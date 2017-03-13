
//  FilterChain.swift
//  Randomizer
//
//  Created by Leo Stefansson on 22.12.2016.
//  Copyright © 2016 Generate Software Inc. All rights reserved.
//

import GPUImage
import AVFoundation
import NextLevel

public class FilterChain: NSObject, NextLevelDelegate, NextLevelVideoDelegate {
    let fbSize = Size(width: 1080, height: 1920)
    var camera:Camera!
    var renderView:RenderView!
    
    let saturationFilter = SaturationAdjustment()
    let pixellateFilter = Pixellate()
    let dotFilter = PolkaDot()
    let invertFilter = ColorInversion()
    let halftoneFilter = Halftone()
    //    let blendFilter = AlphaBlend()
    let swirlFilter = SwirlDistortion()
    let dilationFilter = Dilation()
    
    let erosionFilter = Erosion()
    let lowPassFilter = LowPassFilter()
    let highPassFilter = HighPassFilter()
    let cgaColorspaceFilter = CGAColorspaceFilter()
    let kuwaharaFilter = KuwaharaFilter()
    let posterizeFilter = Posterize()
    let vignetteFilter = Vignette()
    let zoomBlurFilter = ZoomBlur()
    let polarPizellateFilter = PolarPixellate()
    let pinchDistortionFilter = PinchDistortion()
    let sphereRefractionFilter = SphereRefraction()
    let glassSphereRefractionFilter = GlassSphereRefraction()
    let embossFilter = EmbossFilter()
    let toonFilter = ToonFilter()
    let thresholdSketchFilter = ThresholdSketchFilter()
    let tiltShiftFilter = TiltShift()
    let iOSBlurFilter = iOSBlur()
    let solarizeFilter = Solarize()
    
    
    var filters: [BasicOperation] = [BasicOperation]() // All available filters, casting as superclass to hold all filters in an array
    var activeFilters: [BasicOperation] = [BasicOperation]() // Currently active filters
    var numFilters = 7 // Number of filters in chain
    
    override init () {
        super.init()
        initFilters()
        
        NextLevel.sharedInstance.delegate = self
        NextLevel.sharedInstance.videoDelegate = self
        NextLevel.sharedInstance.isVideoCustomContextRenderingEnabled = true
        
    }
    
