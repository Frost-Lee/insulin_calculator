//
//  EstimateCaptureSubmissionViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/23/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import SVProgressHUD


protocol EstimateCaptureSubmissionDelegate {
    func submissionViewControllerClosed(submitted: Bool)
}


class EstimateCaptureSubmissionViewController: UIViewController {
    
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var initialWeightLabel: UILabel!
    @IBOutlet weak var netWeightLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    
    var delegate: EstimateCaptureSubmissionDelegate?
    var estimateCapture: EstimateCapture?
    
    private var isSubmitted: Bool = false
    
    private var backendConnector = BackendConnector.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false
        setEstimateCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.submissionViewControllerClosed(submitted: isSubmitted)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        view.endEditing(true)
    }
    
    private func setEstimateCapture() {
        guard estimateCapture != nil else {return}
        capturedImageView.image = UIImage(data: try! Data(contentsOf: estimateCapture!.photoURL))!
        initialWeightLabel.text = estimateCapture?.initialWeight.collectWeightString()
        netWeightLabel.text = "-"
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        submitButton.isEnabled = nameTextField.hasText && Double(weightTextField.text ?? "na") != nil
        guard weightTextField.hasText else {return}
        guard estimateCapture!.initialWeight - Double(weightTextField.text!)! >= 0 else {submitButton.isEnabled = false;return}
        netWeightLabel.text = (estimateCapture!.initialWeight - Double(weightTextField.text!)!).collectWeightString()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIBarButtonItem) {
        SVProgressHUD.show(withStatus: "Submitting")
        print("Tapped")
        backendConnector.getDensityCollectionResult(
            token: "abcd1234",
            session_id: estimateCapture!.sessionId.uuidString,
            jsonURL: estimateCapture!.jsonURL,
            photoURL: estimateCapture!.photoURL,
            name: nameTextField.text!,
            weight: String(estimateCapture!.initialWeight - Double(weightTextField.text!)!)
        ) { error in
            guard error == nil else {
                print("Error")
                SVProgressHUD.showError(withStatus: "Submisstion Failed")
                self.dismiss(animated: true, completion: nil)
                return
            }
            SVProgressHUD.showSuccess(withStatus: "Submitted")
            self.isSubmitted = true
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}
