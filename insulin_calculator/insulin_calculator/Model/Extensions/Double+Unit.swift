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
<<<<<<< HEAD:insulin_calculator/insulin_calculator/Model/Extensions/Double+Unit.swift
        return String(format: "%.1f ", self * pow(10, 4)) + " cm2"
    }
    
    func volumeString() -> String {
        return String(format: "%.1f ", self * pow(10, 6)) + " cm3"
=======
        return String(format: "%.2f ", self * pow(10, 4)) + "cm2"
    }
    
    func volumeString() -> String {
        return String(format: "%.2f ", self * pow(10, 6)) + "cm3"
>>>>>>> c6b3090c2dd5038697662d57cbcb1cec98ba3149:insulin_calculator/insulin_calculator/Model/Double+Unit.swift
    }
    
    func weightString() -> String {
        return String(format: "%.1f ", self * pow(10, 3)) + " g"
    }
    
    func collectWeightString() -> String {
        return String(format: "%.1f", self) + " lb"
    }
}
