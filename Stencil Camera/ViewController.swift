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
    var captureImageView: UIImageView!
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
        
        // transparent navigation bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear

        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
                
        slider = UISlider(frame: CGRect(origin: CGPoint(x: view.frame.size.width - 120, y: 50), size: CGSize(width: 200, height: 400)))
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .black
        slider.transform = CGAffineTransform(rotationAngle: .pi / 2)
        slider.maximumValue = 100
        slider.minimumValue = 0
        slider.value = 50
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.isEnabled = false
        view.addSubview(slider)
  
        //buttons
        buttonCameraSwitch.setImage(UIImage(named: "camera-switch"), for: UIControl.State.normal)
        buttonCameraSwitch.addTarget(self, action: #selector(switchCamera), for: UIControl.Event.touchUpInside)
        
        let barCameraBtn = UIBarButtonItem(customView: buttonCameraSwitch)
        let barCameraBtnWidth = barCameraBtn.customView?.widthAnchor.constraint(equalToConstant: 34)
        barCameraBtnWidth?.isActive = true
        let barCameraBtnHeight = barCameraBtn.customView?.heightAnchor.constraint(equalToConstant: 24)
        barCameraBtnHeight?.isActive = true

        buttonFlashSwitch.setImage(UIImage(named: "flash-off"), for: UIControl.State.normal)
        buttonFlashSwitch.addTarget(self, action: #selector(switchFlash), for: UIControl.Event.touchUpInside)
        buttonFlashSwitch.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let barFlashBtn = UIBarButtonItem(customView: buttonFlashSwitch)
        let barFlashBtnWidth = barFlashBtn.customView?.widthAnchor.constraint(equalToConstant: 36)
        barFlashBtnWidth?.isActive = true
        let barFlashBtnHeight = barFlashBtn.customView?.heightAnchor.constraint(equalToConstant: 28)
        barFlashBtnHeight?.isActive = true
        
        buttonImportPicture.setImage(UIImage(named: "folder"), for: UIControl.State.normal)
        buttonImportPicture.addTarget(self, action: #selector(importPicture), for: UIControl.Event.touchUpInside)
        buttonImportPicture.frame = CGRect(x: 10, y: view.frame.size.height - 55, width: 45, height: 45)
        buttonImportPicture.imageView?.layer.cornerRadius = 5
        view.addSubview(buttonImportPicture)
        //buttonImportPicture.imageView?.contentMode = .redraw
    
        //buttonImportPicture.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
       
        // let spacer: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        //  spacer.width = 0
        
        navigationItem.leftBarButtonItems = [barCameraBtn, barFlashBtn]
        
        let buttonCameraShot = UIButton(type: .custom)
        buttonCameraShot.setImage(UIImage(named: "shot"), for: UIControl.State.normal)
        buttonCameraShot.setImage(UIImage(named: "shot-hover"), for: UIControl.State.highlighted)
        buttonCameraShot.frame.size.width = 74
        buttonCameraShot.frame.size.height = 74
        buttonCameraShot.contentHorizontalAlignment = .fill
        buttonCameraShot.contentVerticalAlignment = .fill
        buttonCameraShot.imageView?.contentMode = .scaleAspectFit
        buttonCameraShot.translatesAutoresizingMaskIntoConstraints = false
        buttonCameraShot.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        //buttonCameraShot.layer.borderWidth = 1
        //buttonCameraShot.layer.borderColor = UIColor.lightGray.cgColor
        buttonCameraShot.layer.zPosition = 1
        //buttonCameraShot.layer.cornerRadius = 50
        view.addSubview(buttonCameraShot)
        
        flashEffectView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.size.width, height: view.frame.size.height)))
        flashEffectView.alpha = 0
        flashEffectView.backgroundColor = UIColor.white
        view.addSubview(flashEffectView)
    
        NSLayoutConstraint.activate([
            buttonCameraShot.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20),
            buttonCameraShot.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            //buttonCameraShot.heightAnchor.constraint(equalToConstant: 100),
            //buttonCameraShot.widthAnchor.constraint(equalToConstant: 100),
            
//            buttonImportPicture.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: 20),
//            buttonImportPicture.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
//            buttonImportPicture.heightAnchor.constraint(equalToConstant: 45),
//            buttonImportPicture.widthAnchor.constraint(equalToConstant: 45)
        ])
        
        //var image: UIImageAsset!
       // getAssetThumbnail(asset: image)
        
