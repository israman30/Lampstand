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
        model.entities = [
            CachedVerse.entityDescription()
        ]
        return model
    }
}

