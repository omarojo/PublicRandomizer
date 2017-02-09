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

        let captureButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        captureButton.backgroundColor = .red
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(captureButton)
        
//        let someOtherButton = UIButton(type: )
        
        filterChain.start()
        filterChain.startCameraWithView(view: filterView)
        
    }

    func buttonAction(sender: UIButton!) {
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
