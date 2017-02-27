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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create RenderView and add it to main view
        self.view.addSubview(filterView)

        //  Create a touch event recognizer
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.someAction (_:)))
        self.filterView.addGestureRecognizer(gesture)
        
        // Create a capture button
        let captureButton = createCaptureButton()
        
        captureButton.addTarget(self, action: #selector(captureButtonAction), for: .touchUpInside)
        self.view.addSubview(captureButton)
        
        filterChain.start()
        filterChain.startCameraWithView(view: filterView)
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
