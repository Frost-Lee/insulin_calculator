//
//  ManagedSessionRecord+CoreDataProperties.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 2/7/20.
//  Copyright © 2020 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData


extension ManagedSessionRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedSessionRecord> {
        return NSFetchRequest<ManagedSessionRecord>(entityName: "ManagedSessionRecord")
    }

    @NSManaged public var captureJSONURL: URL?
    @NSManaged public var photoURL: URL?
    @NSManaged public var recognitionJSONURL: URL?
    @NSManaged public var sessionId: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var selectedCandidateIndices: String?

}
