//
//  CandidateTableViewCell.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class CandidateTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    
    var candidate: RecognitionEntityCandidate? {
        didSet {
            guard candidate != nil else {return}
            setCandidate()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
    
    private func setCandidate() {
        guard nameLabel != nil else {return}
        guard groupLabel != nil else {return}
        nameLabel.text = candidate?.name
        groupLabel.text = candidate?.groupName
    }

}
