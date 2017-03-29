
//
//  FilterChain.swift
//  Randomizer
//
//  Created by Leo Stefansson on 22.12.2016.
//  Copyright © 2016 Generate Software Inc. All rights reserved.
//

import GPUImage
import AVFoundation
import NextLevel
import CoreMedia

public class FilterChain: NSObject, NextLevelDelegate, NextLevelVideoDelegate {
    let fbSize = Size(width: 1080, height: 1920)
    var camera:Camera!
    var renderView:RenderView!
    
    var rawInput: RawDataInput!
    var _availableFrameBuffer: CVPixelBuffer?
    
    var movieInput:MovieInput!
    var rawOutput:RawDataOutput!
    let testImage = UIImage(named: "unicornSecurity.jpg")
    
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
    
    var out = BasicOperation.init(fragmentShader: PassthroughFragmentShader) //empty
    var outForNextLevel = BasicOperation.init(fragmentShader: PassthroughFragmentShader) //empty
    
    override init () {
        super.init()
        initFilters()
        

        NextLevel.shared.delegate = self
        NextLevel.shared.videoDelegate = self
        NextLevel.shared.isVideoCustomContextRenderingEnabled = true
        //NextLevel.shared.videoConfiguration.preset = AVCaptureSessionPreset1280x720
        NextLevel.shared.videoConfiguration.aspectRatio = .active
        NextLevel.shared.automaticallyUpdatesDeviceOrientation = true
        
        
    }
    
