//
//  BackendConnector.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/17/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BackendConnector: NSObject {
    
    /**
     The shared instance of object `BackendConnector`.
     */
    static var shared: BackendConnector = BackendConnector()
    
    private let backendRecognitionURLString: String = "http://18.20.181.107:5000/nutritionestimation"
    private let backendCollectionURLString: String = "http://18.20.181.107:5000/densitycollect"
    
    /**
     Getting the session's recognition result.
     
     - parameters:
        - token: The token of the user.
        - sessionId: The id of the session, specified by a string.
        - jsonURL: The local URL of the JSON file which wraps the peripheral data of the capture.
        - photoURL: The local URL of the jpg image file of the color image capture.
        - completion: The completion handler.
     
     - throws:
        Errors of type `NetworkError`(for unexpected response of backend server) or `Error`(for
            encoding problems).
     */
    func getRecognitionResult(
        token: String,
        sessionId: String,
        jsonURL: URL,
        photoURL: URL,
        completion: ((SessionRecognitionResult?, Error?) -> ())?
    ) {
        let jsonData = try! Data(contentsOf: jsonURL)
        let photoData = try! Data(contentsOf: photoURL)
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(photoData, withName: "image", fileName: "image.jpg", mimeType: "image/jpg")
                multipartFormData.append(jsonData, withName: "peripheral", fileName: "peripheral.json", mimeType: "text/plain")
                multipartFormData.append(sessionId.data(using: .utf8)!, withName: "session_id")
                multipartFormData.append(token.data(using: .utf8)!, withName: "token")
            },
            to: backendRecognitionURLString,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseData() { dataResponse in
                        guard dataResponse.data != nil else {completion?(nil, NetworkError.unexpectedResponse);return}
                        do {
                            let json = try JSON(data: dataResponse.data!)
                            let result = try SessionRecognitionResult(json: json)
                            completion?(result, nil)
                        } catch {
                            completion?(nil, NetworkError.unexpectedResponse)
                            return
                        }
                    }
                case .failure(let encodingError):
                    completion?(nil, encodingError)
                }
            }
        )
    }
    
    /**
     Submitting a data collection session.
     
     - parameters:
        - token: The token of the user.
        - sessionId: The id of the session, specified by a string.
        - jsonURL: The local URL of the JSON file which wraps the peripheral data of the capture.
        - imageURL: The local URL of the jpg image file of the color image capture.
        - additionalImageURL: The local URL of the jpg image file of the additional color image capture.
        - name: The name of the food.
        - weight: The weight of the food in gram, represented in string.
        - completion: The completion handler.
     
     - throws:
        Errors of type `NetworkError`(for unexpected response of backend server) or `Error`(for
        encoding problems).
     */
    func getDensityCollectionResult(
        token: String,
        sessionId: String,
        jsonURL: URL,
        imageURL: URL,
        additionalImageURL: URL,
        name: String,
        weight: String,
        completion: ((Error?) -> ())?
    ) {
        let jsonData = try! Data(contentsOf: jsonURL)
        let imageData = try! Data(contentsOf: imageURL)
        let additionalImageData = try! Data(contentsOf: additionalImageURL)
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "image", fileName: "image.jpg", mimeType: "image/jpg")
                multipartFormData.append(additionalImageData, withName: "additional", fileName: "additional.jpg", mimeType: "image/jpg")
                multipartFormData.append(jsonData, withName: "peripheral", fileName: "peripheral.json", mimeType: "text/plain")
                multipartFormData.append(sessionId.data(using: .utf8)!, withName: "session_id")
                multipartFormData.append(token.data(using: .utf8)!, withName: "token")
                multipartFormData.append(name.data(using: .utf8)!, withName: "name")
                multipartFormData.append(weight.data(using: .utf8)!, withName: "weight")
            },
            to: backendCollectionURLString,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseData() { dataResponse in
                        guard dataResponse.data != nil else {completion?(NetworkError.unexpectedResponse);return}
                        do {
                            let json = try JSON(data: dataResponse.data!)
                            if json["status"].string! == "OK" {
                                completion?(nil)
                            } else {
                                completion?(NetworkError.unexpectedResponse)
                            }
                        } catch {
                            completion?(NetworkError.unexpectedResponse)
                            return
                        }
                    }
                case .failure(let encodingError):
                    completion?(encodingError)
                }
            }
        )
    }
    
}
