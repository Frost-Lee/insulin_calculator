//
//  BackendConnector.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/17/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation

class BackendConnector: NSObject {
    
    /**
     The shared instance of object `BackendConnector`.
     */
    static var shared: BackendConnector = BackendConnector()
    
    private let backendURLString: String = ""
    
    /**
     Getting the session's recognition result.
     
     - Parameters:
        - token: The token of the device and session.
        - jsonURL: The local URL of the JSON file which wraps the peripheral data of the capture.
        - photoURL: The local URL of the jpg image file of the color image capture.
        - completion: The completion handler.
     */
    func getRecognitionResult(
        token: String,
        jsonURL: URL,
        photoURL: URL,
        completion: ((SessionRecognitionResult, Error?) -> ())?
    ) {
        
    }
    
}
