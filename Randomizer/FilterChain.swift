//
//  FilterChain.swift
//  Randomizer
//
//  Created by Leo Stefansson on 22.12.2016.
//  Copyright © 2016 Generate Software Inc. All rights reserved.
//

import GPUImage
import AVFoundation

public class FilterChain {
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
    
    public func initFilters() {
        filters = [saturationFilter, pixellateFilter, dotFilter, invertFilter, halftoneFilter, /*blendFilter,*/ swirlFilter, dilationFilter, erosionFilter, /*lowPassFilter, highPassFilter,*/ cgaColorspaceFilter, kuwaharaFilter, posterizeFilter, vignetteFilter, zoomBlurFilter, polarPizellateFilter, pinchDistortionFilter, sphereRefractionFilter, glassSphereRefractionFilter, embossFilter, toonFilter, thresholdSketchFilter, /*ShiftFilter, iOSBlurFilter,*/ solarizeFilter]
        var i = 0
        while i<numFilters {
            activeFilters.append(filters[i])
            i+=1
        }
   
    }
    
    // Start the filter chain
    public func start() {
        initFilters()
    }
    // Pass the view from the ViewController
    public func startCameraWithView(view: RenderView) {
        do {
            renderView = view
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = false
//            camera.delegate = self
            
            rebuildChain()
            
            camera.startCapture()

        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }

    }
    
    public func rebuildChain() {
        camera --> activeFilters[0]
        var i = 0
        
        while i<numFilters-1 {
            activeFilters[i] --> activeFilters[i+1]
            i+=1
        }
        activeFilters[numFilters-1] --> renderView
    }
    
    public func randomizeFilterChain() {
        
        print("RANDOMIZING")
        camera.stopCapture()
        // Remove all targets from currently active filters and camera
        camera.removeAllTargets()
        print("activeFilters.count: \(activeFilters.count)")
        print("filters.count: \(filters.count)")
            
        // Remove targets from active filters
        var index = 0
        for _ in activeFilters {
            print("removing target from filter at index \(index)")
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
        print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++-")
        print("Current filter chain:")
        for filter in activeFilters {
            print(filter)
        }
        
        rebuildChain()
        camera.startCapture()
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
            print("Trying to find unique number, current \(hits) hits")
            let newFilterName = type(of:filters[index])//object_getClassName(filters[index])
            print("----------------------------------------------------------------------------")
            print("index \(index)")
            for filter in activeFilters {
                let activeFilterName = type(of:filter)//object_getClassName(filter)
                print("comparing \(filter) to \(activeFilterName)")
                if (newFilterName == activeFilterName) {
                    hits = hits+1
                    print("hits \(hits)")
                }
            }
            if (hits == 0) {
                alreadySelected = false
                // Leave the while loop
            }

        }
//        print("Active filters: ")
//        for filter in activeFilters {
//            //print(filter)
//        }
//        
//
//  
//        
//        var index = 0
//        print("class name \(object_getClassName(filters[0]))");
//        if filters is [BasicOperation] {
//            print("something")
//            
//            // obj is a string array. Do something with stringArray
//        }
//        else {
//            // obj is not a string array
//        }
        
        
        return index
    }
    
    public func capture() {
        print("Capture")
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            self.saturationFilter.saveNextFrameToURL(URL(string:"TestImage.png", relativeTo:documentsDir)!, format:.png)
            print(documentsDir)
        } catch {
            print("Couldn't save image: \(error)")
        }

    }
    
    
}
