//
//  InitialInformationInputViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/26/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import SVProgressHUD

class InitialInformationInputViewController: UIViewController {
    
    var estimateCapture: EstimateCapture!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    
    private var shouldSave: Bool = false
    
    private var dataManager: DataManager = DataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldSave {
            dataManager.saveEstimateCapture(capture: estimateCapture, completion: nil)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        view.endEditing(true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        shouldSave = true
        SVProgressHUD.showSuccess(withStatus: "Data saved. You can submit it in History later.")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        guard
            nameTextField.hasText &&
            Double(weightTextField.text ?? "na") != nil &&
            Double(weightTextField.text ?? "na")! > 0
        else {doneButton.isEnabled = false; return}
        doneButton.isEnabled = true
        estimateCapture.foodName = nameTextField.text!
        estimateCapture.initialWeight = Double(weightTextField.text ?? "na")!
    }
    
}
