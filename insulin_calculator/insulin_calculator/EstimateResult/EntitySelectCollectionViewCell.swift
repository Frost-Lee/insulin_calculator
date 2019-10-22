//
//  EntitySelectCollectionViewCell.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class EntitySelectCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var indexLabel: UILabel! {
        didSet {
            indexLabel.layer.cornerRadius = 8.0
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                indexLabel.backgroundColor = .secondarySystemFill
                indexLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            } else {
                indexLabel.backgroundColor = .secondarySystemBackground
                indexLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            }
        }
    }
    
}
