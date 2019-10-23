//
//  EstimateCaptureHistoryTableViewCell.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/23/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class EstimateCaptureHistoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var captureTitleLabel: UILabel!
    @IBOutlet weak var captureSubmitStatusLabel: UILabel!
    @IBOutlet weak var captureImageView: UIImageView!
    
    var estimateCapture: EstimateCapture? {
        didSet {
            guard estimateCapture != nil else {return}
            setEstimateCapture()
        }
    }
    
    private func setEstimateCapture() {
        captureTitleLabel.text = estimateCapture!.timestamp.formattedString(with: "yyyy.MM.dd hh:mm")
        if estimateCapture!.isSubmitted {
            captureSubmitStatusLabel.text = "submitted"
            captureSubmitStatusLabel.textColor = .green
        } else {
            captureSubmitStatusLabel.text = "not submitted"
            captureSubmitStatusLabel.textColor = .secondaryLabel
        }
        captureImageView.image = UIImage(data: try! Data(contentsOf: estimateCapture!.photoURL))
    }

}
