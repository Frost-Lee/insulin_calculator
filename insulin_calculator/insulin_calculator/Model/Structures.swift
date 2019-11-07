//
//  Structures.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/17/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation
import SwiftyJSON


/**
 The nutrition information of a specific kind of food. The units are all kilogram per kilogram.
 */
struct NutritionInformation {
    var carbs: Double?
    var calories: Double?
    var fat: Double?
    var protein: Double?
    
    init(json: JSON) throws {
        carbs = json["totalCarbs"].double
        calories = json["calories"].double
        fat = json["totalFat"].double
        protein = json["protein"].double
    }
}


/**
 A single recognition entity candidate object for a recognition session. This object represent a kind of food, properties
 of interest are contained, such as density, nutrition information and classification score. These properties are
 helpful when calculating the total nutrition information of the food.
 */
struct RecognitionEntityCandidate {
    var name: String
    var groupName: String
    /// The classification score of this candidate. The higher this score is, the more likely this candidate is
    /// correct.
    var score: Int
    var nutritionInformation: NutritionInformation
    /// Volume density, in kilogram per cube meter
    var volumeDensity: Double
    /// Area density, in kilogram per square meter
    var areaDensity: Double
    
    init(json: JSON) throws {
        guard
            json["name"].string != nil,
            json["group"].string != nil,
            json["score"].int != nil,
            json["volume_density"].double != nil,
            json["area_density"].double != nil
        else {
            throw NetworkError.unexpectedResponse
        }
        name = json["name"].string!
        groupName = json["group"].string!
        score = json["score"].int!
        volumeDensity = json["volume_density"].double!
        areaDensity = json["area_density"].double!
        nutritionInformation = try NutritionInformation(json: json["nutrition"])
    }
}


/**
 The recognition result of a single object in the submitted image.
 */
struct RecognitionResult {
    /// The bounding box of the object in the original color image. The tuple stands for
    /// `(origin_x, origin_y, width, height)`.
    var boundingBox: (Double, Double, Double, Double)
    /// The volume estimation of the food entity, in cube meter.
    var volume: Double
    /// The top area estimation of the food entity, in square meter
    var area: Double
    /// The candidates of the food classification. Once specify a candidate, its properties can be used to conclude
    /// the total nutrition facts about this kind of food.
    var candidates: [RecognitionEntityCandidate]
    
    /// The selected candidate, can be specified by the user.
    var selectedCandidateIndex: Int
    /// The selected recognition result by the user.
    var selectedCandidate: RecognitionEntityCandidate {
        get {
            return candidates[selectedCandidateIndex]
        }
    }
    /**
     The weight of the recognition result, in kilograms. Negative value means the weight is not available in the
     current status.
     - TODO:
        Make it possible for the user to manually specify the weight if the weight data is not available.
     */
    var weight: Double {
        get {
            if selectedCandidate.volumeDensity != 0 {
                return volume * selectedCandidate.volumeDensity
            } else if selectedCandidate.areaDensity != 0 {
                return area * selectedCandidate.areaDensity
            } else {
                return -1
            }
        }
    }
    /**
     The carbon hydrate weight of the recognition result, in kilograms. Negative value means the carbon hydrate
     weight is not available in the current status.
     */
    var carbs: Double {
        get {
            guard selectedCandidate.nutritionInformation.carbs != nil else {return -1}
            return weight * selectedCandidate.nutritionInformation.carbs!
        }
    }
    
    init(json: JSON) throws {
        guard
            (json["bounding_box"].arrayValue.map{$0.double}.filter{$0 != nil}.count) == 4,
            json["volume"].double != nil,
            json["area"].double != nil
        else {
            throw NetworkError.unexpectedResponse
        }
        let boundingBoxArray = json["bounding_box"].arrayValue.map{$0.double}.filter{$0 != nil}
        boundingBox = (
            boundingBoxArray[0]!,
            boundingBoxArray[1]!,
            boundingBoxArray[2]!,
            boundingBoxArray[3]!
        )
        volume = json["volume"].double!
        area = json["area"].double!
        candidates = try json["candidates"].arrayValue.map{try RecognitionEntityCandidate(json: $0)}
        selectedCandidateIndex = 0
    }
}

/**
 The recognition results of a recognition session.
 */
struct SessionRecognitionResult {
    /// The recognition results of different entities in the submitted image.
    var results: [RecognitionResult]
    var rawJSON: JSON
    
    init(json: JSON) throws {
        rawJSON = json
        results = try json["results"].arrayValue.map{try RecognitionResult(json: $0)}
    }
}


struct SessionRecord {
    var photoURL: URL
    var captureJSONURL: URL
    var recognitionJSONURL: URL
    var timestamp: Date
    var sessionId: UUID
}
