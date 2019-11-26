//
//  HomeViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/26/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController {
    
    @IBAction func startCaptureButtonTapped(_ sender: UIButton) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            performSegue(withIdentifier: "showEstimateImageCaptureViewController", sender: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "showEstimateImageCaptureViewController", sender: nil)
                    }
                }
            }
        default:
            let alertController = UIAlertController(
                title: "Camera not Authorized",
                message: "You can authorize the camera usage in Settings.",
                preferredStyle: .alert
            )
            let dismissAction = UIAlertAction(title: "OK", style: .default) { alert in
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(dismissAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func showRulesButtonTapped(_ sender: UIButton) {
        UIApplication.shared.open(
            URL(string: "https://docs.google.com/document/d/1G5qJOI4krUdZLZIz6GNiE3TsblY8DXmVjdFKy4A3VjI/edit?usp=sharing")!,
            options: [:],
            completionHandler: nil
        )
    }

}
