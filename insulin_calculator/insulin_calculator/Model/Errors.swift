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

enum DataStorageError: Error {
    case saveFailure
    case fetchFailure
}
