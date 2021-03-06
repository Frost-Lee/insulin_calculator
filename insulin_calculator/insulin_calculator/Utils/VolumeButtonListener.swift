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
     This method will be triggered when one of the device volume button is triggered.
     
     - parameters:
        - isUpperButton: `true` if the triggered button is the volume up button, otherwise it's the volume
            down button.
     */
    func volumeButtonClicked(isUpperButton: Bool)
}

/**
 A listener for volume button click event.
 */
class VolumeButtonListener: NSObject {
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    var delegate: VolumeButtonListenerDelegate?
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
            /**
             - TODO:
                Obserbed situation when click a volume button, then click another volume button, the latter click
                will not change the device volume.
             */
            if abs(currentVolume - originalVolume) < minimumVolumeChange {return}
            delegate?.volumeButtonClicked(isUpperButton: currentVolume > originalVolume)
            currentVolume = originalVolume
        default:
            break
        }
    }
    
    /**
     Start listening for volume button click event.
     */
    func startListening() {
        /**
         - TODO:
            Consider the case when the user's initial volume is minimum or maximum, on which status clicking
            one volume button will have no effect.
         */
        audioSession = AVAudioSession.sharedInstance()
        try! audioSession!.setActive(true)
        isListening = true
        audioSession!.addObserver(self, forKeyPath: observerKey, options: .new, context: nil)
        originalVolume = AVAudioSession.sharedInstance().outputVolume
    }
    
    /**
     Stop listening for volume button click event.
     */
    func stopListening() {
        audioSession?.removeObserver(self, forKeyPath: observerKey)
        try! audioSession?.setActive(false)
        isListening = false
    }
    
    @objc private func applicationBecomeActive() {
        if shouldRecoverListening {
            startListening()
            shouldRecoverListening = false
        }
    }
    
    @objc private func applicationResignActive() {
        if isListening {
            stopListening()
            shouldRecoverListening = true
        }
    }
    
}
