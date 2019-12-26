//
//  ManagedSessionRecord+CoreDataClass.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 12/20/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ManagedSessionRecord)
public class ManagedSessionRecord: NSManagedObject {
    
    func initialize(with record: SessionRecord) {
        self.photoURL = record.photoURL
        self.captureJSONURL = record.captureJSONURL
        self.recognitionJSONURL = record.recognitionJSONURL
        self.timestamp = record.timestamp
        self.sessionId = record.sessionId
    }
    
    func export() -> SessionRecord {
        return SessionRecord(
            photoURL: self.photoURL!,
            captureJSONURL: self.captureJSONURL!,
            recognitionJSONURL: self.recognitionJSONURL!,
            timestamp: self.timestamp!,
            sessionId: self.sessionId!
        )
    }

}
