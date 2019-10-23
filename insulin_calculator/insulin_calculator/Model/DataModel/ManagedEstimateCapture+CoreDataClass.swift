//
//  ManagedEstimateCapture+CoreDataClass.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/23/19.
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
        self.timestamp = capture.timestamp
        self.sessionId = capture.sessionId
        self.isSubmitted = capture.isSubmitted
    }
    
    func export() -> EstimateCapture {
        return EstimateCapture(
            jsonURL: jsonURL!,
            photoURL: photoURL!,
            timestamp: timestamp!,
            sessionId: sessionId!,
            isSubmitted: isSubmitted
        )
    }
}
