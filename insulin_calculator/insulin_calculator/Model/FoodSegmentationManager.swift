//
//  FoodSegmentationManager.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation
import Vision

protocol FoodSegmentationDelegate {
    /**
     Providing the delegate with the predicted food segmentation mask.
     
     - Parameters:
        - multiArray: The food segmentation mask. Each value stands for the probability of the corresponding
            pixel in the image being food.
     */
    func maskOutput(multiArray: MLMultiArray)
}


class FoodSegmentationManager: NSObject {
    
    private var model: VNCoreMLModel?
    private var request: VNCoreMLRequest?
    private var delegate: FoodSegmentationDelegate!
    
    init(delegate: FoodSegmentationDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    /**
     Trigger the prediction of the model. The result is passed to the delegate.
     
     - Parameters:
        - image: The image to be predicted. The image will be center cropped to match the input shape of
            the model.
     */
    func predict(image: CGImage) {
        try! VNImageRequestHandler(cgImage: image, options: [:]).perform([request!])
    }
    
    private func loadModel() {
        model = try! VNCoreMLModel(for: FoodSegmentationModel().model)
    }
    
    private func configureRequest() {
        request = VNCoreMLRequest(model: model!) { (finishedRequest, error) in
            let results = finishedRequest.results as! [VNCoreMLFeatureValueObservation]
            let probabilityMap = results.first!.featureValue.multiArrayValue!
            self.delegate.maskOutput(multiArray: probabilityMap)
        }
        request?.imageCropAndScaleOption = .centerCrop
    }
}
