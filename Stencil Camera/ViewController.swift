//
//  ViewController.swift
//  Stencil Camera
//
//  Created by Mike on 2019-08-28.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
//import AssetsLibrary
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var captureSession = AVCaptureSession()
    let cameraOutput = AVCapturePhotoOutput()
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
    var motionManager: CMMotionManager!
    var flashMode: AVCaptureDevice.FlashMode! = .off
    let buttonFlashSwitch: UIButton = UIButton(type: UIButton.ButtonType.custom)
    let buttonCameraSwitch: UIButton = UIButton(type: UIButton.ButtonType.custom)
    let buttonImportPicture: UIButton = UIButton(type: UIButton.ButtonType.custom)

    override func viewDidLoad() {
        super.viewDidLoad()
            
        captureDevice = getDevice(position: .back)
        deviceOrientation = .right

        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
                
        slider = UISlider(frame: CGRect(origin: CGPoint(x: view.frame.size.width - 125, y: (UIScreen.main.bounds.size.height * 0.5) - 200), size: CGSize(width: 200, height: 400)))
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
        buttonFlashSwitch.setImage(UIImage(named: "flash-off"), for: UIControl.State.normal)
        buttonFlashSwitch.addTarget(self, action: #selector(switchFlash), for: UIControl.Event.touchUpInside)
        buttonFlashSwitch.frame = CGRect(x: 10, y: 30, width: 30, height: 40)
        buttonFlashSwitch.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        view.addSubview(buttonFlashSwitch)
        
        buttonImportPicture.setImage(UIImage(named: "folder"), for: UIControl.State.normal)
        buttonImportPicture.addTarget(self, action: #selector(importPicture), for: UIControl.Event.touchUpInside)
        buttonImportPicture.frame = CGRect(x: 10, y: view.frame.size.height - 60, width: 50, height: 50)
        buttonImportPicture.imageView?.layer.cornerRadius = 5
        view.addSubview(buttonImportPicture)
        
        buttonCameraSwitch.setImage(UIImage(named: "camera-switch"), for: UIControl.State.normal)
        buttonCameraSwitch.addTarget(self, action: #selector(switchCamera), for: UIControl.Event.touchUpInside)
        buttonCameraSwitch.frame = CGRect(x: view.frame.size.width - 40, y: view.frame.size.height - 40, width: 30, height: 22)
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
                
        beginNewSession()
        addCoreMotion() // device orientation
    }
    
    func setLibraryPic() {
        let manager = PHImageManager.default()
        let imageAsset = PHAsset.fetchAssets(with: .image, options: nil)
        var lastImg: UIImage?
      
        manager.requestImage(for: imageAsset[imageAsset.count - 1], targetSize: CGSize(width: 20, height: 20), contentMode: .aspectFill, options: nil) { image, info in
            lastImg = image
        }
        
        buttonImportPicture.setImage(lastImg, for: UIControl.State.normal)
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
        let devices = AVCaptureDevice.devices();
        
        for device in devices {
            let deviceConverted = device as! AVCaptureDevice
            
            if (deviceConverted.position == position){
                return deviceConverted
            }
        }
        return nil
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
        
    @objc func switchFlash() {
        print(11)
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
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: {
            self.setLibraryPic()
        })
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard var image = UIImage(data: imageData)?.withRenderingMode(.alwaysOriginal) else { return }
        
        var imageWithRightOrientation: UIImage = UIImage(cgImage: image.cgImage!, scale: 1, orientation: deviceOrientation)
                
        UIImageWriteToSavedPhotosAlbum(imageWithRightOrientation, self, nil, nil)
        
        print("image captured.")
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
        print(imageView.image!.imageOrientation.rawValue)
        print(imageView.image!.imageOrientation.hash)
        
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
                print("error : \(error!)")
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
                
                self.buttonFlashSwitch.frame.origin.x = 10
                self.buttonFlashSwitch.frame.origin.y = 30
                self.buttonFlashSwitch.transform = CGAffineTransform(rotationAngle: self.deg2rad(0))
                
                self.buttonImportPicture.frame.origin.x = 10
                self.buttonImportPicture.frame.origin.y = self.view.frame.size.height - 60
                self.buttonImportPicture.transform = CGAffineTransform(rotationAngle: self.deg2rad(0))
                
                self.buttonCameraSwitch.frame.origin.x = self.view.frame.size.width - 40
                self.buttonCameraSwitch.frame.origin.y = self.view.frame.size.height - 40
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
   
}