    public func initFilters() {
        filters = [saturationFilter, pixellateFilter, dotFilter, invertFilter, halftoneFilter, /*blendFilter,*/ swirlFilter, dilationFilter, erosionFilter, /*lowPassFilter, highPassFilter,*/ cgaColorspaceFilter, kuwaharaFilter, posterizeFilter, vignetteFilter, zoomBlurFilter, polarPizellateFilter, pinchDistortionFilter, sphereRefractionFilter, glassSphereRefractionFilter, embossFilter, toonFilter, thresholdSketchFilter, /*ShiftFilter, iOSBlurFilter,*/ solarizeFilter]
        var i = 0
        while i<numFilters {
            activeFilters.append(filters[i])
            i+=1
        }
        
    }
    
    
    // Start the filter chain
    public func startChain() {
        // Request device authorization (camera and audio)
        let nextLevel = NextLevel.sharedInstance
        if nextLevel.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else {
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeVideo)
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeAudio)
        }
        
        
        
    }
    
    private func startCaptureSession() {
        //        NextLevel.sharedInstance.delegate = self
        //        NextLevel.sharedInstance.deviceDelegate = self
        //        NextLevel.sharedInstance.videoDelegate = self
        //        NextLevel.sharedInstance.photoDelegate = self
        //
        //        // modify .videoConfiguration, .audioConfiguration, .photoConfiguration properties
        //        // Compression, resolution, and maximum recording time options are available
        //
        //        NextLevel.sharedInstance.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(5, 600)
        //        NextLevel.sharedInstance.audioConfiguration.bitRate = 44000
    }
    
    // Pass the view from the ViewController
    public func startCameraWithView(view: RenderView) {
        do {
            renderView = view
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = false
            //rebuildChain()
            //camera.startCapture()
            
            // NextLevel implementation
            renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            renderView.backgroundColor = UIColor.black
            NextLevel.sharedInstance.previewLayer.frame = renderView.bounds
            renderView.layer.addSublayer(NextLevel.sharedInstance.previewLayer)
            
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
    }
    
    // Create chain from Camera through all Active Filters to the Render View
    public func rebuildChain() {
        camera --> activeFilters[0]
        var i = 0
        
        while i<numFilters-1 {
            activeFilters[i] --> activeFilters[i+1]
            i+=1
        }
        activeFilters[numFilters-1] --> renderView
    }
    
    
    // Randomize
    public func randomizeFilterChain() {
        
        print("RANDOMIZING")
        camera.stopCapture()
        // Remove all targets from  camera
        camera.removeAllTargets()
        
        // Remove targets from active filters
        var index = 0
        for _ in activeFilters {
            activeFilters[index].removeAllTargets()
            index+=1
        }
        
        // Select new active filters
        index = 0
        for _ in activeFilters {
            let randNum = uniqueRandomIndex()
            activeFilters[index] = filters[randNum]
            index+=1
        }
        
        rebuildChain()
        camera.startCapture()
    }
    
    private func randomIndex() -> Int {
        let count = filters.count
        let randNum = Int(arc4random_uniform(UInt32(count)))
        return randNum
    }
    
    private func uniqueRandomIndex() -> Int {
        var index = 0;
        
        var alreadySelected = true
        
        
        while alreadySelected {
            index = randomIndex()
            var hits = 0
            let newFilterName = type(of:filters[index])//object_getClassName(filters[index])
            
            for filter in activeFilters {
                let activeFilterName = type(of:filter)
                
                if (newFilterName == activeFilterName) {
                    hits = hits+1
                }
            }
            if (hits == 0) {
                // Leave while loop if no filters are the same
                alreadySelected = false
            }
            
        }
        
        return index
    }
    
    public func capture() {
        print("Capture")
        // UIImageWriteToSavedPhotosAlbum(<#T##image: UIImage##UIImage#>, <#T##completionTarget: Any?##Any?#>, <#T##completionSelector: Selector?##Selector?#>, <#T##contextInfo: UnsafeMutableRawPointer?##UnsafeMutableRawPointer?#>)
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            //self.saturationFilter.saveNextFrameToURL(URL(string:"TestImage.png", relativeTo:documentsDir)!, format:.png)
            self.filters[numFilters-1].saveNextFrameToURL(URL(string:"Randomized.png", relativeTo:documentsDir)!, format:.png)
            print("saving image at \(documentsDir)")
        } catch {
            print("Couldn't save image: \(error)")
        }
        
    }
    // MARK: - NextLevelDelegate
    
    //extension FilterChain: NextLevelDelegate {
    
    // permission
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: String) {
        print("NextLevel, authorization updated for media \(mediaType) status \(status)")
        if nextLevel.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else if status == .notAuthorized {
            // gracefully handle when audio/video is not authorized
            print("NextLevel doesn't have authorization for audio or video")
        }
    }
    
    // configuration
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    // session
    public func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionWillStart")
    }
    
    public func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStart")
    }
    
    public func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStop")
    }
    
    // interruption
    public func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }
    
    // preview
    public func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }
    
    // mode
    public func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
    
    // MARK: - NextLevelVideoDelegate
    
    // video zoom
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    // video frame processing
    public func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        var thePixelBuffer : CVPixelBuffer?
        
        if let testImage = UIImage(named: "unicornSecurity.jpg") {
            thePixelBuffer = self.pixelBufferFromImage(image: testImage)
        }
        
        
        if let frame = thePixelBuffer {
            nextLevel.videoCustomContextImageBuffer = frame
        }
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    public func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
        print("renderToCustomContextWithImageBuffer --> Do something here")
    }
    
    // video recording session
    public func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        //        print("setup video")
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        //        print("setup audio")
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        // called when a configuration time limit is specified
        //        self.endCapture()
    }
    
    // video frame photo
    
    public func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        /*
         if let dictionary = photoDict,
         let photoData = dictionary[NextLevelPhotoJPEGKey] {
         
         PHPhotoLibrary.shared().performChanges({
         
         let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle)
         if albumAssetCollection == nil {
         let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewControllerAlbumTitle)
         let _ = changeRequest.placeholderForCreatedAssetCollection
         }
         
         }, completionHandler: { (success1: Bool, error1: Error?) in
         
         if success1 == true {
         if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle) {
         PHPhotoLibrary.shared().performChanges({
         if let data = photoData as? Data,
         let photoImage = UIImage(data: data) {
         let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
         let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
         let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
         assetCollectionChangeRequest?.addAssets(enumeration)
         }
         }, completionHandler: { (success2: Bool, error2: Error?) in
         if success2 == true {
         let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
         let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
         alertController.addAction(okAction)
         self.present(alertController, animated: true, completion: nil)
         }
         })
         }
         } else if let _ = error1 {
         print("failure capturing photo from video frame \(error1)")
         }
         
         })
         
         }
         */
    }
    // MARK - PixelBuffer Methods
    // Get PixelBuffer from Image (thanks Omar)
    func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer {
        
        
        let ciimage = CIImage(image: image)
        //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
        let tmpcontext = CIContext(options: nil)
        let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)
        
        let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
        let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
        let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        keysPointer.initialize(to: keys)
        valuesPointer.initialize(to: values)
        
        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
        
        let width = cgimage!.width
        let height = cgimage!.height
        
        var pxbuffer: CVPixelBuffer?
        // if pxbuffer = nil, you will get status = -6661
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options, &pxbuffer)
        status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        
        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);
        
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
        let context = CGContext(data: bufferAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesperrow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
        //        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal
        
        
        context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
        status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        return pxbuffer!;
        
    }
}
