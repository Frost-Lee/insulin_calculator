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
import CoreML
//import SVProgressHUD

class EstimateImageCaptureViewController: UIViewController {

    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var captureButton: UIButton! {
        didSet {
            captureButton.layer.cornerRadius = 8.0
        }
    }
    @IBOutlet weak var orientationIndicatorImageView: UIImageView!
    @IBOutlet weak var indicatorHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var indicatorVerticalConstraint: NSLayoutConstraint!
    
    private var estimateImageCaptureManager: EstimateImageCaptureManager!
    
    private var dataManager: DataManager = DataManager.shared
    private var backendConnector: BackendConnector = BackendConnector.shared
    
    /**
     An array for caching data captured by `EstimateImageCaptureManager`. The elements stands for
     the photo captured, the attitude when capturing the photo, and the crop rect for the photo.
     
     - TODO:
        Expecting a better way to achieve this functionality.
     */
    private var cachedData: (AVCapturePhoto, CMAttitude, CGRect)?

    override func viewDidLoad() {
        super.viewDidLoad()
        estimateImageCaptureManager = EstimateImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(estimateImageCaptureManager.previewLayer, at: 0)
//        SVProgressHUD.setDefaultStyle(.dark)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        estimateImageCaptureManager.startRunning()
        configureOrientationIndicator()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        estimateImageCaptureManager.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        estimateImageCaptureManager.previewLayer.frame = previewContainerView.bounds
    }

    @IBAction func captureButtonTapped(_ sender: UIButton) {
        captureButton.isEnabled = false
//        SVProgressHUD.show(withStatus: "Processing image data")
        estimateImageCaptureManager.captureImage()
    }
    
    private func submitCapturedData(
        photo: AVCapturePhoto,
        attitude: CMAttitude,
        rect: CGRect
    ) {
        var jsonURL: URL?, photoURL: URL?
        let group = DispatchGroup()
        group.enter()
        cacheEstimateImageCaptureData(
            depthMap: convertAndCropDepthData(depthData: photo.depthData!, rect: rect),
            calibration: photo.depthData!.cameraCalibrationData!,
            attitude: attitude,
            cropRect: rect
        ) { url in
            jsonURL = url
            group.leave()
        }
        group.enter()
        dataManager.saveTemporaryFile(
            data: UIImage(cgImage: try! cropImage(photo: photo, rect: rect)).jpegData(compressionQuality: 1.0)!,
            extensionName: "jpg"
        ) { url in
            photoURL = url
            group.leave()
        }
        group.notify(queue: .main) {
            let activityViewController = UIActivityViewController(activityItems: [jsonURL!], applicationActivities: [])
            self.present(activityViewController, animated: true, completion: nil)
            UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: try! cropImage(photo: photo, rect: rect)), nil, nil, nil)
            self.captureButton.isEnabled = true
//            SVProgressHUD.dismiss()
//            self.backendConnector.getRecognitionResult(
//                token: "abcd1234",
//                jsonURL: jsonURL!,
//                photoURL: photoURL!
//            ) { result, error in
//                self.captureButton.isEnabled = true
//            }
        }

    }
    
    // MARK: - Orientation Indicator Configuration
    /**
     - TODO:
        Wripping the orientation indicator as a separate helper `UIView` object instead of initializing it within
        this view controller.
     */
    
    private func configureOrientationIndicator() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            let attitude = self.estimateImageCaptureManager.deviceAttitude
            let roll = attitude.roll
            let pitch = attitude.pitch
            var horizontalOffset = CGFloat(roll * 50.0)
            if abs(roll) > Double.pi / 2.0 {
                horizontalOffset = CGFloat((Double.pi - abs(roll)) * 50 * sign(roll) )
            }
            let verticalOffset = CGFloat(pitch * 50.0)
            UIView.animate(
                withDuration: 1.0 / 5.0,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.indicatorHorizontalConstraint.constant = horizontalOffset
                    self.indicatorVerticalConstraint.constant = verticalOffset
                    self.view.layoutIfNeeded()
                }, completion: nil
            )
            if abs(horizontalOffset) <= 8 && abs(verticalOffset) <= 6 {
                UIView.animate(withDuration: 1.0 / 5.0) {
                    self.orientationIndicatorImageView.tintColor = .green
                }
            } else {
                UIView.animate(withDuration: 1.0 / 5.0) {
                    self.orientationIndicatorImageView.tintColor = .gray
                }
            }
        }
        timer.fire()
    }

}


extension EstimateImageCaptureViewController: EstimateImageCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, attitude: CMAttitude, error: Error?) {
        guard photo.depthData!.cameraCalibrationData != nil else {return}
        let previewLayer = estimateImageCaptureManager.previewLayer!
        let cropRect = previewLayer.metadataOutputRectConverted(fromLayerRect: previewLayer.bounds)
        submitCapturedData(
            photo: photo,
            attitude: attitude,
            rect: cropRect
        )
    }
}
