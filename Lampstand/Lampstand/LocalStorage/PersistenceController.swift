//
//  PersistenceController.swift
//  Lampstand
//
//  Created by Cursor on 6/10/26.
//

import CoreData

enum PersistenceControllerError: Error, LocalizedError {
    case persistentStoreLoadFailed(underlying: Error)
    case invalidStoreConfiguration(reason: String)

    var errorDescription: String? {
        switch self {
        case .persistentStoreLoadFailed(let underlying):
            return "Failed to load the Core Data persistent store. \(underlying.localizedDescription)"
        case .invalidStoreConfiguration(let reason):
            return "Invalid Core Data store configuration. \(reason)"
        }
    }
}

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // The app builds its Core Data schema in code (see `LampstandManagedObjectModel`)
        // to keep the cache lightweight and avoid shipping/maintaining a `.xcdatamodeld`
        // for a single-entity store.
        let model = LampstandManagedObjectModel.make()
        container = NSPersistentContainer(name: "Lampstand", managedObjectModel: model)

        if inMemory {
            // Used by tests/previews: an in-memory store keeps runs isolated and avoids filesystem writes.
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                let wrapped = PersistenceControllerError.persistentStoreLoadFailed(underlying: error)
                // Persistence is foundational for caching; failing fast makes configuration issues obvious
                // during development instead of silently degrading behavior.
                fatalError(wrapped.localizedDescription)
            }
        }

        // Background upserts should be reflected in `viewContext` without manual refreshes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // If two contexts touch the same row, prefer the most recently written properties.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

