//
//  ManagedEstimateCapture+CoreDataClass.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/26/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ManagedEstimateCapture)
public class ManagedEstimateCapture: NSManagedObject {
    
    func initialize(with capture: EstimateCapture) {
        self.jsonURL = capture.jsonURL
        self.photoURL = capture.photoURL
        self.additionalPhotoURL = capture.additionalPhotoURL
        self.timestamp = capture.timestamp
        self.sessionId = capture.sessionId
        self.isSubmitted = capture.isSubmitted!
        self.initialWeight = capture.initialWeight!
        self.plateWeight = capture.plateWeight!
        self.foodName = capture.foodName
    }
    
    func export() -> EstimateCapture {
        return EstimateCapture(
            jsonURL: jsonURL!,
            photoURL: photoURL!,
            additionalPhotoURL: additionalPhotoURL!,
            timestamp: timestamp!,
            sessionId: sessionId!,
            isSubmitted: isSubmitted,
            initialWeight: initialWeight,
            plateWeight: plateWeight,
            foodName: foodName!
        )
    }

}
