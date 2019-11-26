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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        weightTextField.becomeFirstResponder()
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
        capturedImageView.image = UIImage(data: try! Data(contentsOf: estimateCapture!.photoURL!))!
        initialWeightLabel.text = estimateCapture?.initialWeight!.collectWeightString()
        netWeightLabel.text = "-"
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        guard
            Double(weightTextField.text ?? "na") != nil &&
            Double(weightTextField.text ?? "na")! >= 0 &&
            estimateCapture!.initialWeight! - Double(weightTextField.text ?? "na")! > 0
        else {submitButton.isEnabled = false; return}
        submitButton.isEnabled = true
        estimateCapture?.plateWeight = Double(weightTextField.text ?? "na")!
        netWeightLabel.text = (estimateCapture!.initialWeight! - estimateCapture!.plateWeight!).collectWeightString()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIBarButtonItem) {
        SVProgressHUD.show(withStatus: "Submitting")
        backendConnector.getDensityCollectionResult(
            token: "abcd1234",
            sessionId: estimateCapture!.sessionId!.uuidString,
            jsonURL: estimateCapture!.jsonURL!,
            imageURL: estimateCapture!.photoURL!,
            additionalImageURL: estimateCapture!.additionalPhotoURL!,
            name: estimateCapture!.foodName!,
            weight: String(estimateCapture!.initialWeight! - estimateCapture!.plateWeight!)
        ) { error in
            guard error == nil else {
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
