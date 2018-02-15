//
//  CollectionViewItem.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/15.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

class CollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var tokenLabel: NSTextField!
    
    var share = DataContainerSingleton.sharedDataContainer
    
    private var timer: Timer? = nil
    private var storedToken:String = ""
    
    var otp: Otp? {
        didSet {
            if otp == nil {
                
                timer?.invalidate()
            } else if timer == nil || !timer!.isValid {
                UpdateDisplay()
                timer = Timer.scheduledTimer(timeInterval: 0.1,
                                             target: self,
                                             selector: (#selector(self.timerCallback)),
                                             userInfo: nil,
                                             repeats: true)
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        
        // border info - shown when selected/clicked
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.borderColor = NSColor.white.cgColor
        view.layer?.borderWidth = 3.0
        view.layer?.cornerRadius = 3.0
        
    
    }
    
    override var isSelected: Bool {
        didSet {
            if (isSelected && !share.screen_protect) {
                view.layer?.borderColor = NSColor.controlColor.cgColor
                CopyTokenToClipboard()
                BlurUnBlurToken(blur: false)
                
            } else {
                view.layer?.borderColor = CGColor.white
                storedToken = ""
                BlurUnBlurToken(blur: true)
            }
        }
    }
    
    func BlurUnBlurToken(blur:Bool) {
        tokenLabel.contentFilters.removeAll()
        if (blur) {
            let filter = CIFilter(name:"CIBoxBlur")
            filter?.setValue(17, forKey: "inputRadius")
            
            tokenLabel.contentFilters.append(filter!)
        }
    }
    
    
    func timerCallback(timer: Timer) {
        UpdateDisplay()

    }
    
    func CopyTokenToClipboard() {
        if (!share.screen_protect) {
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
            pasteboard.setString(tokenLabel.stringValue.replacingOccurrences(of: " ", with: ""), forType: NSPasteboardTypeString)
            storedToken = tokenLabel.stringValue
        }
    }
    
    func UpdateDisplay() {
        nameLabel.stringValue = (otp?.issuer)! + " - " + (otp?.username)!
        
        let otpCalc = otp?.GenerateToken()
        tokenLabel.stringValue = otpCalc!.Token
        
        // update clipboard if token changes
        if (isSelected && storedToken != tokenLabel.stringValue) {
            CopyTokenToClipboard()
        }
        
        // Update progress bar
        progressBar?.doubleValue = otpCalc!.percentRemaining
    }
    

    
}
