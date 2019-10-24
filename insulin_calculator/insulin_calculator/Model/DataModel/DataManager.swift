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
    
    /// The shared instance of object `DataManager`.
    static var shared: DataManager = DataManager()
    
    /// Context for CoreData.
    private var context: NSManagedObjectContext = {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return context
    }()
    
    /**
     Save `data` as a temporary file in `cachesDirectory` with extension name `extensionName`.
     The file name would be a UUID string.
     
     - Parameters:
        - data: The data to be saved. Callers are responsible for converting objects to `Data` with proper encoding.
        - extensionName: The extension name of the saved file.
        - completion: The completion handler. This closure will be called once the saving process finished, the parameter
            is the URL of the saved temporary file.
     */
    func saveTemporaryFile(
        data: Data,
        extensionName: String,
        completion: ((URL) -> ())?
    ) {
        let temporaryURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(UUID().uuidString).appendingPathExtension(extensionName)
        try! data.write(to: temporaryURL)
        completion?(temporaryURL)
    }
    
    /**
     Save an `EstimateCapture` object with CoreData.
     
     - Parameters:
        - capture: The `EstimateCapture` object to be saved.
        - completion: The completion handler. `Error` will be `nil` if the data is saved successfully.
     */
    func saveEstimateCapture(capture: EstimateCapture, completion: ((Error?) -> ())?) {
        let entity = NSEntityDescription.entity(forEntityName: "ManagedEstimateCapture", in: context)
        let newCapture = ManagedEstimateCapture(entity: entity!, insertInto: context)
        newCapture.initialize(with: capture)
        do {
            try context.save()
        } catch {
            completion?(DataStorageError.saveFailure)
        }
        completion?(nil)
    }
    
    /**
     Get all `EstimateCapture` objects saved by CoreData.
     
     - Parameters:
        - completion: The completion handler. If the data is successfully fetched, the results will be provided
            as an array at the first parameter, an error will be passed at the second parameter otherwise.
     */
    func getAllEstimateCaptures(completion: (([EstimateCapture]?, Error?) -> ())?) {
        let fetchRequest: NSFetchRequest = ManagedEstimateCapture.fetchRequest()
        do {
            let managedCaptures = (try context.fetch(fetchRequest)) as [ManagedEstimateCapture]
            completion?(managedCaptures.map({$0.export()}).sorted(by: {$0.timestamp > $1.timestamp}), nil)
        } catch {
            completion?(nil, DataStorageError.fetchFailure)
        }
    }
    
    /**
     Remove a stored `EstimateCapture` object with its `sessionId`.
     
     - Parameters:
        - sessionId: The `sessionId` attribute of the `EstimateCapture` object to be removed.
        - completion: The completion handler. `Error` will be `nil` if the data is removed successfully.
     */
    func removeEstimateCapture(sessionId: UUID, completion: ((Error?) -> ())?) {
        let fetchRequest: NSFetchRequest = ManagedEstimateCapture.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sessionId == \"\(sessionId)\"")
        let results = try? context.fetch(fetchRequest)
        guard results != nil else {completion?(DataStorageError.fetchFailure);return}
        for item in results! {
            context.delete(item)
        }
        do {
            try context.save()
        } catch {
            completion?(DataStorageError.saveFailure)
        }
        completion?(nil)
    }
    
    /**
     Update a stored `EstimateCapture` object. Note that the `sessionId` of the capture must not be
     changed, or this method will save another object instead of modifying it.
     
     - Parameters:
        - capture: The updated `EstimateCapture` object that needs to be saved.
        - completion: The completion handler. `Error` will be `nil` if the data is updated successfully.
     */
    func updateEstimateCapture(capture: EstimateCapture, completion: ((Error?) -> ())?) {
        removeEstimateCapture(sessionId: capture.sessionId) { error in
            guard error == nil else {completion?(error);return}
            self.saveEstimateCapture(capture: capture) { anotherError in
                guard anotherError == nil else {completion?(anotherError);return}
                completion?(nil)
            }
        }
    }
    
}
