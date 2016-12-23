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
    let fbSize = Size(width: 640, height: 480)
    var camera:Camera!
    var renderView:RenderView!
    
    let saturationFilter = SaturationAdjustment()
    let pixellateFilter = Pixellate()
    let dotFilter = PolkaDot()
    let invertFilter = ColorInversion()
    let halftoneFilter = Halftone()
    let blendFilter = AlphaBlend()
    let swirlFilter = SwirlDistortion()
    let dilationFilter = Dilation()
    
    var filters: [BasicOperation] = [BasicOperation]() // All available filters
    var activeFilters: [BasicOperation] = [BasicOperation]() // Currently active filters
    var numFilters = 3 // Number of filters in chain
    
    public func initFilters() {
        filters = [saturationFilter, pixellateFilter, dotFilter, invertFilter, halftoneFilter, blendFilter, swirlFilter, dilationFilter]
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
        while i<numFilters {
            activeFilters[i] --> activeFilters[i+1]
            i+=1
        }
        activeFilters[0] --> renderView
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
            print("activating filter at index \(index)")
            activeFilters[index] = filters[randomIndex()]
            index+=1
        }
        
        rebuildChain()
        camera.startCapture()
    }
    
    public func randomIndex() -> Int {
        let diceRoll = Int(arc4random_uniform(6) + 1)
        print("diceRoll: \(diceRoll)")
        return diceRoll
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
