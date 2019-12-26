//
//  SettingsTableViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 12/26/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var filterDepthSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostTextField.text = UserDefaults.standard.string(forKey: "host")!
        portTextField.text = UserDefaults.standard.string(forKey: "port")!
        filterDepthSwitch.isOn = UserDefaults.standard.bool(forKey: "isDepthDataFiltered")
    }

    @IBAction func hostInputFinished(_ sender: UITextField) {
        guard sender.text != nil else {return}
        UserDefaults.standard.set(sender.text!, forKey: "host")
    }
    
    @IBAction func portInputFinished(_ sender: UITextField) {
        guard sender.text != nil else {return}
        UserDefaults.standard.set(sender.text!, forKey: "port")
    }
    
    @IBAction func filterDepthToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isDepthDataFiltered")
    }
}


extension SettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
