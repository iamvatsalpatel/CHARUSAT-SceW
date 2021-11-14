//
//  ViewController.swift
//  SceW
//
//  Created by Vatsal Patel on 20/02/20.
//  Copyright © 2020 Vatsal Patel. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import VisionKit


extension UIImage
{
    func detectOrientationDegree () -> CGFloat
    {
        switch imageOrientation
        {
            case .right, .rightMirrored:    return 90
            case .left, .leftMirrored:      return -90
            case .up, .upMirrored:          return 180
            case .down, .downMirrored:      return 0
            @unknown default:
            return 0
        }
    }
}


class ViewController: UIViewController
{
    
    // MARK: - OUTLETS
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var zoomSlider: UISlider!
    var label : String = ""
    let ExModel = ExtractionModel()
    var abc : String = "YO"
    
    @IBOutlet weak var newl: UILabel!
    
    @IBOutlet weak var GO: UIButton!
    
    override func viewWillAppear(_ animated: Bool)
    {
        GO.isHidden = true
    }
    
    
    // MARK: - Private Properties
    fileprivate var stillImageOutput: AVCaptureStillImageOutput!
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let device  = AVCaptureDevice.default(for: AVMediaType.video)
    fileprivate var textRecognitionRequest = VNRecognizeTextRequest()
    
    
    
    
    // MARK: - View LifeCycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // start camera init
        DispatchQueue.main.async
        {
            if self.device != nil
            {
                self.configureCameraForUse()
            }
            
            self.textRecognitionRequest = VNRecognizeTextRequest(completionHandler:
            {
                (request, error) in
                if let results = request.results, !results.isEmpty
                {
                    if let requestResults = request.results as? [VNRecognizedTextObservation]
                    {
                        DispatchQueue.main.async
                            {
                                // Create a full transcript to run analysis on.
                                var transcript = ""
                                
                                let maximumCandidates = 1
                                for observation in requestResults
                                {
                                    guard let candidate = observation.topCandidates(maximumCandidates).first else
                                    {
                                        continue
                                    }
                                    transcript += candidate.string
                                    transcript += "\n"
                                }
                                self.label = transcript
                                self.newl.text = transcript
                                updateLabel(xyz: self.label)
                        }
                    }
                }
            })
            
            // This doesn't require OCR on a live camera feed, select accurate for more accurate results.
            self.textRecognitionRequest.recognitionLevel = .accurate
            self.textRecognitionRequest.usesLanguageCorrection = true
           
            func updateLabel(xyz : String)
                {
                    self.abc=xyz
                    print(self.abc)
                    self.new(new1 : self.abc)
                }
        }
    }
    
    let VVC = VideoViewController()
    var newz : String?
    func new(new1 : String)
    {
        newz = new1
        print("This is out of func ")
        print(newz!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let VideoVC = segue.destination as! VideoViewController
        
        if let text = newz
        {
            VideoVC.a=text
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func takePhotoButtonPressed (_ sender: UIButton)
    {
        GO.isHidden = false
        
        DispatchQueue.main.async
            {
                guard let capturedType = self.stillImageOutput.connection(with: AVMediaType.video)
                else
                {
                    return
                }
                
                self.stillImageOutput.captureStillImageAsynchronously(from: capturedType)
                {
                    [weak self] optionalBuffer, error -> Void in
                    guard let buffer = optionalBuffer else
                    {
                        return
                    }
                    
                    guard let weakSelf = self else
                    {
                        return
                    }
                
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    let image = UIImage(data: imageData!)
                    
                    let croppedImage = weakSelf.prepareImageForCrop(using: image!)
                        
                    guard let cgImage = croppedImage.cgImage
                        else
                    {
                        print("Failed to get cgimage from input image")
                        return
                    }
                        
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    do
                    {
                        try handler.perform([weakSelf.textRecognitionRequest])
                    }
                    catch
                    {
                        print(error)
                    }
                    
                }
            }
        
    }
        
        @IBAction func sliderValueDidChange(_ sender: UISlider)
        {
            do
            {
                try device!.lockForConfiguration()
                var zoomScale = CGFloat(zoomSlider.value * 10.0)
                let zoomFactor = device?.activeFormat.videoMaxZoomFactor

                if zoomScale < 1
                {
                    zoomScale = 1
                }
                else if zoomScale > zoomFactor!
                {
                    zoomScale = zoomFactor!
                }

                device?.videoZoomFactor = zoomScale
                device?.unlockForConfiguration()
            }
            catch
            {
                print("captureDevice?.lockForConfiguration() denied")
            }
        }
    
    
}
    


extension ViewController {
    // MARK: AVFoundation
    fileprivate func configureCameraForUse ()
    {
        self.stillImageOutput = AVCaptureStillImageOutput()
        let fullResolution = UIDevice.current.userInterfaceIdiom == .phone && max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 568.0
        
        if fullResolution
        {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        }
        else
        {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        DispatchQueue.main.async
        {
            self.prepareCaptureSession()
        }
    }
    
    private func prepareCaptureSession () {
        do
        {
            self.captureSession.addInput(try AVCaptureDeviceInput(device: self.device!))
        }
        catch
        {
            print("AVCaptureDeviceInput Error")
        }
        
        // layer customization
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.frame.size = self.cameraView.frame.size
        previewLayer.frame.origin = CGPoint.zero
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // device lock is important to grab data correctly from image
        do
        {
            try self.device?.lockForConfiguration()
            self.device?.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            self.device?.focusMode = .continuousAutoFocus
            self.device?.unlockForConfiguration()
        }
        catch
        {
            print("captureDevice?.lockForConfiguration() denied")
        }
        
        //Set initial Zoom scale
        do
        {
            try self.device?.lockForConfiguration()
            
            let zoomScale: CGFloat = 2.5
            
            if zoomScale <= (device?.activeFormat.videoMaxZoomFactor)! {
                device?.videoZoomFactor = zoomScale
            }
            
            device?.unlockForConfiguration()
        }
        catch
        {
            print("captureDevice?.lockForConfiguration() denied")
        }
        
        DispatchQueue.main.async(execute: {
            self.cameraView.layer.addSublayer(previewLayer)
            self.captureSession.startRunning()
        })
    }
    
    // MARK: Image Processing
    fileprivate func prepareImageForCrop (using image: UIImage) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(Double.pi)
        }
        
        let imageOrientation = image.imageOrientation
        let degree = image.detectOrientationDegree()
        let cropSize = CGSize(width: 400, height: 110)
        
        //Downscale
        let cgImage = image.cgImage!
        
        let width = cropSize.width
        let height = image.size.height / image.size.width * cropSize.width
        
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        
        let context = CGContext(data: nil,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace!,
                                bitmapInfo: bitmapInfo.rawValue)
        
        context!.interpolationQuality = CGInterpolationQuality.none
        // Rotate the image context
        context?.rotate(by: degreesToRadians(degree));
        // Now, draw the rotated/scaled image into the context
        context?.scaleBy(x: -1.0, y: -1.0)
        
        //Crop
        switch imageOrientation {
        case .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: -height, y: 0, width: height, height: width))
        case .left, .leftMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: -width, width: height, height: width))
        case .up, .upMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        case .down, .downMirrored:
            context?.draw(cgImage, in: CGRect(x: -width, y: -height, width: width, height: height))
        @unknown default:
            debugPrint("some error occured")
        }
        
        let calculatedFrame = CGRect(x: 0, y: CGFloat((height - cropSize.height)/2.0), width: cropSize.width, height: cropSize.height)
        let scaledCGImage = context?.makeImage()?.cropping(to: calculatedFrame)
        
        
        return UIImage(cgImage: scaledCGImage!)
    }
    
}
