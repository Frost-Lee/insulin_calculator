//
//  AdditionalImageCaptureViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/25/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class AdditionalImageCaptureViewController: UIViewController {
    
    @IBOutlet weak var previewContainerView: UIView!
    
    var estimateCapture: EstimateCapture!
    
    private var imageCaptureManager: ImageCaptureManager!
    private var dataManager: DataManager = DataManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        imageCaptureManager = ImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(imageCaptureManager.previewLayer, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageCaptureManager.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageCaptureManager.previewLayer.frame = previewContainerView.bounds
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "showInitialInformationInputViewController":
            let destination = segue.destination as! InitialInformationInputViewController
            destination.estimateCapture = sender as? EstimateCapture
        default:
            break
        }
    }
    
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        imageCaptureManager.captureImage()
    }
    
    private func processCapturedData(imageData: Data) {
        dataManager.saveFile(data: imageData, extensionName: "jpg") { url in
            self.estimateCapture.additionalPhotoURL = url
            self.performSegue(withIdentifier: "showInitialInformationInputViewController", sender: self.estimateCapture)
        }
    }
    
}


extension AdditionalImageCaptureViewController: ImageCaptureDelegate {
    func captureOutput(image: CGImage, error: Error?) {
        let jpegData = UIImage(cgImage: image).jpegData(compressionQuality: 1.0)!
        processCapturedData(imageData: jpegData)
    }
}
