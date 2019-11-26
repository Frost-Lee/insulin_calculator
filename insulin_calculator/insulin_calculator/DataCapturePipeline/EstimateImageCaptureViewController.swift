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
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var deviceOrientationIndicatorView: DeviceOrientationIndicateView!
    @IBOutlet weak var previewBlurView: UIVisualEffectView!
    
    private var volumeButtonListener: VolumeButtonListener?
    
    var estimateCapture: EstimateCapture?
    
    private var estimateImageCaptureManager: EstimateImageCaptureManager!
    private var dataManager: DataManager = DataManager.shared
    
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
        self.isModalInPresentation = true
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "showAdditionalImageCaptureViewController":
            let destination = segue.destination as! AdditionalImageCaptureViewController
            destination.estimateCapture = sender as? EstimateCapture
        default:
            break
        }
    }

    @IBAction func captureButtonTapped(_ sender: Any?) {
        guard isAvailable else {return}
        isAvailable = false
        SVProgressHUD.show(withStatus: "Processing Calculation Data")
        estimateImageCaptureManager.captureImage()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        removeEstimateCaptureFiles()
        dismiss(animated: true, completion: nil)
    }
    
    private func setupVolumeButtonListener() {
        volumeButtonListener = VolumeButtonListener()
        volumeButtonListener?.delegate = self
        volumeButtonListener?.startListening()
    }
    
    private func processCapturedData(
        imageData: Data,
        depthMap: CVPixelBuffer,
        calibration: AVCameraCalibrationData,
        attitude: CMAttitude
    ) {
        var jsonURL: URL?, photoURL: URL?
        let group = DispatchGroup()
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
            self.removeEstimateCaptureFiles()
            self.estimateCapture = EstimateCapture(
                jsonURL: jsonURL,
                photoURL: photoURL,
                timestamp: Date(),
                sessionId: UUID(),
                isSubmitted: false,
                plateWeight: 0
            )
            SVProgressHUD.dismiss()
            self.performSegue(
                withIdentifier: "showAdditionalImageCaptureViewController",
                sender: self.estimateCapture!
            )
        }
    }
    
    private func removeEstimateCaptureFiles() {
        self.dataManager.removeFile(url: self.estimateCapture?.jsonURL)
        self.dataManager.removeFile(url: self.estimateCapture?.photoURL)
        self.dataManager.removeFile(url: self.estimateCapture?.additionalPhotoURL)
    }

}


extension EstimateImageCaptureViewController: EstimateImageCaptureDelegate {
    func captureOutput(
        image: CGImage,
        depthMap: CVPixelBuffer,
        calibration: AVCameraCalibrationData,
        attitude: CMAttitude,
        error: Error?
    ) {
        let jpegData = UIImage(cgImage: image).jpegData(compressionQuality: 1.0)!
        processCapturedData(
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
