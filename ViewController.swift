//
//  ViewController.swift
//  Randomizer
//
//  Created by Leo Stefansson on 31.1.2017.
//  Copyright © 2017 Sunset Lake Software LLC. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {

    var filterChain = FilterChain()
    let filterView = RenderView(frame: UIScreen.main.bounds)
    let nLView = UIView(frame: CGRect(origin: CGPoint(x:0,y:0), size: CGSize(width: UIScreen.main.bounds.width * 0.3,height: UIScreen.main.bounds.height * 0.3) ))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterView.frame = self.view.bounds
        // Do any additional setup after loading the view
        
        // Create RenderView and add it to main view
        self.view.addSubview(filterView)
        self.view.addSubview(nLView)
        //  Create a touch event recognizer
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.someAction (_:)))
        self.filterView.addGestureRecognizer(gesture)
        
        // Create a capture button
        let captureButton = createCaptureButton()
        
        captureButton.addTarget(self, action: #selector(captureButtonAction), for: .touchUpInside)
        self.view.addSubview(captureButton)
        
//        let someOtherButton = UIButton(type: )
        
//        filterChain.startChain()
//        filterChain.startCameraWithView(view: filterView)
        filterChain.startCameraWithNLView(view: filterView)
        filterChain.makeNextLevelPreviewLayer(previewView: nLView)
    }
    
    // Layout and setup
    func createCaptureButton() -> UIButton{
        let bSize = 72; // This should be an even number
        let loc = CGRect(x: Int(UIScreen.main.bounds.width/2)-(bSize/2), y: Int(UIScreen.main.bounds.height)-Int(UIScreen.main.bounds.height/7), width: bSize, height: bSize)
        let captureButton = UIButton(frame: loc)
        
        captureButton.setTitle("C", for: .normal)
        captureButton.backgroundColor = .red
        // Make the button round
        captureButton.layer.cornerRadius = 0.5 * captureButton.bounds.size.width
        captureButton.clipsToBounds = true
        return captureButton
    }
    
    // Button actions
    func captureButtonAction(sender: UIButton!) {
        print("Capture Button tapped")
        
        filterChain.capture()
    }
    
    // Touch recognizer action
    func someAction(_ sender:UITapGestureRecognizer){
        // do other task
        print("Touch Event!!!, randomizing filter")
        filterChain.randomizeFilterChain()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait //this is always read twice idk why
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation == .landscapeRight {
            print("Landscape")
            filterView.orientation = .landscapeLeft
        } else if UIDevice.current.orientation == .landscapeLeft {
            print("Lanscape Left")
            filterView.orientation = .landscapeRight
        } else if UIDevice.current.orientation == .portrait {
            print("Portrait")
            filterView.orientation = .portrait
        }else if UIDevice.current.orientation == .portraitUpsideDown {
            print("Portrait")
            filterView.orientation = .portraitUpsideDown
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
