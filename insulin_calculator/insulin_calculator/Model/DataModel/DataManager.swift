//
//  DataManager.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject {
    
    /**
     The shared instance of object `DataManager`.
     */
    static var shared: DataManager = DataManager()
    
    // MARK: - `SessionRecord` manipulation.
    
    /**
     Insert a session record into the persistant container.
     
     - parameters:
        - record: The `SessionRecord` object to be inserted into the persistant container.
     */
    func createSessionRecord(record: SessionRecord) {
        let entity = NSEntityDescription.entity(forEntityName: "ManagedSessionRecord", in: context)
        let newRecord = ManagedSessionRecord(entity: entity!, insertInto: context)
        newRecord.initialize(with: record)
        saveContext()
    }
    
    /**
     Update a session record in the persistant container. Do not update the URL related fields.
     
     - parameters:
        - record: The `SessionRecord` object to be updated.
     */
    func updateSessionRecord(record: SessionRecord) {
        removeSessionRecord(record: record, withFiles: false)
        createSessionRecord(record: record)
    }
    
    /**
     Remove a session record from the persistant container.
     
     - parameters:
        - record: The `SessionRecord` object to be removed from the persistant container.
        - withFiles: Whether the files specified by URL fields of the `SessionRecord` object should
            also be removed with the record.
     */
    func removeSessionRecord(record: SessionRecord, withFiles: Bool) {
        let fetchRequest: NSFetchRequest = ManagedSessionRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sessionId == \"\(record.sessionId)\"")
        let results = try! context.fetch(fetchRequest)
        for record in results {
            if withFiles {
                removeFile(url: record.photoURL)
                removeFile(url: record.captureJSONURL)
                removeFile(url: record.recognitionJSONURL)
            }
            context.delete(record)
        }
        saveContext()
    }
    
    /**
     Return all stored session records in an array.
     */
    func getAllSessionRecords() -> [SessionRecord] {
        let fetchRequest: NSFetchRequest = ManagedSessionRecord.fetchRequest()
        let managedRecords = (try! context.fetch(fetchRequest)) as [ManagedSessionRecord]
        return managedRecords.map({$0.export()})
    }
    
    // MARK: - File Manipulation.
    
    /**
     Save `data` as a temporary file in `documentDirectory` with extension name `extensionName`.
     The file name would be a UUID string.
     
     - parameters:
        - data: The data to be saved. Callers are responsible for converting objects to `Data` with proper encoding.
        - extensionName: The extension name of the saved file.
        - completion: The completion handler. This closure will be called once the saving process finished, the parameter
            is the URL of the saved temporary file.
     */
    func saveFile(
        data: Data,
        extensionName: String,
        completion: ((URL) -> ())?
    ) {
        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(UUID().uuidString).appendingPathExtension(extensionName)
        try! data.write(to: url)
        completion?(url)
    }
    
    /**
     Remove the file with the given URL.
     
     - parameters:
        - url: The url of the file to be removed.
     */
    func removeFile(url: URL?) {
        guard url != nil else {return}
        guard FileManager.default.fileExists(atPath: url!.path) else {return}
        try! FileManager.default.removeItem(at: url!)
    }
    
    // MARK: - Utilties.
    
    /**
     A context representing a single object space that allows fetch, create, and remove managed objects.
     */
    private var context: NSManagedObjectContext = {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return context
    }()
    
    /**
     Save CoreData context.
     */
    private func saveContext() {
        do {
            try context.save()
        } catch {
            fatalError("Error occurred when saving a context.")
        }
    }
    
}
