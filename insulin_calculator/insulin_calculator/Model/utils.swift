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
import CoreML

/**
 Wrap the depth map, calibration data, and attitude data as a `Data` object. The object is in JSON format.
 
 - Parameters:
    - depthMap: The depth map captured along with the image, represente as `[[Float32]]`.
    - calibration: The calibration data of the camera when capturing the image.
    - attitude: The device attitude when capturing the image.
 */
func wrapEstimateImageData(
    depthMap: [[Float32]],
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
            ]
        ],
        "device_attitude" : [
            "pitch" : attitude.pitch,
            "roll" : attitude.roll,
            "yaw" : attitude.yaw
        ],
        "depth_data" : depthMap
    ]
    let jsonStringData = try! JSONSerialization.data(
        withJSONObject: jsonDict,
        options: .prettyPrinted
    )
    return jsonStringData
//    dataManager.saveFile(data: jsonStringData, extensionName: "json", completion: completion)
}


/**
 Convert the depth data from `CVPixelBuffer` to `[[Float32]]`.
 
 - Parameters:
    - depthMap: The pixel buffer containing the depth data.
 
 - Returns:
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
            if floatBuffer[width * row + col].isNaN || floatBuffer[width * row + col].isInfinite {
                convertedDepthMap[row][col] = 0
            } else {
                convertedDepthMap[row][col] = floatBuffer[width * row + col]
            }
        }
//        DispatchQueue.concurrentPerform(iterations: endCol - startCol) { index in
//            depthMap[realRow][index] = 1.0 / floatBuffer[width * row + index + startCol]
//        }
//        realRow += 1
    }
    CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
    return convertedDepthMap
}


/**
 Get the matched point after applying a distortion specified by a distortion lookup table. Reference [here](https://github.com/shu223/iOS-Depth-Sampler/issues/5).
 */
func lensDistortionPoint(for point: CGPoint, lookupTable: Data, distortionOpticalCenter opticalCenter: CGPoint, imageSize: CGSize) -> CGPoint {
    // The lookup table holds the relative radial magnification for n linearly spaced radii.
    // The first position corresponds to radius = 0
    // The last position corresponds to the largest radius found in the image.
      
    // Determine the maximum radius.
    let delta_ocx_max = Float(max(opticalCenter.x, imageSize.width  - opticalCenter.x))
    let delta_ocy_max = Float(max(opticalCenter.y, imageSize.height - opticalCenter.y))
    let r_max = sqrt(delta_ocx_max * delta_ocx_max + delta_ocy_max * delta_ocy_max)
      
    // Determine the vector from the optical center to the given point.
    let v_point_x = Float(point.x - opticalCenter.x)
    let v_point_y = Float(point.y - opticalCenter.y)
      
    // Determine the radius of the given point.
    let r_point = sqrt(v_point_x * v_point_x + v_point_y * v_point_y)
      
    // Look up the relative radial magnification to apply in the provided lookup table
    let magnification: Float = lookupTable.withUnsafeBytes { (lookupTableValues: UnsafePointer<Float>) in
        let lookupTableCount = lookupTable.count / MemoryLayout<Float>.size
          
        if r_point < r_max {
            // Linear interpolation
            let val   = r_point * Float(lookupTableCount - 1) / r_max
            let idx   = Int(val)
            let frac  = val - Float(idx)
              
            let mag_1 = lookupTableValues[idx]
            let mag_2 = lookupTableValues[idx + 1]
              
            return (1.0 - frac) * mag_1 + frac * mag_2
        } else {
            return lookupTableValues[lookupTableCount - 1]
        }
    }
    
    // Apply radial magnification
    let new_v_point_x = v_point_x + magnification * v_point_x
    let new_v_point_y = v_point_y + magnification * v_point_y
      
    // Construct output
    return CGPoint(x: opticalCenter.x + CGFloat(new_v_point_x), y: opticalCenter.y + CGFloat(new_v_point_y))
}


/**
 Rectify the image from the lens distortion using calibration data.
 
 - Parameters:
    - buffer: The `CVPixelBuffer` object containing the image.
    - calibration: The camera calibration data of the image.
 
 - Returns:
    The image buffer of the rectified image.
 */
