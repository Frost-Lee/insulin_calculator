//
//  Errors.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation


enum ValueError: Error {
    case shapeMismatch
}

enum NetworkError: Error {
    case connectionLost
    case unexpectedResponse
}

<<<<<<< HEAD
enum DataStorageError: Error {
    case saveFailure
    case fetchFailure
}

=======
>>>>>>> 68c6ea513f00bb497b7bab3e87d4c69216efcaeb
enum DeviceSupportError: Error {
    case deviceUnsupported
}
