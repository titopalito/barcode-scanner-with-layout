//
//  ViewController.swift
//  Camera
//
//  Created by Rizwan on 16/06/17.
//  Copyright © 2017 Rizwan. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var middleButtonBarderView: UIView!
    @IBOutlet weak var outerButtonBarderView: UIView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: ScannerOverlayPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var qrCodeFrameView: UIView?
    var barCodeFrameView: UIView?

//    override var shouldAutorotate: Bool {
//        return false
//    }
    //    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    //        return .landscapeRight
    //    }
    
    //pilas kevin
    private var _orientations = UIInterfaceOrientationMask.portrait
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get { return self._orientations }
        set { self._orientations = newValue }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        supportedInterfaceOrientations = .landscapeRight
        UIView.setAnimationsEnabled(false)
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIView.setAnimationsEnabled(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureButton()
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            fatalError("No video device found")
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous deivce object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object
            captureSession = AVCaptureSession()
            
            // Set the input devcie on the capture session
            captureSession?.addInput(input)
            
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            // Set the output on the capture session
            captureSession?.addOutput(capturePhotoOutput!)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the input device
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)

            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
            
            videoPreviewLayer = ScannerOverlayPreviewLayer(session: captureSession!)
            videoPreviewLayer?.frame = previewView.bounds
            videoPreviewLayer?.maskSize = CGSize(width: 280, height: 150)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            previewView.layer.addSublayer(videoPreviewLayer!)
            captureMetadataOutput.rectOfInterest = videoPreviewLayer!.rectOfInterest
            
            
            
            //Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
//            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
//            videoPreviewLayer?.videoGravity = .resizeAspectFill
//            videoPreviewLayer?.frame = view.layer.bounds
//            previewView.layer.addSublayer(videoPreviewLayer!)
            
            //start video capture
            captureSession?.startRunning()
            
            messageLabel.isHidden = true
            
            //Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            barCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
            if let qrCodeFrameView = barCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.red.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        } catch {
            //If any error occurs, simply print it out
            print(error)
            return
        }
    
    }
    
    func setupCaptureButton() {
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.clipsToBounds = true
        captureButton.setBackgroundColor(color: .black, forState: .highlighted)
        captureButton.setTitle("", for: .normal)
        
        middleButtonBarderView.layer.cornerRadius = middleButtonBarderView.frame.size.width / 2
        outerButtonBarderView.layer.cornerRadius = outerButtonBarderView.frame.size.width / 2
    }

    override func viewDidLayoutSubviews() {
        videoPreviewLayer?.frame = view.bounds
        if let previewLayer = videoPreviewLayer ,(previewLayer.connection?.isVideoOrientationSupported)! {
            previewLayer.connection?.videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation ?? .portrait
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onTapTakePhoto(_ sender: Any) {
        // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        
        // Get an instance of AVCapturePhotoSettings class
        let photoSettings = AVCapturePhotoSettings()
        
        // Set photo settings for our need
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        // Call capturePhoto method by passing our photo settings and a delegate implementing AVCapturePhotoCaptureDelegate
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        
        //pilas kevin
        supportedInterfaceOrientations = .portrait
        UIView.setAnimationsEnabled(false)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIView.setAnimationsEnabled(true)
    }
}

extension ViewController : AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer")
            return
        }

        guard let capturedImage = UIImage.init(data: imageData , scale: 1.0) else {
            print("Fail to convert image data to UIImage")
            return
        }

        let width = capturedImage.size.width
        let height = capturedImage.size.height
        let origin = CGPoint(x: (width - height)/2, y: (height - height)/2)
        let size = CGSize(width: height, height: height)

        guard let imageRef = capturedImage.cgImage?.cropping(to: CGRect(origin: origin, size: size)) else {
            print("Fail to crop image")
            return
        }

        let imageToSave = UIImage(cgImage: imageRef, scale: 1.0, orientation: .down)
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
    }
}

extension ViewController : AVCaptureMetadataOutputObjectsDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {

    }
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            barCodeFrameView?.frame = CGRect.zero
            messageLabel.isHidden = true
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.isHidden = false
                messageLabel.text = metadataObj.stringValue
            }
        }
        
        if metadataObj.type == AVMetadataObject.ObjectType.ean8 ||
        metadataObj.type == AVMetadataObject.ObjectType.ean13 ||  metadataObj.type == AVMetadataObject.ObjectType.pdf417 {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            barCodeFrameView?.frame = CGRect(x: barCodeObject!.bounds.minX, y: barCodeObject!.bounds.minY, width: barCodeObject!.bounds.width, height: CGFloat(4))
            barCodeFrameView?.alpha = 0.7
            barCodeFrameView?.layer.cornerRadius = 2
            if metadataObj.stringValue != nil {
                messageLabel.isHidden = false
                messageLabel.text = metadataObj.stringValue
            }
            
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        return .landscapeRight
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }
}
