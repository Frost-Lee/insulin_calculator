//
//  AdditionalImageCaptureViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/25/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import SVProgressHUD

class AdditionalImageCaptureViewController: UIViewController {
    
    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var previewBlurView: UIVisualEffectView!
    
    var estimateCapture: EstimateCapture!
    
    private var imageCaptureManager: ImageCaptureManager!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        imageCaptureManager = ImageCaptureManager(delegate: self)
        previewContainerView.layer.insertSublayer(imageCaptureManager.previewLayer, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageCaptureManager.startRunning()
        isAvailable = true
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
        guard isAvailable else {return}
        isAvailable = false
        SVProgressHUD.show(withStatus: "Processing Data")
        imageCaptureManager.captureImage()
    }
    
    private func processCapturedData(imageData: Data) {
        dataManager.saveFile(data: imageData, extensionName: "jpg") { url in
            self.dataManager.removeFile(url: self.estimateCapture?.additionalPhotoURL)
            self.estimateCapture.additionalPhotoURL = url
            SVProgressHUD.dismiss()
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
