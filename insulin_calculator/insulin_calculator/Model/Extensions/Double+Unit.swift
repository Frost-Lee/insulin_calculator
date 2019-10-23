//
//  Double+Unit.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation

extension Double {
    func areaString() -> String {
        return String(format: "%.1f ", self * pow(10, 4)) + "cm2"
    }
    
    func volumeString() -> String {
        return String(format: "%.1f ", self * pow(10, 6)) + "cm3"
    }
    
    func weightString() -> String {
        return String(format: "%.1f ", self * pow(10, 3)) + "g"
    }
}
