import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(app.artworks) { art in
                    NavigationLink {
                        ArtworkDetailView(art: art)
                    } label: {
                        HStack(spacing: 12) {
                            if let img = try? app.store.loadArtworkPNG(filename: art.pngFilename) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 84, height: 84)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 84, height: 84)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(art.title)
                                    .font(.custom("Georgia-Bold", size: 18))
                                    .foregroundStyle(.primary)

                                Text(art.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.custom("Georgia", size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    app.deleteArtwork(art)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(Color(hex: "#F0EBE0").ignoresSafeArea())
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Gallery")
                    .font(.custom("Georgia-Bold", size: 20))
            }
        }
    }
}

struct ArtworkDetailView: View {
    @EnvironmentObject private var app: AppState
    let art: Artwork

    var body: some View {
        VStack(spacing: 12) {
            if let img = try? app.store.loadArtworkPNG(filename: art.pngFilename) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemBackground))
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                }
                .padding(.horizontal, 16)
                .frame(height: 520)
            }

            Text(art.title)
                .font(.custom("Georgia-Bold", size: 26))

            Text(art.createdAt.formatted(date: .long, time: .shortened))
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .background(Color(hex: "#F0EBE0").ignoresSafeArea())
    }
}
