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
    
    private var estimateImageCaptureManager: EstimateImageCaptureManager!
    
    private var dataManager: DataManager = DataManager.shared
    private var backendConnector: BackendConnector = BackendConnector.shared
    
    private var isBusy: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        estimateImageCaptureManager = EstimateImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(estimateImageCaptureManager.previewLayer, at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        estimateImageCaptureManager.startRunning()
        deviceOrientationIndicatorView.startRunning() {
            return self.estimateImageCaptureManager.deviceAttitude
        }
        setupVolumeButtonListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deviceOrientationIndicatorView.stopRunning()
        estimateImageCaptureManager.stopRunning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "showEstimateResultViewController":
            let destination = (segue.destination as! UINavigationController).topViewController!
            (destination as! EstimateResultViewController).sessionRecord = sender as? SessionRecord
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        estimateImageCaptureManager.previewLayer.frame = previewContainerView.bounds
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            captureButtonTapped(nil)
        }
    }

    @IBAction func captureButtonTapped(_ sender: Any?) {
<<<<<<< HEAD
        guard !isBusy else {return}
        isBusy = true
        SVProgressHUD.show(withStatus: "Processing Calculation Data")
=======
        captureButton.isEnabled = false
        SVProgressHUD.show(withStatus: "Fetching Estimation Result")
>>>>>>> c6b3090c2dd5038697662d57cbcb1cec98ba3149
        estimateImageCaptureManager.captureImage()
    }
    
    private func setupVolumeButtonListener() {
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(true)
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
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
<<<<<<< HEAD
            self.launchWeightInputAlert() { input in
                guard input != nil else {SVProgressHUD.dismiss();self.isBusy=false;return}
                self.dataManager.saveEstimateCapture(capture: EstimateCapture(
                    jsonURL: jsonURL!,
                    photoURL: photoURL!,
                    timestamp: Date(),
                    sessionId: UUID(),
                    isSubmitted: false,
                    initialWeight: Double(input!) ?? 0.0
                )) { error in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: "Error occurred when saving the estimate.")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "Data Captured, you can submit it later.")
                    }
                    self.isBusy = false
                }
            }
        }
    }
    
    private func launchWeightInputAlert(savedAction: ((String?) -> ())?) {
        let alertController = UIAlertController(
            title: "Weight of the Food?",
            message: "The weight of the food including its plate.",
            preferredStyle: .alert
        )
        let saveAction = UIAlertAction(title: "Save", style: .default) { alert in
            savedAction?(alertController.textFields?.first?.text)
        }
        saveAction.isEnabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alert in
            savedAction?(nil)
        }
        alertController.addTextField() { textField in
            textField.placeholder = "Weight digits (in gram)"
            textField.keyboardType = .decimalPad
        }
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alertController.textFields!.first!,
            queue: .main
        ) { notification in
            saveAction.isEnabled = Double(alertController.textFields!.first!.text ?? "na") != nil
        }
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        present(alertController, animated: true, completion: nil)
=======
//            UIImageWriteToSavedPhotosAlbum(UIImage(data: try! Data(contentsOf: photoURL!))!, nil, nil, nil)
//            SVProgressHUD.dismiss()
//            let activityViewController = UIActivityViewController(activityItems: [jsonURL!], applicationActivities: nil)
//            self.present(activityViewController, animated: true, completion: nil)
            self.backendConnector.getRecognitionResult(
                token: "abcd1234",
                session_id: sessionId.uuidString,
                jsonURL: jsonURL!,
                photoURL: photoURL!
            ) { result, error in
                guard error == nil else {
                    self.captureButton.isEnabled = true
                    SVProgressHUD.showError(withStatus: "Server Error")
                    return
                }
                self.dataManager.saveFile(data: result!.rawJSON.rawString()!.data(using: .utf8)!, extensionName: "json") { url in
                    self.captureButton.isEnabled = true
                    SVProgressHUD.showSuccess(withStatus: "Done")
                    let sessionRecord = SessionRecord(
                        photoURL: photoURL!,
                        captureJSONURL: jsonURL!,
                        recognitionJSONURL: url,
                        timestamp: Date(),
                        sessionId: sessionId
                    )
                    self.performSegue(withIdentifier: "showEstimateResultViewController", sender: sessionRecord)
                }
            }
        }
>>>>>>> c6b3090c2dd5038697662d57cbcb1cec98ba3149
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
