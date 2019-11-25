//
//  ImpactGenerator.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/25/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation
import Haptica

class ImpactGenerator: NSObject {
    
    private var timer: Timer?
    private let period: TimeInterval = 1.0 / 3.0
    
    static var sharedInstance: ImpactGenerator = ImpactGenerator()
    
    func startRunning() {
        timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true) { timer in
            Haptic.impact(.light).generate()
        }
        timer?.fire()
    }
    
    func stopRunning() {
        timer?.invalidate()
    }
    
}
