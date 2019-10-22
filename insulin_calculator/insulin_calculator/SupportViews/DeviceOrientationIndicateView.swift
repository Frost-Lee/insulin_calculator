//
//  DeviceOrientationIndicateView.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import CoreMotion
import simd

class DeviceOrientationIndicateView: UIView {
    
    var referenceIndicatorImageView: UIImageView! {
        let imageView = UIImageView(image: UIImage(named: "orientation_indicator")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        return imageView
    }
    var flexibleIndicatorImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "orientation_indicator")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        return imageView
    }()
    
    private var flexibleIndicatorXConstraint: NSLayoutConstraint?
    private var flexibleIndicatorYConstraint: NSLayoutConstraint?
    
    private let thresholdConstant = 8.0
    
    private var attitudeSource: CMAttitude?
    
    private var timer: Timer?
    
    /**
     Prepare the `DeviceOrientationIndicateView` object. Call this method before calling
     `startRunning()`.
     */
    func prepare() {
        addSubview(referenceIndicatorImageView)
        addSubview(flexibleIndicatorImageView)
        
        flexibleIndicatorXConstraint = flexibleIndicatorImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0)
        flexibleIndicatorYConstraint = flexibleIndicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            referenceIndicatorImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            referenceIndicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            referenceIndicatorImageView.widthAnchor.constraint(equalToConstant: 32.0),
            referenceIndicatorImageView.heightAnchor.constraint(equalToConstant: 32.0)
        ])
        
        NSLayoutConstraint.activate([
            flexibleIndicatorXConstraint!,
            flexibleIndicatorYConstraint!,
            flexibleIndicatorImageView.widthAnchor.constraint(equalToConstant: 16.0),
            flexibleIndicatorImageView.heightAnchor.constraint(equalToConstant: 16.0)
        ])
    }
    
    /**
     Start updating the view. Call this method after calling `prepare(attitudeSource:)`.
     
     - Parameters:
        - attitudeSource: The source of the device attitude, pass by reference since `CMAttitude` is
            a class object. This view will keep this reference and call the reference when necessary to layout
            the indicator.
     */
    func startRunning(attitudeSource: CMAttitude) {
        self.attitudeSource = attitudeSource
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            let roll = self.attitudeSource!.roll
            let pitch = self.attitudeSource!.pitch
            var horizontalOffset = CGFloat(roll * 50.0)
            if abs(roll) > Double.pi / 2.0 {
                horizontalOffset = CGFloat((Double.pi - abs(roll)) * 50 * sign(roll))
            }
            let verticalOffset = CGFloat(pitch * 50.0)
            UIView.animate(
                withDuration: 1.0 / 5.0,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.flexibleIndicatorYConstraint!.constant = horizontalOffset
                    self.flexibleIndicatorXConstraint!.constant = verticalOffset
                    self.layoutIfNeeded()
                }, completion: nil
            )
            if abs(horizontalOffset) <= 8 && abs(verticalOffset) <= 6 {
                UIView.animate(withDuration: 1.0 / 5.0) {
                    self.referenceIndicatorImageView.tintColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                }
            } else {
                UIView.animate(withDuration: 1.0 / 5.0) {
                    self.referenceIndicatorImageView.tintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                }
            }
        }
        self.timer = timer
        timer.fire()
    }
    
    /**
     Stop updating the view.
     */
    func stopRunning() {
        timer?.invalidate()
        timer = nil
    }

}
