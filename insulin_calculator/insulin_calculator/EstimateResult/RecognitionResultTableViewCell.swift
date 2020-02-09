//
//  RecognitionResultTableViewCell.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 2/7/20.
//  Copyright © 2020 李灿晨. All rights reserved.
//

import UIKit

class RecognitionResultTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    
    var recognitionResult: RecognitionResult? {
        didSet {
            guard recognitionResult != nil else {return}
            setRecognitionResult()
        }
    }
    
    private func setRecognitionResult() {
        guard
            sizeLabel != nil,
            weightLabel != nil,
            carbsLabel != nil
        else {return}
        nameLabel.text = recognitionResult?.selectedCandidate.name
        sizeLabel.text = recognitionResult?.volume.volumeString()
        weightLabel.text = recognitionResult?.weight.weightString()
        carbsLabel.text = recognitionResult?.carbs.weightString()
    }

}
