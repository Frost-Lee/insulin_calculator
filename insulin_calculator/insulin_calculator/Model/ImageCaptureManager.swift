//
//  AdditionalImageCaptureManager.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/25/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import AVFoundation

protocol ImageCaptureDelegate {
    /**
     Providing the delegate with the captured data.
     
     - parameters:
        - image: The colored image.
        - error: See [photoOutput(_:didFinishProcessingPhoto:error:)](https://developer.apple.com/documentation/avfoundation/avcapturephotocapturedelegate/2873949-photooutput)
     */
    func captureOutput(image: CGImage, error: Error?)
}

class ImageCaptureManager: NSObject {
    
    private var captureSession: AVCaptureSession!
    private var imageCaptureDevice: AVCaptureDevice!
    private var deviceInput: AVCaptureDeviceInput!
    private var photoOutput: AVCapturePhotoOutput!
    
    private var delegate: ImageCaptureDelegate!
    
    /**
     The preview layer of the capture session managed by `ImageCaptureManager`. Adding this
     layer to your view by adding it as a sublayer to the container view's layer and adjust its frame when necessary.
     */
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    /**
     Initialize a `ImageCaptureManager` instance.
     
     - parameters:
        - delegate: The delegate for handling output of the `ImageCaptureManager` instance.
     */
    init(delegate: ImageCaptureDelegate) {
        super.init()
        self.delegate = delegate
        createCaptureSession()
        configureCaptureDevices()
        configureDeviceInputs()
        configurePhotoOutput()
        configurePreviewOutput()
    }
    
    /**
     Start the `ImageCaptureManager`, this includes starting the capture session.
     */
    func startRunning() {
        captureSession.startRunning()
    }
    
    /**
     Stop the `ImageCaptureManager`, this includes stopping the capture session.
     */
    func stopRunning() {
        captureSession.stopRunning()
    }
    
    /**
     Capture an image. The result will be passed to the delegate.
     */
    func captureImage() {
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func createCaptureSession() {
        captureSession = AVCaptureSession()
    }

    private func configureCaptureDevices() {
        imageCaptureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
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
    }

    private func configurePreviewOutput() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
    }
    
}

extension ImageCaptureManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        delegate.captureOutput(
            image: photo.cgImageRepresentation()!.takeUnretainedValue(),
            error: error
        )
    }
}

