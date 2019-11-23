//
//  VolumeButtonListener.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol VolumeButtonListenerDelegate {
    /**
     Indicating the volume button is clicked by the user.
     
     - Parameters:
        - isUpperButton: Whether the upper volume button is clicked by the user.
     */
    func volumeButtonClicked(isUpperButton: Bool)
}

class VolumeButtonListener: NSObject {
    
    /**
     - TODO:
        Fixing the problem that triggering control center will make the listener invalid.
     */
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationEnteredForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    /// The delegate for receiving volume button click events.
    var delegate: VolumeButtonListenerDelegate?
    /// Whether the volume button listener is listening
    private(set) var isListening: Bool = false
    
    private var shouldRecoverListening: Bool = false
    
    private var audioSession: AVAudioSession?
    private let observerKey: String = "outputVolume"
    private let minimumVolumeChange: Float = 0.05
    
    private var originalVolume: Float = 0.0
    private var currentVolume: Float {
        get {
            return AVAudioSession.sharedInstance().outputVolume
        } set {
            MPVolumeView.setVolume(newValue)
        }
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        switch keyPath {
        case observerKey:
            if abs(currentVolume - originalVolume) < minimumVolumeChange {return}
            delegate?.volumeButtonClicked(isUpperButton: currentVolume > originalVolume)
            currentVolume = originalVolume
        default:
            break
        }
    }
    
    /**
     Start listening the volume button click events
     */
    func startListening() {
        audioSession = AVAudioSession.sharedInstance()
        try! audioSession!.setActive(true)
        isListening = true
        audioSession!.addObserver(self, forKeyPath: observerKey, options: .new, context: nil)
        originalVolume = AVAudioSession.sharedInstance().outputVolume
    }
    
    func stopListening() {
        audioSession?.removeObserver(self, forKeyPath: observerKey)
        try! audioSession?.setActive(false)
        isListening = false
    }
    
    @objc func applicationEnteredForeground() {
        if shouldRecoverListening {
            startListening()
            shouldRecoverListening = false
        }
    }
    
    @objc func applicationResignActive() {
        if isListening {
            stopListening()
            shouldRecoverListening = true
        }
    }
    
}
