//
//  ManagedSessionRecord+CoreDataProperties.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 12/20/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData


extension ManagedSessionRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedSessionRecord> {
        return NSFetchRequest<ManagedSessionRecord>(entityName: "ManagedSessionRecord")
    }

    @NSManaged public var photoURL: URL?
    @NSManaged public var captureJSONURL: URL?
    @NSManaged public var recognitionJSONURL: URL?
    @NSManaged public var timestamp: Date?
    @NSManaged public var sessionId: UUID?

}
