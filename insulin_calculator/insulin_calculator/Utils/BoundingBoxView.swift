//
//  BoundingBoxView.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 2/10/20.
//  Copyright © 2020 李灿晨. All rights reserved.
//

import UIKit

class BoundingBoxView: UIView {

    var boundingBoxes: [(Double, Double, Double, Double)]? {
        didSet {
            guard boundingBoxes != nil else {return}
            setNeedsDisplay()
        }
    }
    static let boundingBoxColors: [UIColor] = [#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1), #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1), #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1), #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)]

    override func draw(_ rect: CGRect) {
        for (index, box) in boundingBoxes!.enumerated() {
            let colors = BoundingBoxView.boundingBoxColors
            drawBoundingBox(boundingBox: box, color: colors[index % colors.count])
        }
    }
    
    private func drawBoundingBox(
        boundingBox: (Double, Double, Double, Double),
        color: UIColor
    ) {
        let viewWidth = Double(bounds.width)
        let viewHeight = Double(bounds.height)
        print(viewWidth, viewHeight)
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2)
        color.set()
        context?.addRect(CGRect(
            x: viewWidth * boundingBox.0,
            y: viewHeight * boundingBox.2,
            width: viewWidth * (boundingBox.1 - boundingBox.0),
            height: viewHeight * (boundingBox.3 - boundingBox.2)
        ))
        context?.strokePath()
    }

}
