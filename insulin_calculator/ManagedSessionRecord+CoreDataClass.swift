//
//  ManagedSessionRecord+CoreDataClass.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 2/7/20.
//  Copyright © 2020 李灿晨. All rights reserved.
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
        self.selectedCandidateIndices = record.selectedCandidateIndices.map({String($0)}).joined(separator: ";")
        self.timestamp = record.timestamp
        self.sessionId = record.sessionId
    }
    
    func export() -> SessionRecord {
        return SessionRecord(
            photoURL: self.photoURL!,
            captureJSONURL: self.captureJSONURL!,
            recognitionJSONURL: self.recognitionJSONURL!,
            selectedCandidateIndices: self.selectedCandidateIndices!.split(separator: ";").map({Int($0) ?? 0}),
            timestamp: self.timestamp!,
            sessionId: self.sessionId!
        )
    }

}
