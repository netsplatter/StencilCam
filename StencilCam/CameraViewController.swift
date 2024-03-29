//
//  CameraViewController.swift
//  StencilCam
//
//  Created by Mike on 1/11/23.
//

import SwiftUI
import UIKit
import AVFoundation
import CoreMotion
import Photos

class CameraViewController: UIViewController, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate, ObservableObject {
    var captureDevice: AVCaptureDevice?
    let captureSession = AVCaptureSession()
    let cameraOutput = AVCapturePhotoOutput()
    let picker = UIImagePickerController()

    var motionManager: CMMotionManager!
    @Published var deviceOrientation: AVCaptureVideoOrientation = .portrait
    
    var flashMode: AVCaptureDevice.FlashMode! = .off
    @Published var flashEffect = false
    @Published var libraryPic: UIImage = UIImage(named: "folder")!
    @Published var imageOverlay: UIImage = UIImage()
    @Published var showOverlay: Bool = false
    
    var photoAlbum: PhotoAlbum!
    
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOutput
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureDevice = getDevice(position: .back)
        beginNewSession()
        
        addCoreMotion() // device orientation
        
        photoAlbum = PhotoAlbum()
        photoAlbum.checkAuthorizationWithHandler(completion: {_ in }) // checking permissions and the album in Photos
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        captureSession.stopRunning()
        motionManager = nil
    }
    
    func beginNewSession() {
        if let input = try? AVCaptureDeviceInput(device: captureDevice!) {
            if captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.captureSession.addOutput(cameraOutput)
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = UIScreen.main.bounds
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.zPosition = -1
                //previewLayer?.connection?.videoOrientation = deviceOrientation
                self.view.layer.addSublayer(previewLayer)
                
                DispatchQueue.main.async {
                    self.libraryPic = self.setLibraryPic()
                }
                
                DispatchQueue.global().async {
                    self.captureSession.startRunning()
                }
            }
        } else {
            print("captureDevice error!")
        }
    }
        
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        settings.flashMode = flashMode
        //settings.photoQualityPrioritization = .quality

        cameraOutput.capturePhoto(with: settings, delegate: self)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [], animations: { () -> Void in
            self.flashEffect = true
        }, completion: {(finished: Bool) in
            self.flashEffect = false
        })
    }
    
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceConverted = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
        return deviceConverted
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData)?.withRenderingMode(.alwaysOriginal) else { return }
        //guard let deviceOrientation = deviceOrientation else { return }
        
        let imageWithOrientation: UIImage = UIImage(cgImage: image.cgImage!, scale: 1, orientation: deviceToImageOrientation(deviceOrientation))
                
        photoAlbum.save(image: imageWithOrientation) { success in
            guard success else { return }
            DispatchQueue.main.async {
                self.libraryPic = self.setLibraryPic()
            }
        }
        print("image captured.")
    }
    
    @objc func imageSaved(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer?) {
        libraryPic = setLibraryPic()
    }
    
    @objc func setLibraryPic() -> UIImage {
        let manager = PHImageManager.default()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let imageAsset = PHAsset.fetchAssets(with: .image, options: options)
        var lastImg: UIImage?
        
        if imageAsset.count > 0 {
            manager.requestImage(for: imageAsset.lastObject!, targetSize: CGSize(width: 20, height: 20), contentMode: .aspectFill, options: nil) { image, info in
                lastImg = image
            }
        } else {
            print("No image assets found.")
        }
        
        return lastImg != nil ? lastImg! : UIImage(named: "folder")!
    }
    
    func deviceToImageOrientation(_ deviceOrientation: AVCaptureVideoOrientation) -> UIImage.Orientation {
        let orientation: UIImage.Orientation
        
        switch deviceOrientation {
        case .portrait: orientation = .right
        case .portraitUpsideDown: orientation = .left
        case .landscapeLeft: orientation = .down
        case .landscapeRight: orientation = .up
        default: orientation = .down
        }
        
        return orientation
    }
    
    func imageFadeInAnimation() {
        UIView.animate(withDuration: 1, animations: {
     //       self.imageView.alpha = CGFloat(self.slider.value / 100)
        })
    }
}

// Device Orientation
extension CameraViewController {
    func addCoreMotion() {
        let splitAngle: Double = 0.75
        let updateTimer: TimeInterval = 0.5
        var lastOrientation = UIInterfaceOrientation(rawValue: 0)!
        
        motionManager = CMMotionManager()
        motionManager.gyroUpdateInterval = updateTimer
        motionManager.accelerometerUpdateInterval = updateTimer
        
        motionManager.startAccelerometerUpdates(to: (OperationQueue.current)!, withHandler: {
            (acceleroMeterData, error) -> Void in
            if error == nil {
                let acceleration = (acceleroMeterData?.acceleration)!
                var newOrientation = UIInterfaceOrientation(rawValue: 0)!

                if acceleration.x >= splitAngle {
                    newOrientation = .landscapeLeft
                }

                else if acceleration.x <= -(splitAngle) {
                    newOrientation = .landscapeRight
                }

                else if acceleration.y <= -(splitAngle) {
                    newOrientation = .portrait
                }

                else if acceleration.y >= splitAngle {
                    newOrientation = .portraitUpsideDown
                }

                if newOrientation != lastOrientation && newOrientation != .unknown {
                    lastOrientation = newOrientation
                    self.deviceOrientationChanged(orientation: newOrientation)
                }
            }
            else {
                print("error: \(error!)")
            }
        })
    }
    
    func deviceOrientationChanged(orientation: UIInterfaceOrientation) {
        if orientation.rawValue == 1 {
            deviceOrientation = .portrait
        }

        if orientation.rawValue == 2 {
            deviceOrientation = .portraitUpsideDown
        }

        if orientation.rawValue == 3 {
            deviceOrientation = .landscapeRight
        }

        if orientation.rawValue == 4 {
            deviceOrientation = .landscapeLeft
        }
    }
    
    func importedImageNativeOrientation(img: UIImage) -> UIImage {
        //0 left 1 right 2 upside 3 up
        var image: UIImage
        
        if img.imageOrientation == .down { //landscapeLeft
            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .right)
            return image
        }
        
        if img.imageOrientation == .up { //landscapeRight
            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .right)
            return image
        }
        
//        if img.imageOrientation == .right { //portrait
//            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .right)
//            return image
//        }
        
//        if img.imageOrientation == .left { //portraitUpsideDown
//            image = UIImage(cgImage: img.cgImage!, scale: 1, orientation: .left)
//            return image
//        }
        
        return img
    }
}

// Image Picker
extension CameraViewController: UIImagePickerControllerDelegate {
    func importImage() {
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = ["public.image"]
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        //imageOverlay.alpha = 0
        dismiss(animated: true, completion: imageFadeInAnimation)
        let ImageWithNativeOrientation = importedImageNativeOrientation(img: image)
        imageOverlay = ImageWithNativeOrientation
        //imageView.backgroundColor = .black

        showOverlay = true
    }
}
