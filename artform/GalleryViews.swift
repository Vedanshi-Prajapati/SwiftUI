// GalleryViews.swift
import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
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
                                        .fill(MTheme.paper)
                                        .frame(width: 84, height: 84)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(art.title)
                                        .font(MTheme.heading(20))
                                        .foregroundStyle(MTheme.ink)

                                    Text("\(art.createdAt.formatted(date: .abbreviated, time: .shortened)) • \(art.durationSeconds)s")
                                        .font(MTheme.bodyRounded(13))
                                        .foregroundStyle(MTheme.ink.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .background(MTheme.canvas)
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
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
                    RoundedRectangle(cornerRadius: 22).fill(MTheme.paper)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                }
                .padding(.horizontal, 16)
                .frame(height: 520)
            }

            Text(art.title)
                .font(MTheme.heading(26))

            Text("\(art.createdAt.formatted(date: .long, time: .shortened)) • \(art.durationSeconds)s")
                .font(MTheme.bodyRounded(14))
                .foregroundStyle(MTheme.ink.opacity(0.75))

            Spacer()
        }
        .background(MTheme.canvas)
    }
}
