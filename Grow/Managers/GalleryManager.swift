import CoreData
import Foundation
import Combine

class GalleryManager: ObservableObject {
    let context: NSManagedObjectContext
    @Published var media: [Media] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        media = fetchMedia()
    }
    
    func addMedia(filename: String, type: String, tags: [String] = []) {
        let item = Media(context: context)
        item.id = UUID()
        item.date = Date()
        item.filename = filename
        item.type = type
        item.tags = tags.joined(separator: ",")
        
        saveContext()
        loadData()
    }
    
    func deleteMedia(_ item: Media) {
        context.delete(item)
        saveContext()
        loadData()
    }
    
    func linkToWeight(_ media: Media, weightId: UUID) {
        media.linkedWeightId = weightId
        saveContext()
        loadData()
    }
    
    private func fetchMedia() -> [Media] {
        let request: NSFetchRequest<Media> = Media.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
