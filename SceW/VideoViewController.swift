//
//  VideoViewController.swift
//  SceW
//
//  Created by Vatsal Patel on 21/02/20.
//  Copyright © 2020 Vatsal Patel. All rights reserved.
//

import UIKit
import WebKit

class VideoViewController: UIViewController
{
    
    @IBOutlet weak var checkLabel: UILabel!
    var a : String?
    var yt : String = ""
    
    
    @IBOutlet weak var YT: WKWebView!
    
    override func viewDidLoad()
    {
        if let recievedText = a
        {
            yt = recievedText
            checkLabel.text = recievedText
        }
        
        //print(yt)
        var b = "MacBook Pro"
        var bb = "MacBook Air"
        var official = "466"
        b+="\n"
        bb+="\n"
        official+="\n"
        
        if yt == b
        {
            getVideo(videoCode: "ysRigNyavF4")
        }
        
        else if yt == bb
        {
             getVideo(videoCode: "hs1HoLs4SD0")
        }
        else if yt == official
        {
            getVideo(videoCode: "G4V-J0g-pFw")
        }
        
        else
        {
            getVideo(videoCode: "vsZRKm-9Ggs")
        }
    }
    
    
    func getVideo(videoCode : String )
    {
        let url = URL (string: "https://www.youtube.com/embed/\(videoCode)")
        
        if let ytURL = url
        {
            YT.load(URLRequest(url: ytURL))
        }
    }

}

