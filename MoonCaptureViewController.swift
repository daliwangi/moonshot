//
//  MoonCaptureViewController.swift
//  MoonCaptureApp
//
//  Created by Lucas Cane on 2023-04-01.
//

import UIKit
import AVFoundation
import CoreImage
import CoreGraphics

// Add this import statement
import OpenCVWrapper

class MoonCaptureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var instructionLabel: UILabel!
    
    weak var viewModel: MoonCaptureViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInstructionLabel()
        setupCaptureSession()
    }
    
    private func setupInstructionLabel() {
        instructionLabel = UILabel()
        instructionLabel.text = "将镜头对准月亮"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        NSLayoutConstraint.activate([
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        // Configure camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("No back camera found.")
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                fatalError("Unable to add camera input.")
            }
        } catch {
            fatalError("Error configuring camera input: \(error)")
        }
        
        // Configure camera output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraOutputQueue"))
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            fatalError("Unable to add camera output.")
        }
        
        // Enable continuous autofocus
        do {
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            camera.unlockForConfiguration()
        } catch {
            fatalError("Error configuring camera focus: \(error)")
        }
        
        // Set up preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Start capture session
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }

    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)

            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return
            }

            let capturedImage = UIImage(cgImage: cgImage)
            guard let jpegData = capturedImage.jpegData(compressionQuality: 1.0) else {
                return
            }
            guard let jpegImage = UIImage(data: jpegData) else {
                return
            }
            
            debugPrint("Captured frame") // Add this line to log every captured frame

            if let moonRegion = detectMoon(in: jpegImage) {
                DispatchQueue.main.async {
                    debugPrint("Moon region found: \(moonRegion)")
                    self.instructionLabel.text = "尽量保持镜头稳定"
                }
                let zoomFactor = CGFloat.random(in: 8...10)
                setCameraZoom(zoomFactor: zoomFactor, to: moonRegion)
            } else {
                DispatchQueue.main.async {
                    debugPrint("Moon not found")
                    self.instructionLabel.text = "将镜头对准月亮"
                }
            }
        }

    private func detectMoon(in image: UIImage) -> CGRect? {
        // Call the OpenCVWrapper to detect the moon using Hough Circle Transform
        let detectedImage = OpenCVWrapper.detectMoon(in:image)

        // Convert the detected image back to CIImage
        guard let detectedCIImage = CIImage(image: detectedImage) else { return nil }

        // Analyze the detected image to find the moon region (with the green circle)
        let greenCircleDetector = CIFilter(name: "CIColorCube", parameters: [
            "inputCubeDimension": 16,
            "inputCubeData": createGreenColorCubeData(),
            "inputImage": detectedCIImage
        ])
        let greenCircleImage = greenCircleDetector?.outputImage

        // Calculate the bounding box of the detected green circle
        guard let cgImage = CIContext(options: nil).createCGImage(greenCircleImage!, from: greenCircleImage!.extent) else { return nil }

        guard let boundingBox = detectBoundingBox(cgImage) else { return nil }

        return boundingBox
    }

    
    
    //这个函数接受一个缩放系数和月亮检测到的区域，并设置相机的缩放系数、焦点和曝光点。请注意，这个函数使用了一个简化的方法来设置相机参数。在实际应用中，您可能需要根据实际需求对此函数进行调整。
    private func setCameraZoom(zoomFactor: CGFloat, to region: CGRect) {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        do {
            try camera.lockForConfiguration()
            
            // Limit zoom factor to the maximum allowed by the camera
            let maxZoomFactor = min(zoomFactor, camera.activeFormat.videoMaxZoomFactor)
            camera.videoZoomFactor = maxZoomFactor
            
            // Set focus and exposure point to the center of the detected moon region
            let focusPoint = CGPoint(x: region.midX, y: region.midY)
            if camera.isFocusPointOfInterestSupported {
                camera.focusPointOfInterest = focusPoint
                camera.focusMode = .autoFocus
            }
            
            if camera.isExposurePointOfInterestSupported {
                camera.exposurePointOfInterest = focusPoint
                camera.exposureMode = .continuousAutoExposure
            }
            
            camera.unlockForConfiguration()
        } catch {
            print("Error setting camera zoom: \(error)")
        }
    }
    
    private func createGreenColorCubeData() -> Data {
        let size = 16
        let cubeData = NSMutableData(length: size * size * size * 4)!
        
        let ptr = cubeData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        var offset = 0
        
        for z in 0 ..< size {
            for y in 0 ..< size {
                for x in 0 ..< size {
                    let alpha: UInt8 = 255
                    let red: UInt8 = UInt8(x)
                    let green: UInt8 = UInt8(y)
                    let blue: UInt8 = UInt8(z)
                    
                    if red >= 20 && red <= 200 && green >= 150 && green <= 255 && blue >= 0 && blue <= 150 {
                        ptr[offset] = alpha
                    } else {
                        ptr[offset] = 0
                    }
                    
                    ptr[offset + 1] = red
                    ptr[offset + 2] = green
                    ptr[offset + 3] = blue
                    
                    offset += 4
                }
            }
        }
        
        return cubeData as Data
    }
    
    private func detectBoundingBox(_ cgImage: CGImage) -> CGRect? {
        let width = cgImage.width
        let height = cgImage.height
        
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: height * bytesPerRow)
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            rawData.deallocate()
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                let byteIndex = bytesPerRow * y + bytesPerPixel * x
                let alpha = rawData[byteIndex]
                if alpha > 0 {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        rawData.deallocate()
        
        if minX <= maxX && minY <= maxY {
            return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        } else {
            return nil
        }
    }
    
    func convertHeicToJpeg(heicImage: UIImage) -> UIImage? {
        guard let imageData = heicImage.jpegData(compressionQuality: 1.0) else {
            return nil
        }

        return UIImage(data: imageData)
    }
}
