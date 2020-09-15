//
//  ViewController.swift
//  FlappyBird
//
//  Created by 伊藤光次郎 on 2020/09/11.
//  Copyright © 2020 kojiro.ito. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let skView = self.view as! SKView
        
        skView.showsFPS = true
        
        skView.showsNodeCount = true
        
        let scene = GameScene(size: skView.frame.size)
        
        
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool{
        get{
            return true
        }
    }


}

