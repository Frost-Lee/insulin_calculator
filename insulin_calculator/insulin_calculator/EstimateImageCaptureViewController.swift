//
//  ViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import Photos
import CoreImage
import SVProgressHUD

class EstimateImageCaptureViewController: UIViewController {

    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var captureButton: UIButton! {
        didSet {
            captureButton.layer.cornerRadius = 8.0
        }
    }
    @IBOutlet weak var deviceOrientationIndicatorView: DeviceOrientationIndicateView!
    @IBOutlet weak var previewBlurView: UIVisualEffectView!
    
    private var volumeButtonListener: VolumeButtonListener?
    
    private var estimateImageCaptureManager: EstimateImageCaptureManager!
    private var dataManager: DataManager = DataManager.shared
    private var backendConnector: BackendConnector = BackendConnector.shared
    
    private var isAvailable: Bool = false {
        didSet {
            guard oldValue != isAvailable else {return}
            if isAvailable {
                captureButton.isEnabled = true
                UIView.animate(withDuration: 0.2, delay: 0, options:
                    UIView.AnimationOptions.curveEaseInOut, animations: {
                        self.previewBlurView.alpha = 0
                }, completion: nil)
            } else {
                captureButton.isEnabled = false
                UIView.animate(withDuration: 0.2, delay: 0, options:
                    UIView.AnimationOptions.curveEaseInOut, animations: {
                        self.previewBlurView.alpha = 1
                }, completion: nil)
            }
        }
    }
    private var isDeviceSupported: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            estimateImageCaptureManager = try EstimateImageCaptureManager(delegate: self)
        } catch {isDeviceSupported = false;return}
        previewContainerView.layer.insertSublayer(estimateImageCaptureManager.previewLayer, at: 0)
        setupVolumeButtonListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isDeviceSupported else {return}
        estimateImageCaptureManager.startRunning()
        deviceOrientationIndicatorView.startRunning() {
            return self.estimateImageCaptureManager.deviceAttitude
        }
        
        isAvailable = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isDeviceSupported {
            performSegue(withIdentifier: "showDeviceUnsupportInformationViewController", sender: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isDeviceSupported else {return}
        isAvailable = false
        deviceOrientationIndicatorView.stopRunning()
        estimateImageCaptureManager.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isDeviceSupported else {return}
        estimateImageCaptureManager.previewLayer.frame = previewContainerView.bounds
    }

    @IBAction func captureButtonTapped(_ sender: Any?) {
        isAvailable = false
        SVProgressHUD.show(withStatus: "Fetching Estimation Result")
        estimateImageCaptureManager.captureImage()
    }
    
    private func setupVolumeButtonListener() {
        volumeButtonListener = VolumeButtonListener()
        volumeButtonListener?.delegate = self
        volumeButtonListener?.startListening()
    }
    
    private func submitCapturedData(
        imageData: Data,
        depthMap: CVPixelBuffer,
        calibration: AVCameraCalibrationData,
        attitude: CMAttitude
    ) {
        var jsonURL: URL?, photoURL: URL?
        let group = DispatchGroup()
        let sessionId: UUID = UUID()
        group.enter()
        dataManager.saveFile(
            data: wrapEstimateImageData(depthMap: depthMap, calibration: calibration, attitude: attitude),
            extensionName: "json"
        ) { url in jsonURL = url; group.leave()}
        group.enter()
        dataManager.saveFile(
            data: imageData,
            extensionName: "jpg"
        ) { url in photoURL = url; group.leave()}
        group.notify(queue: .main) {
            self.backendConnector.getRecognitionResult(
                token: "abcd1234",
                sessionId: sessionId.uuidString,
                jsonURL: jsonURL!,
                photoURL: photoURL!
            ) { result, error in
                guard error == nil else {
                    self.isAvailable = true
                    SVProgressHUD.showError(withStatus: "Server Error")
                    return
                }
                SVProgressHUD.showSuccess(withStatus: "Uploaded")
                self.isAvailable = true
            }
        }
    }

}


extension EstimateImageCaptureViewController: EstimateImageCaptureDelegate {
    func captureOutput(image: CGImage, depthMap: CVPixelBuffer, calibration: AVCameraCalibrationData, attitude: CMAttitude, error: Error?) {
        let jpegData = UIImage(cgImage: image).jpegData(compressionQuality: 1.0)!
        submitCapturedData(
            imageData: jpegData,
            depthMap: depthMap,
            calibration: calibration,
            attitude: attitude
        )
    }
}


extension EstimateImageCaptureViewController: VolumeButtonListenerDelegate {
    func volumeButtonClicked(isUpperButton: Bool) {
        captureButtonTapped(nil)
    }
}
