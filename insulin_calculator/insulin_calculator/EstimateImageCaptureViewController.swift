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
import SVProgressHUD

class EstimateImageCaptureViewController: UIViewController {

    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var captureButton: UIButton! {
        didSet {
            captureButton.layer.cornerRadius = 8.0
        }
    }
    
    var orientationIndicateView: DeviceOrientationIndicateView = {
        let view = DeviceOrientationIndicateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var estimateImageCaptureManager: EstimateImageCaptureManager!
    
    private var dataManager: DataManager = DataManager.shared
    private var backendConnector: BackendConnector = BackendConnector.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        estimateImageCaptureManager = EstimateImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(estimateImageCaptureManager.previewLayer, at: 0)
        view.addSubview(orientationIndicateView)
        NSLayoutConstraint.activate([
            orientationIndicateView.topAnchor.constraint(equalTo: previewContainerView.topAnchor, constant: 0),
            orientationIndicateView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: 0),
            orientationIndicateView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor, constant: 0),
            orientationIndicateView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor, constant: 0),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        estimateImageCaptureManager.startRunning()
        orientationIndicateView.startRunning() {
            return self.estimateImageCaptureManager.deviceAttitude
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        orientationIndicateView.stopRunning()
        estimateImageCaptureManager.stopRunning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "showEstimateResultViewController":
            let destination = (segue.destination as! UINavigationController).topViewController!
            (destination as! EstimateResultViewController).sessionRecognitionResult = sender as? SessionRecognitionResult
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        estimateImageCaptureManager.previewLayer.frame = previewContainerView.bounds
    }

    @IBAction func captureButtonTapped(_ sender: UIButton) {
        captureButton.isEnabled = false
        SVProgressHUD.show(withStatus: "Fetching Estimation Result")
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
            self.backendConnector.getRecognitionResult(
                token: "abcd1234",
                session_id: UUID().uuidString,
                jsonURL: jsonURL!,
                photoURL: photoURL!
            ) { result, error in
                guard error == nil else {
                    self.captureButton.isEnabled = true
                    SVProgressHUD.showError(withStatus: "Server Error")
                    return
                }
                self.captureButton.isEnabled = true
                SVProgressHUD.showSuccess(withStatus: "Done")
                self.performSegue(withIdentifier: "showEstimateResultViewController", sender: result!)
            }
        }

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