func rectifyImage(
    from buffer: CVPixelBuffer,
    using calibration: AVCameraCalibrationData
) -> CVPixelBuffer {
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    let pixelType = CVPixelBufferGetPixelFormatType(buffer)
    var rectifiedBuffer: CVPixelBuffer? = nil
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelType, nil, &rectifiedBuffer)
    CVPixelBufferLockBaseAddress(rectifiedBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 1))
    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let bytesPerPixel = bytesPerRow / width
    let rectifiedBufferBaseAddress = CVPixelBufferGetBaseAddress(rectifiedBuffer!)!
    let originalBufferBaseAddress = CVPixelBufferGetBaseAddress(buffer)!
    let imageScale = CGFloat(width) / calibration.intrinsicMatrixReferenceDimensions.width
    print(imageScale)
    let distortionCenter = CGPoint(x: calibration.lensDistortionCenter.x * imageScale , y: calibration.lensDistortionCenter.y * imageScale)
    for row in 0 ..< height {
        let rectifiedRowBaseAddress = rectifiedBufferBaseAddress + row * bytesPerRow
        let rectifiedRowData = UnsafeMutableBufferPointer(start: rectifiedRowBaseAddress.assumingMemoryBound(to: UInt8.self), count: bytesPerRow)
//        DispatchQueue.concurrentPerform(iterations: width) { col in
//            let rectifiedPoint = CGPoint(x: col, y: row)
//            let originalPoint = lensDistortionPoint(
//                for: rectifiedPoint,
//                lookupTable: calibration.lensDistortionLookupTable!,
//                distortionOpticalCenter: distortionCenter,
//                imageSize: CGSize(width: width, height: height)
//            )
//            if !((0 ..< width).contains(Int(originalPoint.x))) || !((0 ..< height).contains(Int(originalPoint.y))) {
//            } else {
//                let originalRowBaseAddress = originalBufferBaseAddress + Int(originalPoint.y) * bytesPerRow
//                let originalRowData = UnsafeBufferPointer(start: originalRowBaseAddress.assumingMemoryBound(to: UInt8.self), count: bytesPerRow)
//                for byteIndex in 0 ..< bytesPerPixel {
//                    rectifiedRowData[col * bytesPerPixel + byteIndex] = originalRowData[Int(originalPoint.x) * bytesPerPixel + byteIndex]
//                }
//            }
//        }
        for col in 0 ..< width {
            let rectifiedPoint = CGPoint(x: col, y: row)
            let originalPoint = lensDistortionPoint(
                for: rectifiedPoint,
                lookupTable: calibration.lensDistortionLookupTable!,
                distortionOpticalCenter: distortionCenter,
                imageSize: CGSize(width: width, height: height)
            )
            if !((0 ..< width).contains(Int(originalPoint.x))) || !((0 ..< height).contains(Int(originalPoint.y))) {
                continue
            }
            let originalRowBaseAddress = originalBufferBaseAddress + Int(originalPoint.y) * bytesPerRow
            let originalRowData = UnsafeBufferPointer(start: originalRowBaseAddress.assumingMemoryBound(to: UInt8.self), count: bytesPerRow)
            for byteIndex in 0 ..< bytesPerPixel {
                rectifiedRowData[col * bytesPerPixel + byteIndex] = originalRowData[Int(originalPoint.x) * bytesPerPixel + byteIndex]
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 1))
    CVPixelBufferUnlockBaseAddress(rectifiedBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    return rectifiedBuffer!
}


/**
 Crop the `AVCapturePhoto` with `rect`.
 
 - Parameters:
    - photo: The image to crop, represented as `AVCapturePhoto`.
    - rect: The rect that represents the region to preserve in the image. See [metadataOutputRectConverted](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/1623495-metadataoutputrectconverted)
    for details.
 
 - Returns:
    The `CGImage` object cropped from `photo` with `rect`.
 */
@available(*, deprecated, message: "It's better to submit raw data to the server.")
func cropImage(photo: AVCapturePhoto, rect: CGRect) throws -> CGImage {
    let image = photo.cgImageRepresentation()!.takeUnretainedValue()
    let croppedImage = image.cropping(to: CGRect(
        x: rect.origin.x * CGFloat(image.width),
        y: rect.origin.y * CGFloat(image.height),
        width: rect.size.width * CGFloat(image.width),
        height: rect.size.height * CGFloat(image.height)
    ))
    guard croppedImage != nil else {throw ValueError.shapeMismatch}
    return croppedImage!
}


/**
 Convert the `MLMultiArray` object to a 2d `Float32` array. Note that the `MLMultiArray` object have to
 have shape 1 * w * h.
 
 - Parameters:
    - multiArray: The multiarray to be converted.
 
 - Returns:
    A 2d `Float32` array converted from `multiArray` with shape w * h.
 */
@available(*, deprecated, message: "No ML model running on front end currently.")
func convertSegmentMaskData(multiArray: MLMultiArray) throws -> [[Float32]] {
    let totalValues = multiArray.count
    let area = Int(truncating: multiArray.shape[1]) * Int(truncating: multiArray.shape[2])
    guard multiArray.shape.count == 3 && area == totalValues else {throw ValueError.shapeMismatch}
    let floatMutablePointer = multiArray.dataPointer.bindMemory(to: Float32.self, capacity: multiArray.count)
    let floatArray = Array(UnsafeBufferPointer(start: floatMutablePointer, count: multiArray.count))
    var float2dArray: [[Float32]] = Array(
        repeating: Array(repeating: 0, count: multiArray.shape[1] as! Int),
        count: multiArray.shape[2] as! Int
    )
    for row in 0 ..< (multiArray.shape[1] as! Int) {
        for col in 0 ..< (multiArray.shape[2] as! Int) {
            float2dArray[row][col] = floatArray[row * col + col]
        }
    }
    return float2dArray
}
