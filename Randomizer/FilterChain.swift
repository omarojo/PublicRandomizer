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
    
    var activeFilters = [0] // Make the array longer for more filters
    
    var filters = [BasicOperation]()
//    self.initFilters()
    
    public func initFilters() {
        filters = [saturationFilter, pixellateFilter, dotFilter, invertFilter, halftoneFilter, blendFilter, swirlFilter, dilationFilter]
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
            camera --> filters[activeFilters[0]] --> renderView
            camera.startCapture()

        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }

    }
    
    public func randomizeFilterChain() {
        do {
            print("RANDOMIZING")
            
//            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            print("stopping camera capture")
            camera.stopCapture()
            // Remove all targets from currently active filters and camera
            print("removing targets from camera")
            camera.removeAllTargets()
            print("target removed from camera")
            //            camera.delegate = self
            print("length of activeFilters array is: \(activeFilters.count)")
            print("length of filters array is: \(filters.count)")
            for i in activeFilters {
                print("removing target from filter \(activeFilters[i])")
                filters[activeFilters[i]].removeAllTargets()
            }
            for i in activeFilters {
                print("activating filter \(activeFilters[i])")
                activeFilters[i] = randomIndex()
                
            }
            
            camera --> filters[activeFilters[0]] --> renderView
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    public func randomIndex() -> Int {
        let diceRoll = Int(arc4random_uniform(6) + 1)
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
