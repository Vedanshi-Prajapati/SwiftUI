import CoreData
import UIKit
import Combine

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "artform", managedObjectModel: Self.model)
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static var model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let artwork = NSEntityDescription()
        artwork.name = "ArtworkEntity"
        artwork.managedObjectClassName = NSStringFromClass(ArtworkEntity.self)

        func attr(_ name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name; a.attributeType = type; a.isOptional = optional
            return a
        }

        artwork.properties = [
            attr("id",              type: .UUIDAttributeType),
            attr("title",           type: .stringAttributeType),
            attr("createdAt",       type: .dateAttributeType),
            attr("durationSeconds", type: .integer32AttributeType),
            attr("source",          type: .stringAttributeType),
            attr("levelId",         type: .integer32AttributeType, optional: true),
            attr("pngFilename",     type: .stringAttributeType),
        ]

        let progress = NSEntityDescription()
        progress.name = "LevelProgressEntity"
        progress.managedObjectClassName = NSStringFromClass(LevelProgressEntity.self)

        progress.properties = [
            attr("levelId",        type: .integer32AttributeType),
            attr("isUnlocked",     type: .booleanAttributeType),
            attr("isCompleted",    type: .booleanAttributeType),
            attr("lastTool",       type: .stringAttributeType, optional: true),
            attr("lastColor",      type: .stringAttributeType, optional: true),
            attr("assistStrength", type: .doubleAttributeType),
            attr("snapRadius",     type: .doubleAttributeType),
            attr("updatedAt",      type: .dateAttributeType),
        ]

        model.entities = [artwork, progress]
        return model
    }()

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do { try ctx.save() } catch { print("Core Data save error: \(error)") }
    }

    func saveArtwork(_ art: Artwork, pngFilename: String) {
        let ctx = container.viewContext
        let entity = ArtworkEntity(context: ctx)
        entity.id              = art.id
        entity.title           = art.title
        entity.createdAt       = art.createdAt
        entity.durationSeconds = Int32(art.durationSeconds)
        entity.source          = art.source.rawValue
        entity.levelId         = art.levelId.map(Int32.init) ?? -1
        entity.pngFilename     = pngFilename
        save()
    }

    func fetchArtworks() -> [Artwork] {
        let req = NSFetchRequest<ArtworkEntity>(entityName: "ArtworkEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let entities = (try? container.viewContext.fetch(req)) ?? []
        return entities.compactMap { e in
            guard let id = e.id, let title = e.title, let date = e.createdAt,
                  let sourceRaw = e.source, let pngFilename = e.pngFilename,
                  let source = ArtworkSource(rawValue: sourceRaw) else { return nil }
            return Artwork(
                id: id, title: title, createdAt: date,
                durationSeconds: Int(e.durationSeconds),
                source: source,
                levelId: e.levelId == -1 ? nil : Int(e.levelId),
                pngFilename: pngFilename
            )
        }
    }

    func deleteArtwork(id: UUID) {
        let req = NSFetchRequest<ArtworkEntity>(entityName: "ArtworkEntity")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try? container.viewContext.fetch(req).first {
            container.viewContext.delete(obj)
            save()
        }
    }

    func fetchProgress(levelId: Int) -> LevelProgressEntity? {
        let req = NSFetchRequest<LevelProgressEntity>(entityName: "LevelProgressEntity")
        req.predicate = NSPredicate(format: "levelId == %d", levelId)
        req.fetchLimit = 1
        return try? container.viewContext.fetch(req).first
    }

    func upsertProgress(levelId: Int, configure: (LevelProgressEntity) -> Void) {
        let entity = fetchProgress(levelId: levelId) ?? {
            let e = LevelProgressEntity(context: container.viewContext)
            e.levelId = Int32(levelId)
            e.assistStrength = 0.5
            e.snapRadius = 12.0
            return e
        }()
        entity.updatedAt = Date()
        configure(entity)
        save()
    }

    func allCompletedLevelIds() -> Set<Int> {
        let req = NSFetchRequest<LevelProgressEntity>(entityName: "LevelProgressEntity")
        req.predicate = NSPredicate(format: "isCompleted == YES")
        let items = (try? container.viewContext.fetch(req)) ?? []
        return Set(items.map { Int($0.levelId) })
    }

    func maxUnlockedLevelId() -> Int {
        let req = NSFetchRequest<LevelProgressEntity>(entityName: "LevelProgressEntity")
        req.predicate = NSPredicate(format: "isUnlocked == YES")
        req.sortDescriptors = [NSSortDescriptor(key: "levelId", ascending: false)]
        req.fetchLimit = 1
        return Int((try? container.viewContext.fetch(req).first?.levelId) ?? 1)
    }
}

@objc(ArtworkEntity)
class ArtworkEntity: NSManagedObject {
    @NSManaged var id:              UUID?
    @NSManaged var title:           String?
    @NSManaged var createdAt:       Date?
    @NSManaged var durationSeconds: Int32
    @NSManaged var source:          String?
    @NSManaged var levelId:         Int32
    @NSManaged var pngFilename:     String?
}

@objc(LevelProgressEntity)
class LevelProgressEntity: NSManagedObject {
    @NSManaged var levelId:        Int32
    @NSManaged var isUnlocked:     Bool
    @NSManaged var isCompleted:    Bool
    @NSManaged var lastTool:       String?
    @NSManaged var lastColor:      String?
    @NSManaged var assistStrength: Double
    @NSManaged var snapRadius:     Double
    @NSManaged var updatedAt:      Date?
}
