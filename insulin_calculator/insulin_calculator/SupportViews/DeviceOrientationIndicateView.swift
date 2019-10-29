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
import Haptica

class DeviceOrientationIndicateView: UIView {
    
    var referenceIndicatorImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "orientation_indicator")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        return imageView
    }()
    var flexibleIndicatorImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "orientation_indicator")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        return imageView
    }()
    
    private var flexibleIndicatorXConstraint: NSLayoutConstraint?
    private var flexibleIndicatorYConstraint: NSLayoutConstraint?
    
    private let thresholdConstant: CGFloat = 4.0
    
    private var timer: Timer?
    
    private var isHorizontal: Bool = false {
        didSet {
            if isHorizontal {
                Haptic.impact(.light).generate()
            }
            if oldValue != isHorizontal {
                if isHorizontal {
//                    Haptic.play(".-O", delay: 0.15)
                    UIView.animate(withDuration: 1.0 / 5.0) {
                        self.referenceIndicatorImageView.tintColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                    }
                } else {
//                    Haptic.play("O-.", delay: 0.15)
                    UIView.animate(withDuration: 1.0 / 5.0) {
                        self.referenceIndicatorImageView.tintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                    }
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setLayout()
    }
    
    private func setLayout() {
        backgroundColor = .clear
        addSubview(referenceIndicatorImageView)

        NSLayoutConstraint.activate([
            referenceIndicatorImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            referenceIndicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            referenceIndicatorImageView.widthAnchor.constraint(equalToConstant: 32.0),
            referenceIndicatorImageView.heightAnchor.constraint(equalToConstant: 32.0)
        ])
        
        addSubview(flexibleIndicatorImageView)
        
        flexibleIndicatorXConstraint = flexibleIndicatorImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0)
        flexibleIndicatorYConstraint = flexibleIndicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            flexibleIndicatorXConstraint!,
            flexibleIndicatorYConstraint!,
            flexibleIndicatorImageView.widthAnchor.constraint(equalToConstant: 16.0),
            flexibleIndicatorImageView.heightAnchor.constraint(equalToConstant: 16.0)
        ])
    }
    
    /**
     Start updating the view.
     
     - Parameters:
        - attitudeSource: A closure that provides the `CMAttitude` object. This closure will be called
            when `DeviceOrientationIndicateView` needs to update itself.
     */
    func startRunning(attitudeSource: @escaping () -> (CMAttitude)) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { timer in
            let attitude = attitudeSource()
            let roll = attitude.roll
            let pitch = attitude.pitch
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
                    self.flexibleIndicatorYConstraint!.constant = verticalOffset
                    self.flexibleIndicatorXConstraint!.constant = horizontalOffset
                    self.layoutIfNeeded()
                }, completion: nil
            )
            if abs(horizontalOffset) <= self.thresholdConstant
                && abs(verticalOffset) <= self.thresholdConstant {
                self.isHorizontal = true
            } else {
                self.isHorizontal = false
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
