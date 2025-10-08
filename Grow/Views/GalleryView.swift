//
//  GalleryView.swift
//  Grow
//
//  Created by Bryan Liu on 2025-10-07.
//


import SwiftUI
import PhotosUI

struct GalleryView: View {
    @ObservedObject var galleryManager: GalleryManager
    @State private var showImagePicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if galleryManager.media.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No progress photos yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Track your transformation with photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                            Label("Add Photos", systemImage: "photo.badge.plus")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(galleryManager.media) { media in
                            MediaThumbnail(media: media)
                        }
                    }
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onChange(of: selectedItems) { oldValue, newValue in
                handleSelectedPhotos(newValue)
            }
        }
    }
    
    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) {
        for _ in items {
            // In a real app, you'd save the photo to disk and store the filename
            // For now, we'll just create a placeholder entry
            galleryManager.addMedia(
                filename: "photo_\(UUID().uuidString).jpg",
                type: "photo",
                tags: ["progress"]
            )
        }
        selectedItems = []
    }
}

struct MediaThumbnail: View {
    let media: Media
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fill)
            
            // Placeholder for actual image
            Image(systemName: "photo")
                .font(.title)
                .foregroundColor(.white)
            
            if let date = media.date {
                Text(date, style: .date)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4)
            }
        }
        .frame(height: 120)
        .clipped()
    }
}