//        let mostRecentMedia = PHFetchOptions()
//               mostRecentMedia.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
//               let allPhotos: PHFetchResult = PHAsset.fetchAssets(with: mostRecentMedia)
        
        //getAssetThumbnail(allPhotos: allPhotos)
        
        beginNewSession()
        addCoreMotion() // device orientation
    }
    
    func setLibraryPic() {
        let manager = PHImageManager.default()
        let imageAsset = PHAsset.fetchAssets(with: .image, options: nil)
        var lastImg: UIImage?
        //print(imageAsset)
      
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
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
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
        
        //print(image)
        
        //image = fixOrientation(img: image)
        
        //var newImage = image.fixOrientation()
        var imageWithRightOrientation: UIImage = UIImage(cgImage: image.cgImage!, scale: 1, orientation: deviceOrientation)
        
        //print(newImage)
        
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
        imageView.image = image
        imageView.backgroundColor = .black
        
        //print("1 \(imageView.frame.size)")
        //print("2 \(imageView)")
        
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
    
    
    
    
    
//    func getAssetThumbnail( ) {
//
//
//
//        let asset = allPhotos.object(at: 0)
//        let size = CGSize(width: 80, height: 80)
//
//        PHCachingImageManager().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
//            // Ensure we're dealing with the same cell when the asset returns
//            // In case its since been recycled
//            print(image)
////            if cell.localAssetID == asset.localIdentifier
////            {
////                cell.theImageViewImage = image
////            }
//        })
//
//
//        //print(image)
//        //return image
//      //  let image = asset.image
//
//
//    }
    
    
    
    
    
        
//    func getLatestPhotos(completion completionBlock : (([UIImage]) -> ()))   {
//        let library = ALAssetsLibrary()
//        var count = 0
//        var images : [UIImage] = []
//        var stopped = false
//
//        library.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos, usingBlock: { (group, stop) -> Void in
//
//            group?.setAssetsFilter(ALAssetsFilter.allPhotos())
//
//            group?.enumerateAssets(options: NSEnumerationOptions.reverse, using: {
//                (asset : ALAsset!, index, stopEnumeration) -> Void in
//
//                if (!stopped)
//                {
//                    if count >= 3
//                    {
//
//                        stopEnumeration.memory = ObjCBool(true)
//                        stop.memory = ObjCBool(true)
//                        completionBlock(images)
//                        stopped = true
//                    }
//                    else
//                    {
//                        // For just the thumbnails use the following line.
//                        let cgImage = asset.thumbnail().takeUnretainedValue()
//
//                        if let image = UIImage(cgImage: cgImage) {
//                            images.append(image)
//                            count += 1
//                        }
//                    }
//                }
//
//            })
//
//            },failureBlock : { error in
//                print(error)
//        })
//    }
    
    func deviceOrientationChanged(orientation:UIInterfaceOrientation) {
        //print("orientation:",orientation.rawValue)
//        print(orientation)
        if orientation.rawValue == 1 { //portrait
            deviceOrientation = .right
         //   print(deviceOrientation)
            //imageView.
            //imageView.transform = CGAffineTransform(rotationAngle: 0)
            //buttonCameraShot.transform = CGAffineTransform(rotationAngle: 0)
        }
        if orientation.rawValue == 2 { //upside down
           deviceOrientation = .left
           //print(deviceOrientation)
           //imageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
           //buttonCameraShot.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
       }
        if orientation.rawValue == 3 { //landscapeLeft
            deviceOrientation = .up
          //           print(deviceOrientation)
            //imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
            //buttonCameraShot.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        }
        if orientation.rawValue == 4 { //landscapeRight
            deviceOrientation = .down
            //print(deviceOrientation)
            //imageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            //buttonCameraShot.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
    }
}
