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

    override func viewDidLoad() {
        super.viewDidLoad()
        estimateImageCaptureManager = EstimateImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(estimateImageCaptureManager.previewLayer, at: 0)
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
    }
    
    // MARK: - Orientation Indicator Configuration
    
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
        UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: cropImage(photo: photo, rect: cropRect)!), nil, nil, nil)
        cacheEstimateImageCaptureData(
            token: "abcd1234",
            depthMap: convertAndCropDepthData(depthData: photo.depthData!, rect: cropRect),
            foodSegmentationMask: [[1]],
            calibration: photo.depthData!.cameraCalibrationData!,
            attitude: attitude,
            cropRect: cropRect
        ) { url in
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [])
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

