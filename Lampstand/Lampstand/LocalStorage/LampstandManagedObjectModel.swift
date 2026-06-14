//
//  LampstandManagedObjectModel.swift
//  Lampstand
//
//  Created by Cursor on 6/10/26.
//

import CoreData

enum LampstandManagedObjectModel {
    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        // This model is intentionally tiny and defined in code so the cache can evolve without
        // depending on Xcode model editor artifacts. If the schema grows, consider moving to a
        // `.xcdatamodeld` with proper migrations.
        model.entities = [
            CachedVerse.entityDescription()
        ]
        return model
    }
}

