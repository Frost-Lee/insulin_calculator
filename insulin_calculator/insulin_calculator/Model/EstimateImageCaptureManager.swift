//
//  EstimateImageCaptureManager.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import AVFoundation
import CoreMotion

protocol EstimateImageCaptureDelegate {
    /**
     Providing the delegate with the captured image data, including `AVCapturePhoto` object and an attitude
     measurement.
     
     - Parameters:
        - output: See [photoOutput(_:didFinishProcessingPhoto:error:)](https://developer.apple.com/documentation/avfoundation/avcapturephotocapturedelegate/2873949-photooutput)
        - photo: The captured photo. [depthData](https://developer.apple.com/documentation/avfoundation/avcapturephoto/2873909-depthdata)
        and [cameraCalibrationData](https://developer.apple.com/documentation/avfoundation/avcapturephoto/2890249-cameracalibrationdata)
        are included. See [photoOutput(_:didFinishProcessingPhoto:error:)](https://developer.apple.com/documentation/avfoundation/avcapturephotocapturedelegate/2873949-photooutput)
        for more details.
        - attitude: The device attitude when capturing the image.
        - error: See [photoOutput(_:didFinishProcessingPhoto:error:)](https://developer.apple.com/documentation/avfoundation/avcapturephotocapturedelegate/2873949-photooutput)
     */
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        attitude: CMAttitude,
        error: Error?
    )
}

class EstimateImageCaptureManager: NSObject {
    
    private var captureSession: AVCaptureSession!
    private var imageCaptureDevice: AVCaptureDevice!
    private var deviceInput: AVCaptureDeviceInput!
    private var photoOutput: AVCapturePhotoOutput!
    
    private var motionManager: CMMotionManager = CMMotionManager()
    private var attitude: CMAttitude?
    
    private var delegate: EstimateImageCaptureDelegate!
    
    /**
     The preview layer of the capture session managed by `EstimateImageCaptureManager`. Adding this
     layer to your view by adding it as a sublayer to the container view's layer and adjust its frame when necessary.
     */
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    /**
     The attitude of the device at the current time. This variable have a usable value only when the `EstimateImageCaptureManager`
     is running.
     */
    var deviceAttitude: CMAttitude {
        get {
            return motionManager.deviceMotion!.attitude
        }
    }
    
    init(delegate: EstimateImageCaptureDelegate) {
        super.init()
        self.delegate = delegate
        createCaptureSession()
        configureCaptureDevices()
        configureDeviceInputs()
        configurePhotoOutput()
        configurePreviewOutput()
    }
    
    /**
     Start the `EstimateImageCaptureManager`, this includes starting the capture session as well as
     the device motion update.
     */
    func startRunning() {
        motionManager.startDeviceMotionUpdates()
        captureSession.startRunning()
    }
    
    /**
     Stop the `EstimateImageCaptureManager`, this includes stopping the capture session as well as
     the device motion update.
     */
    func stopRunning() {
        motionManager.stopDeviceMotionUpdates()
        captureSession.stopRunning()
    }
    
    /**
     Capture an image, the recorded data includes a `AVCapturePhoto` output and a `CMAttitude` output.
     In the `AVCapturePhoto` output, [depthData](https://developer.apple.com/documentation/avfoundation/avcapturephoto/2873909-depthdata)
     and [cameraCalibrationData](https://developer.apple.com/documentation/avfoundation/avcapturephoto/2890249-cameracalibrationdata)
     are recorded. The processed data is passed to the delegate.
     */
    func captureImage() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isDepthDataDeliveryEnabled = true
        photoSettings.isDepthDataFiltered = true
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        attitude = motionManager.deviceMotion!.attitude
    }
    
    private func createCaptureSession() {
        captureSession = AVCaptureSession()
    }

    private func configureCaptureDevices() {
        imageCaptureDevice = AVCaptureDevice.default(
            .builtInTrueDepthCamera,
            for: .depthData,
            position: .unspecified
        )
    }

    private func configureDeviceInputs() {
        deviceInput = try! AVCaptureDeviceInput(device: imageCaptureDevice)
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(deviceInput)
        captureSession.commitConfiguration()
    }

    private func configurePhotoOutput() {
        captureSession.beginConfiguration()
        photoOutput = AVCapturePhotoOutput()
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
        photoOutput.isDepthDataDeliveryEnabled = true
    }

    private func configurePreviewOutput() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
    }
    
}

extension EstimateImageCaptureManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        delegate.photoOutput(
            output,
            didFinishProcessingPhoto: photo,
            attitude: attitude!,
            error: error
        )
    }
}
