//
//  PrefsViewController.swift
//  Otp Token Manager
//
//  Created by William Roscoe on 2017/05/25.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {
    
    var share = DataContainerSingleton.sharedDataContainer
    
    var prefs = Preferences()
    
    @IBAction func sliderAction(_ sender: NSSlider) {
        
        UpdateSliderValueToString()
    }

    @IBOutlet weak var sliderOutput: NSTextField!
    
    @IBOutlet weak var sliderOutlet: NSSlider!
    
    @IBAction func cancelBtnAction(_ sender: NSButton) {
        
        view.window?.close()
    }
    
    @IBAction func okBtnAction(_ sender: NSButton) {
        // save prefs
        prefs.screen_protect_timeout = sliderOutlet.doubleValue
        share.screen_protect_timeout = sliderOutlet.doubleValue
        
        view.window?.close()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // get prefs
        sliderOutlet.doubleValue = prefs.screen_protect_timeout
        
        UpdateSliderValueToString()
        
    }
    
    func UpdateSliderValueToString() {
        sliderOutput.stringValue = "\(sliderOutlet.integerValue) seconds"
    }
    
}
