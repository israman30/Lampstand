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
        let model = LampstandManagedObjectModel.make()
        container = NSPersistentContainer(name: "Lampstand", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                let wrapped = PersistenceControllerError.persistentStoreLoadFailed(underlying: error)
                fatalError(wrapped.localizedDescription)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

