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
        let filterRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let filterView = RenderView(frame: filterRect)
        

        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = .red
        button.setTitle("Test Button", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        
        
//        self.view.addSubview(filterView)
//        
//        filterChain.start()
//        filterChain.startCameraWithView(view: filterView)
        
    }

    func buttonAction(sender: UIButton!) {
        print("Button tapped")
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
