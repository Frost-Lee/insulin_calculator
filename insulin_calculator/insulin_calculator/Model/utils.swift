//
//  utils.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMotion

// MARK: Data Wrapping.

/**
 Wrap the depth map, calibration data, and attitude data as a `Data` object. The object is in JSON format.
 
 - parameters:
    - depthMap: The depth map captured along with the image, represente as `[[Float32]]`.
    - calibration: The calibration data of the camera when capturing the image.
    - attitude: The device attitude when capturing the image.
 */
func wrapEstimateImageData(
    depthMap: CVPixelBuffer,
    calibration: AVCameraCalibrationData,
    attitude: CMAttitude
) -> Data {
    let jsonDict: [String : Any] = [
        "calibration_data" : [
            "intrinsic_matrix" : (0 ..< 3).map{ x in
                (0 ..< 3).map{ y in calibration.intrinsicMatrix[x][y]}
            },
            "pixel_size" : calibration.pixelSize,
            "intrinsic_matrix_reference_dimensions" : [
                calibration.intrinsicMatrixReferenceDimensions.width,
                calibration.intrinsicMatrixReferenceDimensions.height
            ],
            "lens_distortion_center" : [
                calibration.lensDistortionCenter.x,
                calibration.lensDistortionCenter.y
            ],
            "lens_distortion_lookup_table" : convertLensDistortionLookupTable(
                lookupTable: calibration.lensDistortionLookupTable!
            ),
            "inverse_lens_distortion_lookup_table" : convertLensDistortionLookupTable(
                lookupTable: calibration.inverseLensDistortionLookupTable!
            )
        ],
        "device_attitude" : [
            "pitch" : attitude.pitch,
            "roll" : attitude.roll,
            "yaw" : attitude.yaw
        ],
        "depth_data" : convertDepthData(depthMap: depthMap)
    ]
    let jsonStringData = try! JSONSerialization.data(
        withJSONObject: jsonDict,
        options: .prettyPrinted
    )
    return jsonStringData
}


// MARK: Data Convertion.

/**
 Convert the depth data from `CVPixelBuffer` to `[[Float32]]`.
 
 - parameters:
    - depthMap: The pixel buffer containing the depth data.
 
 - returns:
    The type casted depth data, represented as `[[Float32]]`.
 */
func convertDepthData(depthMap: CVPixelBuffer) -> [[Float32]] {
    let width = CVPixelBufferGetWidth(depthMap)
    let height = CVPixelBufferGetHeight(depthMap)
    var convertedDepthMap: [[Float32]] = Array(
        repeating: Array(repeating: 0, count: width),
        count: height
    )
    CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
    let floatBuffer = unsafeBitCast(
        CVPixelBufferGetBaseAddress(depthMap),
        to: UnsafeMutablePointer<Float32>.self
    )
    for row in 0 ..< height {
        for col in 0 ..< width {
            convertedDepthMap[row][col] = floatBuffer[width * row + col]
        }
    }
    CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
    return convertedDepthMap
}


/**
 Convert the `lensDistortionLookupTable` or `inverseLensDistortionLookupTable` to a `Float` array.
 
 - parameters:
    - lookupTable: The `lensDistortionLookupTable` or `inverseLensDistortionLookupTable`,
        see [AVCameraCalibrationData](https://developer.apple.com/documentation/avfoundation/avcameracalibrationdata)
        for details.
 
 - returns:
    A `Float` array that contains numbers in the lookup table.
 */
func convertLensDistortionLookupTable(lookupTable: Data) -> [Float] {
    let tableLength = lookupTable.count / MemoryLayout<Float>.size
    var floatArray: [Float] = Array(repeating: 0, count: tableLength)
    _ = floatArray.withUnsafeMutableBytes{lookupTable.copyBytes(to: $0)}
    return floatArray
}
