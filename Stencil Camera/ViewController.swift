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

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var captureSession = AVCaptureSession()
    let cameraOutput = AVCapturePhotoOutput()
    var captureImageView: UIImageView!
    var captureDevice: AVCaptureDevice?
    enum CameraDirection {
        case front
        case back
    }
    var currentDirection: CameraDirection = .back
    var flashEffectView = UIView()
    var imageView: UIImageView!
    var currentImage: UIImage!
    var currentFilter: CIFilter!
    var slider: UISlider!
    var motionManager: CMMotionManager!
    
    //buttons
    let buttonCameraShot = UIButton(type: .system)
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureDevice = getDevice(position: .back)
        
//        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: (view.center.y / 2) - 15), size: CGSize(width: view.frame.size.width, height: view.frame.size.width)))
        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        //flashEffectView.alpha = 1
        //flashEffectView.backgroundColor = UIColor.red
        //flashEffectView.layer.zPosition = 0
        view.addSubview(imageView)
        
        currentFilter = CIFilter(name: "CISepiaTone")
        
        slider = UISlider(frame: CGRect(origin: CGPoint(x: view.frame.size.width - 120, y: 50), size: CGSize(width: 200, height: 400)))
        slider.transform = CGAffineTransform(rotationAngle: .pi / 2)
        slider.maximumValue = 100
        slider.minimumValue = 0
        slider.value = 50
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        view.addSubview(slider)
        
        let buttonCameraSwitch = UIButton(type: .system)
        buttonCameraSwitch.translatesAutoresizingMaskIntoConstraints = false
        buttonCameraSwitch.setTitle("switch", for: .normal)
        buttonCameraSwitch.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        buttonCameraSwitch.layer.borderWidth = 1
        buttonCameraSwitch.layer.borderColor = UIColor.lightGray.cgColor
        buttonCameraSwitch.layer.zPosition = 1
        view.addSubview(buttonCameraSwitch)
        
        buttonCameraShot.translatesAutoresizingMaskIntoConstraints = false
        buttonCameraShot.setTitle("shot", for: .normal)
        buttonCameraShot.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        buttonCameraShot.layer.borderWidth = 1
        buttonCameraShot.layer.borderColor = UIColor.lightGray.cgColor
        buttonCameraShot.layer.zPosition = 1
        buttonCameraShot.layer.cornerRadius = 50
        view.addSubview(buttonCameraShot)
        
        let buttonImportPicture = UIButton(type: .system)
        buttonImportPicture.translatesAutoresizingMaskIntoConstraints = false
        buttonImportPicture.setTitle("Add Layer", for: .normal)
        buttonImportPicture.addTarget(self, action: #selector(importPicture), for: .touchUpInside)
        buttonImportPicture.layer.borderWidth = 1
        buttonImportPicture.layer.borderColor = UIColor.lightGray.cgColor
        buttonImportPicture.layer.zPosition = 1
        view.addSubview(buttonImportPicture)
        
        flashEffectView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        flashEffectView.alpha = 0
        flashEffectView.backgroundColor = UIColor.white
        view.addSubview(flashEffectView)
    
        NSLayoutConstraint.activate([
            buttonImportPicture.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            buttonImportPicture.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 100),
            buttonImportPicture.heightAnchor.constraint(equalToConstant: 44),
            
            slider.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            //slider.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 100),
            //slider.heightAnchor.constraint(equalToConstant: 44),
            
            buttonCameraSwitch.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            buttonCameraSwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -100),
            buttonCameraSwitch.heightAnchor.constraint(equalToConstant: 44),
            
            buttonCameraShot.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20),
            buttonCameraShot.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            buttonCameraShot.heightAnchor.constraint(equalToConstant: 100),
            buttonCameraShot.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        beginNewSession()
        addCoreMotion() // device orientation
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
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                }
            }
        }
    }
    
    func beginNewSession() {
        if let input = try? AVCaptureDeviceInput(device: captureDevice!) {
            if captureSession.canAddInput(input) {
                print("Can!")
                self.captureSession.addInput(input)
                self.captureSession.addOutput(cameraOutput)
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                self.view.layer.addSublayer(previewLayer)
                previewLayer.frame = self.view.layer.frame
                previewLayer.zPosition = -1
                captureSession.startRunning()
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
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
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
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        
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
        imageView.image = image
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
    
    func deviceOrientationChanged(orientation:UIInterfaceOrientation) {
        print("orientation:",orientation.rawValue)
        print(orientation)
        if orientation.rawValue == 1 { //portrait
            //imageView.transform = CGAffineTransform(rotationAngle: 0)
            buttonCameraShot.transform = CGAffineTransform(rotationAngle: 0)
        }
        if orientation.rawValue == 3 { //landscapeLeft
            //imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
            buttonCameraShot.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        }
        if orientation.rawValue == 4 { //landscapeRight
            //imageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            buttonCameraShot.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
    }
}
