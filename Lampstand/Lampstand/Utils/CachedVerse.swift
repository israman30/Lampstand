//
//  CachedVerse.swift
//  Lampstand
//
//  Created by Cursor on 6/10/26.
//

import CoreData

@objc(CachedVerse)
final class CachedVerse: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var book: String?
    @NSManaged var chapter: Int16
    @NSManaged var verse: Int16
    @NSManaged var version: String
    @NSManaged var text: String
    @NSManaged var fetchedAt: Date
}

extension CachedVerse {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CachedVerse"
        entity.managedObjectClassName = NSStringFromClass(CachedVerse.self)

        let key = NSAttributeDescription()
        key.name = "key"
        key.attributeType = .stringAttributeType
        key.isOptional = false

        let book = NSAttributeDescription()
        book.name = "book"
        book.attributeType = .stringAttributeType
        book.isOptional = true

        let chapter = NSAttributeDescription()
        chapter.name = "chapter"
        chapter.attributeType = .integer16AttributeType
        chapter.isOptional = false

        let verse = NSAttributeDescription()
        verse.name = "verse"
        verse.attributeType = .integer16AttributeType
        verse.isOptional = false

        let version = NSAttributeDescription()
        version.name = "version"
        version.attributeType = .stringAttributeType
        version.isOptional = false

        let text = NSAttributeDescription()
        text.name = "text"
        text.attributeType = .stringAttributeType
        text.isOptional = false

        let fetchedAt = NSAttributeDescription()
        fetchedAt.name = "fetchedAt"
        fetchedAt.attributeType = .dateAttributeType
        fetchedAt.isOptional = false

        entity.properties = [key, book, chapter, verse, version, text, fetchedAt]
        entity.uniquenessConstraints = [["key"]]

        return entity
    }

    @nonobjc static func fetchRequest() -> NSFetchRequest<CachedVerse> {
        NSFetchRequest<CachedVerse>(entityName: "CachedVerse")
    }
}

