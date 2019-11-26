//
//  ManagedEstimateCapture+CoreDataProperties.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/26/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData


extension ManagedEstimateCapture {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedEstimateCapture> {
        return NSFetchRequest<ManagedEstimateCapture>(entityName: "ManagedEstimateCapture")
    }

    @NSManaged public var initialWeight: Double
    @NSManaged public var isSubmitted: Bool
    @NSManaged public var jsonURL: URL?
    @NSManaged public var photoURL: URL?
    @NSManaged public var sessionId: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var plateWeight: Double
    @NSManaged public var foodName: String?
    @NSManaged public var additionalPhotoURL: URL?

}
