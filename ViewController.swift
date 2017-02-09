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
    var renderView: RenderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view
        let filterRect = UIScreen.main.bounds
        let filterView = RenderView(frame: filterRect)
        self.view.addSubview(filterView)

        let bSize = 72; // This should be an even number
        let loc = CGRect(x: Int(UIScreen.main.bounds.width/2)-(bSize/2), y: Int(UIScreen.main.bounds.height)-Int(UIScreen.main.bounds.height/7), width: bSize, height: bSize)
        let captureButton = UIButton(frame: loc)
        
        captureButton.setTitle("C", for: .normal)
        captureButton.backgroundColor = .red
        // Make the button round
        captureButton.layer.cornerRadius = 0.5 * captureButton.bounds.size.width
        captureButton.clipsToBounds = true
        
        captureButton.addTarget(self, action: #selector(captureButtonAction), for: .touchUpInside)
        self.view.addSubview(captureButton)
        
//        let someOtherButton = UIButton(type: )
        
        filterChain.start()
        filterChain.startCameraWithView(view: filterView)
        
    }

    func captureButtonAction(sender: UIButton!) {
        print("Button tapped")
        filterChain.randomizeFilterChain()
        filterChain.capture()
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