    public func initFilters() {
        filters = [saturationFilter, pixellateFilter, dotFilter, invertFilter, halftoneFilter, /*blendFilter,*/ swirlFilter, dilationFilter, erosionFilter, /*lowPassFilter, highPassFilter,*/ cgaColorspaceFilter, kuwaharaFilter, posterizeFilter, vignetteFilter, zoomBlurFilter, polarPizellateFilter, pinchDistortionFilter, sphereRefractionFilter, glassSphereRefractionFilter, embossFilter, toonFilter, thresholdSketchFilter, /*ShiftFilter, iOSBlurFilter,*/ solarizeFilter]
//        filters = [pixellateFilter]
        var i = 0
        while i<numFilters {
            activeFilters.append(filters[i])
            i+=1
        }
        
    }
    // Pass the view from the ViewController
    public func startCameraWithNLView(view: RenderView!){
        
        rawInput = RawDataInput.init()
        
        self.renderView = view
        self.renderView.autoresizingMask = [.flexibleWidth, .flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleTopMargin]
        self.renderView.fillMode = FillMode.preserveAspectRatioAndFill
        self.renderView.backgroundColor = UIColor.black
        
        
        startChain()
        
    }
    public func makeNextLevelPreviewLayer(previewView: UIView?){
        
        if let previewView = previewView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.backgroundColor = UIColor.black
            NextLevel.shared.previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(NextLevel.shared.previewLayer)
        }
    }
    // Start the filter chain
    public func startChain() {
        // Request device authorization (camera and audio)
        let nextLevel = NextLevel.shared
        if nextLevel.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized {
            do {
                try nextLevel.start()
                //NextLevel.shared.freezePreview()
                rebuildChain()
                //prepareOutFramesForNextLevel()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else {
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeVideo)
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeAudio)
        }
        
    }
    
    public func prepareOutFramesForNextLevel(){
        rawOutput = RawDataOutput.init()
        self.outForNextLevel.addTarget(rawOutput)
        
        rawOutput.dataAvailableCallbackWithSize = {dataArray, frameSize in //THIS IS CALLED AT THE VERY END OF THE FILTERCHAIN
            
            let numberOfBytesPerRow = frameSize.width;
            let data = Data.init(bytes: dataArray)
            
            
            data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) -> Void in
                let rawPtr = UnsafeMutableRawPointer(mutating: u8Ptr)
                
                var pixelBuffer : CVPixelBuffer?;
                _ = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                          Int(frameSize.width),
                                                          Int(frameSize.height),
                                                          kCVPixelFormatType_32BGRA,
                                                          rawPtr,
                                                          Int(numberOfBytesPerRow*4), nil, nil, nil,
                                                          &pixelBuffer);
                //print(result)
                if pixelBuffer != nil {
                    //DEBUG: Convert CVPixelBuffer back to UIImage just to see if the image is right
                    self._availableFrameBuffer = pixelBuffer
//                    let pb = self._availableFrameBuffer!
//                    let ciImage:CIImage = CIImage(cvPixelBuffer: pb, options: nil)
//                    let temporaryContext = CIContext.init(options: nil)
//                    let videoImage = temporaryContext.createCGImage(ciImage, from: CGRect(x:0,y:0,width:CVPixelBufferGetWidth(pb), height:CVPixelBufferGetHeight(pb)))
//                    
//                    let returnedImg = UIImage.init(cgImage: videoImage!);
                    //Put a breakpoint here.. so see the image in the debugger, by pressing SPACE after selecting the variable returnedImg
                    //var x = 1 //this does nothing
                }
            }
        }
    }
    
    //not using this method
    public func startCameraWithView(view: RenderView) {
        do {
            renderView = view
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = false
            camera.startCapture()
            renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            renderView.backgroundColor = UIColor.black
            
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
    }
    
    // Create chain from Camera through all Active Filters to the Render View
    public func rebuildChain() {
//        camera --> activeFilters[0]
        rawInput --> activeFilters[0]

        var i = 0
        
        while i<numFilters-1 {
            activeFilters[i] --> activeFilters[i+1]
            i+=1
        }
        
        activeFilters[numFilters-1] --> self.renderView //for viewing
        activeFilters[numFilters-1] --> self.out //for someone else to use
        activeFilters[numFilters-1] --> self.outForNextLevel //for nextlevel
    }
    
    public func randomizeFilterChain() {
        
        print("RANDOMIZING FILTER CHAIN")
        // camera.stopCapture()
        // Remove all targets from currently active filters and camera
        rawInput.removeAllTargets()
        
        // movieInput.removeAllTargets()
        
//        print("activeFilters.count: \(activeFilters.count)")
//        print("filters.count: \(filters.count)")
        
        // Remove targets from active filters
        var index = 0
        for _ in activeFilters {
//            print("removing target from filter at index \(index)")
            activeFilters[index].removeAllTargets()
            index+=1
        }
        
        // Remove active filters from array
        
        // Select new active filters
        index = 0
        for _ in activeFilters {
            let randNum = uniqueRandomIndex()
            //            print("activating filter at index \(index), filter is: \(filters[randNum])")
            activeFilters[index] = filters[randNum]
            index+=1
        }
//        print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++-")
//        print("Current filter chain:")
//        for filter in activeFilters {
//            print(filter)
//        }
        
        rebuildChain()
//        camera.startCapture()
    }
    
    private func randomIndex() -> Int {
        let count = filters.count
        
        let randNum = Int(arc4random_uniform(UInt32(count)))
        //        print("diceRoll: \(randNum)")
        return randNum
    }
    
    private func uniqueRandomIndex() -> Int {
        var index = 0;
        
        var alreadySelected = true
        
        
        while alreadySelected {
            index = randomIndex()
            var hits = 0
          //  print("Trying to find unique number, current \(hits) hits")
            let newFilterName = type(of:filters[index])//object_getClassName(filters[index])
          //  print("----------------------------------------------------------------------------")
          //  print("index \(index)")
            for filter in activeFilters {
                let activeFilterName = type(of:filter)//object_getClassName(filter)
             //   print("comparing \(newFilterName) to \(activeFilterName)")
                if (newFilterName == activeFilterName) {
                    hits = hits+1
                 //   print("hits \(hits)")
                }
            }
            if (hits == 0) {
                alreadySelected = false
                // Leave the while loop
            }
            
        }

        return index
    }
    
    public func capture() {
        print("Capture")
        
            
            var pb: CVPixelBuffer? = nil
            if let pixelBuffer = self._availableFrameBuffer {
                pb = pixelBuffer
            }
//            NextLevel.shared.capturePhotoFromVideo()
            DispatchQueue.main.async {
                //                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
//                let pb = pixelBuffer
                let ciImage:CIImage = CIImage(cvPixelBuffer: pb!, options: nil)
                let temporaryContext = CIContext.init(options: nil)
                let videoImage = temporaryContext.createCGImage(ciImage, from: CGRect(x:0,y:0,width:CVPixelBufferGetWidth(pb!), height:CVPixelBufferGetHeight(pb!)))
                
                _ = UIImage.init(cgImage: videoImage!);
                //                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
                //Put a breakpoint here.. so see the image in the debugger, by pressing SPACE after selecting the variable returnedImg
                print("taken")
                
            }
        
        
    }
    // MARK: - NextLevelDelegate
    
    //extension FilterChain: NextLevelDelegate {
    
    // permission
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: String) {
        print("NextLevel, authorization updated for media \(mediaType) status \(status)")
    }
    
    // configuration
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
        print("NetLevel -> didUpdateVideoConfiguration")
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
        print("NetLevel -> didUpdateAudioConfiguration")
    }
    
    // session
    public func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelSessionWillStart")
    }
    
    public func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelSessionDidStart")
    }
    
    public func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelSessionDidStop")
    }
    
    // interruption
    public func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelSessionWasInterrupted")
    }
    
    public func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelSessionInterruptionEnded")
    }
    
    // preview
    public func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelWillStartPreview")
    }
    
    public func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelDidStopPreview")
    }
    
    // mode
    public func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelCaptureModeWillChange")
    }
    
    public func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
        print("NextLevel -> nextLevelCaptureModeDidChange")
    }
    
    
    // MARK: - NextLevelVideoDelegate
    
    // video zoom
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
        print("NextLevel -> didUpdateVideoZoomFactor")
    }
    
    
    // video frame processing
    public func nextLevel(_ nextLevel: NextLevel,   willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        //print("NextLevel -> willProcessRawVideoSampleBuffer")
        
//// TRY 1 - it works... but slow frames and sometimes rawDataInput breaks
//        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        CVPixelBufferLockBaseAddress(imageBuffer,CVPixelBufferLockFlags(rawValue: 0));
//        let width = CVPixelBufferGetWidth(imageBuffer)
//        let height = CVPixelBufferGetHeight(imageBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
//        //Get the bytes from the imageBuffer
//        if let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) {
//            let i8bufptr = UnsafeBufferPointer(start: baseAddress.assumingMemoryBound(to: UInt8.self), count: width*height*4)
//            let i8array = Array(i8bufptr)
//            self.rawInput.uploadBytes(i8array, size: Size.init(width: Float(width), height: Float(height)), pixelFormat: PixelFormat.bgra)
//            
//        } else {
//            // `baseAddress` is `nil`
//        }
//        CVPixelBufferUnlockBaseAddress( imageBuffer, CVPixelBufferLockFlags(rawValue: 0) );
        
//// TRY 2 - it works... but slow frames
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
//        let chromaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
//        
//        let width = CVPixelBufferGetWidth(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        
//        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
//        let chromaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
//        let lumaBuffer = lumaBaseAddress?.assumingMemoryBound(to: UInt8.self)
//        let chromaBuffer = chromaBaseAddress?.assumingMemoryBound(to: UInt8.self)
//        
//        var rgbaImage = [UInt8](repeating: 0, count: 4*width*height)
//        for x in 0 ..< width {
//            for y in 0 ..< height {
//                let lumaIndex = x+y*lumaBytesPerRow
//                let chromaIndex = (y/2)*chromaBytesPerRow+(x/2)*2
//                let yp = lumaBuffer?[lumaIndex]
//                let cb = chromaBuffer?[chromaIndex]
//                let cr = chromaBuffer?[chromaIndex+1]
//                
//                let ri = Double(yp!)                                + 1.402   * (Double(cr!) - 128)
//                let gi = Double(yp!) - 0.34414 * (Double(cb!) - 128) - 0.71414 * (Double(cr!) - 128)
//                let bi = Double(yp!) + 1.772   * (Double(cb!) - 128)
//                
//                let r = UInt8(min(max(ri,0), 255))
//                let g = UInt8(min(max(gi,0), 255))
//                let b = UInt8(min(max(bi,0), 255))
//                
//                rgbaImage[(x + y * width) * 4] = b
//                rgbaImage[(x + y * width) * 4 + 1] = g
//                rgbaImage[(x + y * width) * 4 + 2] = r
//                rgbaImage[(x + y * width) * 4 + 3] = 255
//            }
//        }
//        
//        self.rawInput.uploadBytes(rgbaImage, size: Size.init(width: Float(width), height: Float(height)), pixelFormat: PixelFormat.rgba)
//        CVPixelBufferUnlockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: 0) );

//Try 3 .. only works if I comment NextLevel code to make it not use chroma/luma
        
        //http://stackoverflow.com/questions/40766672/how-to-keep-low-latency-during-the-preview-of-video-coming-from-avfoundation
//        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        //CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
        //let width = CVPixelBufferGetWidth(pixelBuffer)
        //let height = CVPixelBufferGetHeight(pixelBuffer)
        //let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        //let int8Buffer = baseAddress?.assumingMemoryBound(to: UInt8.self)
        
        //let arr = Array(UnsafeBufferPointer(start: int8Buffer, count: width*height ))
        
        //var rgbaImage = [UInt8](repeating: 0, count: 4*width*height)
        //for i in 0 ..< (width*height*4){
        //    rgbaImage[i] = UInt8((int8Buffer?[i])!)
        //}
        
        //self.rawInput.uploadBytes(arr, size: Size.init(width: Float(width), height: Float(height)), pixelFormat: PixelFormat.rgba)
        
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        
        self.rawInput.uploadPixelBuffer(pixelBuffer)
        
        
        

        
    
        //CVPixelBufferUnlockBaseAddress(pixelBuffer,CVPixelBufferLockFlags(rawValue: 0))
        

        
        if let frame = self._availableFrameBuffer {
            nextLevel.videoCustomContextImageBuffer = frame
        }
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    public func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
        print("NextLevel -> renderToCustomContextWithImageBuffer")
        
        // provide the frame back to NextLevel for recording
        if let frame = self._availableFrameBuffer {
            nextLevel.videoCustomContextImageBuffer = frame
        }
        
    }
    
    // video recording session
    public func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        print("NextLevel -> didSetupVideoInSession")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        print("NextLevel -> didSetupAudioInSession")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
        print("NextLevel -> didStartClipInSession")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
        print("NextLevel -> didCompleteClip")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        print("NextLevel -> didAppendVideoSampleBuffer")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        print("NextLevel -> didAppendAudioSampleBuffer")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        print("NextLevel -> didSkipVideoSampleBuffer")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        print("NextLevel -> didSkipAudioSampleBuffer")

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        print("NextLevel -> didCompleteSession")

        // called when a configuration time limit is specified
        //        self.endCapture()
    }
    
    // video frame photo
    
    public func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        print("NextLevel -> didCompletePhotoCaptureFromVideoFrame")


        if let dictionary = photoDict {
            let photoData = dictionary[NextLevelPhotoJPEGKey]
            if let data = photoData as? Data {
                let photoImage = UIImage(data: data)
                print("taken")
            }
            
        }
        
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
