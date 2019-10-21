//
//  EstimateResultViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/21/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class EstimateResultViewController: UIViewController {

    @IBOutlet weak var responseTextView: UITextView!
    
    var sessionRecognitionResult: SessionRecognitionResult? {
        didSet {
            fillTextViewContent(content: sessionRecognitionResult?.rawJSON.rawString())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillTextViewContent(content: sessionRecognitionResult?.rawJSON.rawString())
    }
    
    private func fillTextViewContent(content: String?) {
        guard content != nil else {return}
        responseTextView.text = content
    }

}
