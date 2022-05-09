//
//  ViewController.swift
//  StencilCam
//
//  Created by Mike on 2019-08-28.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var captureSession = AVCaptureSession()
    let cameraOutput = AVCapturePhotoOutput()
    var gestureRecognizer = UIPinchGestureRecognizer()
    var prevZoomFactor: CGFloat = 1
    var captureDevice: AVCaptureDevice?
    enum CameraDirection {
        case front
        case back
    }
    var currentDirection: CameraDirection = .back
    var deviceOrientation: UIImage.Orientation!
    var flashEffectView = UIView()
    var imageView: UIImageView!
    var currentImage: UIImage!
    var slider: UISlider!
    var sliderPortraitPos = CGPoint()
    var gridFrame: CGRect!
    var gridView: UIView!
    var motionManager: CMMotionManager!
    var flashMode: AVCaptureDevice.FlashMode! = .off
    let buttonFlashSwitch: UIButton = UIButton(type: UIButton.ButtonType.custom)
    var buttonFlashSwitchPortraitPos = CGPoint()
    let buttonCameraSwitch: UIButton = UIButton(type: UIButton.ButtonType.custom)
    var buttonCameraSwitchPortraitPos = CGPoint()
    let buttonImportPicture: UIButton = UIButton(type: UIButton.ButtonType.custom)
    var buttonImportPicturePortraitPos = CGPoint()
    let buttonGridSwitch: UIButton = UIButton(type: UIButton.ButtonType.custom)
    var buttonGridSwitchPortraitPos = CGPoint()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        captureDevice = getDevice(position: .back)
        deviceOrientation = .right

        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
        
        sliderPortraitPos = CGPoint(x: view.frame.size.width - 125, y: (UIScreen.main.bounds.size.height * 0.5) - 200)
        slider = UISlider(frame: CGRect(origin: CGPoint(x: sliderPortraitPos.x, y: sliderPortraitPos.y), size: CGSize(width: 200, height: 400)))
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .black
        slider.transform = CGAffineTransform(rotationAngle: deg2rad(90))
        slider.maximumValue = 100
        slider.minimumValue = 0
        slider.value = 50
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.isEnabled = false
        view.addSubview(slider)
  
        //buttons
        buttonFlashSwitchPortraitPos = CGPoint(x: 10, y: 30)
        buttonFlashSwitch.setImage(UIImage(named: "flash-off"), for: UIControl.State.normal)
        buttonFlashSwitch.addTarget(self, action: #selector(switchFlash), for: UIControl.Event.touchUpInside)
        buttonFlashSwitch.frame = CGRect(x: buttonFlashSwitchPortraitPos.x, y: buttonFlashSwitchPortraitPos.y, width: 30, height: 40)
        buttonFlashSwitch.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        view.addSubview(buttonFlashSwitch)
        
        buttonGridSwitchPortraitPos = CGPoint(x: view.frame.size.width - 40, y: 32)
        buttonGridSwitch.setImage(UIImage(named: "grid"), for: UIControl.State.normal)
        buttonGridSwitch.addTarget(self, action: #selector(switchGrid), for: UIControl.Event.touchUpInside)
        buttonGridSwitch.frame = CGRect(x: buttonGridSwitchPortraitPos.x, y: buttonGridSwitchPortraitPos.y, width: 32, height: 32)
        buttonGridSwitch.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        view.addSubview(buttonGridSwitch)
        
        buttonImportPicturePortraitPos = CGPoint(x: view.frame.size.width * 0.05, y: view.frame.size.height - (view.frame.size.height * 0.11))
        buttonImportPicture.setImage(UIImage(named: "circle"), for: UIControl.State.normal) //default icon
        buttonImportPicture.imageView?.contentMode = .scaleAspectFill
        buttonImportPicture.addTarget(self, action: #selector(importPicture), for: UIControl.Event.touchUpInside)
        buttonImportPicture.frame = CGRect(x: buttonImportPicturePortraitPos.x, y: buttonImportPicturePortraitPos.y, width: 50, height: 50)
        buttonImportPicture.imageView?.layer.cornerRadius = buttonImportPicture.frame.size.width / 2
        buttonImportPicture.layer.masksToBounds = false
        buttonImportPicture.clipsToBounds = true
        view.addSubview(buttonImportPicture)
        
        buttonCameraSwitchPortraitPos = CGPoint(x: view.frame.size.width - (view.frame.size.width * 0.14), y: view.frame.size.height - (view.frame.size.height * 0.085))
        buttonCameraSwitch.setImage(UIImage(named: "camera-switch"), for: UIControl.State.normal)
        buttonCameraSwitch.addTarget(self, action: #selector(switchCamera), for: UIControl.Event.touchUpInside)
        buttonCameraSwitch.frame = CGRect(x: buttonCameraSwitchPortraitPos.x, y: buttonCameraSwitchPortraitPos.y, width: 30, height: 22)
        view.addSubview(buttonCameraSwitch)

        let buttonCameraShot = UIButton(type: .custom)
        buttonCameraShot.setBackgroundImage(UIImage(named: "shot"), for: UIControl.State.normal)
        buttonCameraShot.setBackgroundImage(UIImage(named: "shot-hover"), for: UIControl.State.highlighted)
        buttonCameraShot.frame = CGRect(x: (view.frame.size.width / 2) - 37, y: view.frame.size.height - 100, width: 74, height: 74)
        buttonCameraShot.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        buttonCameraShot.layer.zPosition = 1
        view.addSubview(buttonCameraShot)
        
        flashEffectView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        flashEffectView.alpha = 0
        flashEffectView.backgroundColor = UIColor.white
        view.addSubview(flashEffectView)
        
        // Grid
        gridFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        gridView = GridView(frame: gridFrame)
        gridView.backgroundColor = .clear
        gridView.alpha = 0.7
        gridView.isUserInteractionEnabled = false
        gridView.isHidden = true
        view.addSubview(gridView)
        
        beginNewSession()
        addCoreMotion() // device orientation
        
        gestureRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinchRecognized))
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func setLibraryPic() {
        let manager = PHImageManager.default()
        let imageAsset = PHAsset.fetchAssets(with: .image, options: nil)
        var lastImg: UIImage?
        
        if imageAsset.count > 0 {
            manager.requestImage(for: imageAsset[imageAsset.count - 1], targetSize: CGSize(width: 20, height: 20), contentMode: .aspectFill, options: nil) { image, info in
                lastImg = image
            }
            buttonImportPicture.setImage(lastImg, for: UIControl.State.normal)
            
        } else {
            print("No image assets found.")
            buttonImportPicture.setImage(UIImage(named: "circle"), for: UIControl.State.normal)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let videoView = self.view
        let screenSize = videoView!.bounds.size
        if let touchPoint = touches.first {
            let x = touchPoint.location(in: videoView).y / screenSize.height
            let y = 1.0 - touchPoint.location(in: videoView).x / screenSize.width
            let focusPoint = CGPoint(x: x, y: y)
            if let device = captureDevice {
                if currentDirection == .back {
                    try? device.lockForConfiguration()
                    device.focusPointOfInterest = focusPoint
                    device.focusMode = .continuousAutoFocus
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .continuousAutoExposure
                    device.unlockForConfiguration()
                }
            }
        }
    }
    
    func beginNewSession() {
        if let input = try? AVCaptureDeviceInput(device: captureDevice!) {
            if captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.captureSession.addOutput(cameraOutput)
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                self.view.layer.addSublayer(previewLayer)
                previewLayer.frame = self.view.layer.frame
                previewLayer.zPosition = -1
                captureSession.startRunning()

                setLibraryPic()
            }
        } else {
            print("captureDevice error!")
        }
    }
    
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let deviceConverted = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
        
        return deviceConverted
    }
    
    @objc func switchFlash() {
        switch flashMode {
        case .on:
            flashMode = .off
            buttonFlashSwitch.setImage(UIImage(named: "flash-off"), for: UIControl.State.normal)
            print("flash off")
        case .off:
            flashMode = .auto
            buttonFlashSwitch.setImage(UIImage(named: "flash-auto"), for: UIControl.State.normal)
            print("flash auto")
        case .auto:
            flashMode = .on
            buttonFlashSwitch.setImage(UIImage(named: "flash-on"), for: UIControl.State.normal)
            print("flash on")
        default:
            flashMode = .off
            buttonFlashSwitch.setImage(UIImage(named: "flash-off"), for: UIControl.State.normal)
        }
    }
    
    @objc func switchGrid() {
        gridView.isHidden.toggle()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.buttonGridSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(self.gridView.isHidden ? 0 : 180))
        })
    }
    
    @objc func switchCamera() {
        captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
                captureSession.removeOutput(cameraOutput)
            }
        }
        
        if (currentDirection == .front) {
            captureDevice = getDevice(position: .back)
            currentDirection = .back
        } else {
            captureDevice = getDevice(position: .front)
            currentDirection = .front
        }
        
        beginNewSession()
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        settings.flashMode = flashMode
        settings.isAutoStillImageStabilizationEnabled = true
        settings.isHighResolutionPhotoEnabled = true

        self.cameraOutput.isHighResolutionCaptureEnabled = true
        self.cameraOutput.capturePhoto(with: settings, delegate: self)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [], animations: { () -> Void in
            self.flashEffectView.alpha = 1
        }, completion: {(finished: Bool) in
            self.flashEffectView.alpha = 0
        })
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData)?.withRenderingMode(.alwaysOriginal) else { return }
        
        let imageWithRightOrientation: UIImage = UIImage(cgImage: image.cgImage!, scale: 1, orientation: deviceOrientation)
                
        UIImageWriteToSavedPhotosAlbum(imageWithRightOrientation, self, #selector(imageSaved), nil)
        
        print("image captured.")
    }
    
    @objc func imageSaved(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer?) {
        self.setLibraryPic()
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        imageView.alpha = 0
        dismiss(animated: true, completion: pictureFadeInAnimation)
        let ImageWithNativeOrientation = importedImageNativeOrientation(img: image)
        imageView.image = ImageWithNativeOrientation
        imageView.backgroundColor = .black

        if !slider.isEnabled {
            slider.isEnabled = true
        }
    }
        
    func pictureFadeInAnimation() {
        UIView.animate(withDuration: 1, animations: {
            self.imageView.alpha = CGFloat(self.slider.value / 100)
        })
    }
    
    @objc func sliderValueChanged(sender: UISlider) {
        imageView.alpha = CGFloat(slider.value / 100)
    }
    
    func addCoreMotion() {
        let splitAngle: Double = 0.75
        let updateTimer: TimeInterval = 0.5

        motionManager = CMMotionManager()
        motionManager?.gyroUpdateInterval = updateTimer
        motionManager?.accelerometerUpdateInterval = updateTimer

        var orientationLast = UIInterfaceOrientation(rawValue: 0)!

        motionManager?.startAccelerometerUpdates(to: (OperationQueue.current)!, withHandler: {
            (acceleroMeterData, error) -> Void in
            if error == nil {
                let acceleration = (acceleroMeterData?.acceleration)!
                var orientationNew = UIInterfaceOrientation(rawValue: 0)!

                if acceleration.x >= splitAngle {
                    orientationNew = .landscapeLeft
                }

                else if acceleration.x <= -(splitAngle) {
                    orientationNew = .landscapeRight
                }

                else if acceleration.y <= -(splitAngle) {
                    orientationNew = .portrait
                }

                else if acceleration.y >= splitAngle {
                    orientationNew = .portraitUpsideDown
                }

                if orientationNew != orientationLast && orientationNew != .unknown{
                    orientationLast = orientationNew
                    self.deviceOrientationChanged(orientation: orientationNew)
                }
            }
            else {
                print("error: \(error!)")
            }
        })
    }
    
    func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }
    
    func deviceOrientationChanged(orientation: UIInterfaceOrientation) {
        if orientation.rawValue == 1 { //portrait
            deviceOrientation = .right
            
            UIView.animate(withDuration: 0.25, animations: {
                self.slider.frame.origin.x = self.view.frame.size.width - 225
                self.slider.transform = CGAffineTransform(rotationAngle: self.deg2rad(90))
                
                self.buttonFlashSwitch.frame.origin.x = self.buttonFlashSwitchPortraitPos.x
                self.buttonFlashSwitch.frame.origin.y = self.buttonFlashSwitchPortraitPos.y
                self.buttonFlashSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(0))
                
                self.buttonGridSwitch.frame.origin.x = self.buttonGridSwitchPortraitPos.x
                self.buttonGridSwitch.frame.origin.y = self.buttonGridSwitchPortraitPos.y
                
                self.buttonImportPicture.frame.origin.x = self.buttonImportPicturePortraitPos.x
                self.buttonImportPicture.frame.origin.y = self.buttonImportPicturePortraitPos.y
                self.buttonImportPicture.transform = CGAffineTransform(rotationAngle: self.deg2rad(0))
                
                self.buttonCameraSwitch.frame.origin.x = self.buttonCameraSwitchPortraitPos.x
                self.buttonCameraSwitch.frame.origin.y = self.buttonCameraSwitchPortraitPos.y
                self.buttonCameraSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(0))
            })
        }
        
        if orientation.rawValue == 2 { //upside down
            deviceOrientation = .left
            
            UIView.animate(withDuration: 0.25, animations: {
                self.buttonFlashSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(180))
                self.buttonImportPicture.transform = CGAffineTransform(rotationAngle: self.deg2rad(180))
                self.buttonCameraSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(180))
            })
        }
        
        if orientation.rawValue == 3 { //landscapeLeft
            deviceOrientation = .up
            
            UIView.animate(withDuration: 0.25, animations: {
                self.slider.frame.origin.x = -175
                self.slider.transform = CGAffineTransform(rotationAngle: self.deg2rad(90))
                
                self.buttonFlashSwitch.frame.origin.x = self.view.frame.size.width - 45
                self.buttonFlashSwitch.frame.origin.y = 30
                self.buttonFlashSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(90))
                
                self.buttonGridSwitch.frame.origin.x = self.view.frame.size.width - 40
                self.buttonGridSwitch.frame.origin.y = self.view.frame.size.height - 40
                self.buttonImportPicture.frame.origin.x = 10
                self.buttonImportPicture.frame.origin.y = 30
                self.buttonImportPicture.transform = CGAffineTransform(rotationAngle: self.deg2rad(90))
                
                self.buttonCameraSwitch.frame.origin.x = 15
                self.buttonCameraSwitch.frame.origin.y = self.view.frame.size.height - 45
                self.buttonCameraSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(90))
            })
        }
        
        if orientation.rawValue == 4 { //landscapeRight
            deviceOrientation = .down
            
            UIView.animate(withDuration: 0.25, animations: {
                self.slider.frame.origin.x = self.view.frame.size.width - 225
                self.slider.transform = CGAffineTransform(rotationAngle: self.deg2rad(-90))
                
                self.buttonFlashSwitch.frame.origin.x = 10
                self.buttonFlashSwitch.frame.origin.y = self.view.frame.size.height - 55
                self.buttonFlashSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(-90))
                
                self.buttonGridSwitch.frame.origin.x = 10
                self.buttonGridSwitch.frame.origin.y = 30
                
                self.buttonImportPicture.frame.origin.x = self.view.frame.size.width - 60
                self.buttonImportPicture.frame.origin.y = self.view.frame.size.height - 60
                self.buttonImportPicture.transform = CGAffineTransform(rotationAngle: self.deg2rad(-90))
                
                self.buttonCameraSwitch.frame.origin.x = self.view.frame.size.width - 40
                self.buttonCameraSwitch.frame.origin.y = 40
                self.buttonCameraSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(-90))
            })
        }
    }
    
    func importedImageNativeOrientation(img: UIImage) -> UIImage {
        //0 left 1 right 2 upside 3 up
        var image: UIImage
        
        if img.imageOrientation.rawValue == 0 { //landscapeLeft
            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .right)
            return image
        }
        
        if img.imageOrientation.rawValue == 1 { //landscapeRight
            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .right)
            return image
        }
        
        if img.imageOrientation.rawValue == 2 { //down
            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .left)
            return image
        }
        
        return img
    }
    
    @objc func pinchRecognized(pinch: UIPinchGestureRecognizer) {
        let device = captureDevice!
        let vZoomFactor = pinch.scale * prevZoomFactor
                
        if pinch.state == .ended {
            
            if vZoomFactor >= 1.0 {
                prevZoomFactor = vZoomFactor
            } else {
                prevZoomFactor = 1.0
            }
            
            if vZoomFactor > 16.0 {
                prevZoomFactor = 16.0
            }
        }
                
        do {
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()}
            
            if (vZoomFactor >= 1.0 && vZoomFactor <= device.activeFormat.videoMaxZoomFactor){
                device.videoZoomFactor = vZoomFactor
            } else {
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, vZoomFactor);
            }
            
            if vZoomFactor > 16.0 {
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, vZoomFactor);
            }
            
        } catch let error {
            NSLog("Unable to set videoZoom: %@", error.localizedDescription);
        }
    }
}
