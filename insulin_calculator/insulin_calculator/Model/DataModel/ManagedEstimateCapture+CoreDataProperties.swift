//
//  ManagedEstimateCapture+CoreDataProperties.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/23/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData


extension ManagedEstimateCapture {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedEstimateCapture> {
        return NSFetchRequest<ManagedEstimateCapture>(entityName: "ManagedEstimateCapture")
    }

    @NSManaged public var jsonURL: URL?
    @NSManaged public var photoURL: URL?
    @NSManaged public var isSubmitted: Bool
    @NSManaged public var sessionId: UUID?
    @NSManaged public var timestamp: Date?

}
