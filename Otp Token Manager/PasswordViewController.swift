//
//  LoginViewController.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/16.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

class PasswordViewController: NSViewController {
    
    var share = DataContainerSingleton.sharedDataContainer
    var prefs = Preferences()
    var action_setpassword:Bool = false
    var action_dosaveas:Bool = false
    var action_for_change_password:Bool = false
    var action_screen_protect:Bool = false
    let min_password_length = 6 // should be 15
    
    @IBOutlet weak var infoLabel: NSTextField!
    
    
    @IBAction func goBtnAction(_ sender: Any) {
        
        let travel_mode_chars = prefs.travel_mode_chars
        infoLabel.isHidden = true
        infoLabel.stringValue = ""
        var returnTitle = ""
        var returnMsg = ""
        var returnShowMsg = false
        var ok2dismiss = true
        
        if (share.screen_protect) {
            action_screen_protect = true
            if (passwordTxt.stringValue == share.passphrase) {
                share.screen_protect = false
                ok2dismiss = true
            } else {
                infoLabel.stringValue = "Password is incorrect"
                infoLabel.isHidden = false
                ok2dismiss = false
            }
        } else if (action_setpassword) {
            if (passwordTxt.stringValue != "") {
                if (passwordTxt.stringValue.characters.count >= min_password_length) {
                    share.passphrase = passwordTxt.stringValue
                    infoLabel.isHidden = true
                } else {
                    infoLabel.stringValue = "Password must be > \(min_password_length) chars"
                    infoLabel.isHidden = false
                    ok2dismiss = false
                }
            } else {
                infoLabel.stringValue = "Password required."
                infoLabel.isHidden = false
                ok2dismiss = false
            }
        } else if (!(share.encrypted_data ?? "").isEmpty && passwordTxt.stringValue != "") {
            
            var tmpPW:String = passwordTxt.stringValue
            if (tmpPW.hasSuffix(travel_mode_chars)) {
                share.travel_mode = true
                share.passphrase = tmpPW.substring(with: tmpPW.startIndex..<tmpPW.characters.index(tmpPW.endIndex, offsetBy: -travel_mode_chars.characters.count))
            } else {
                share.passphrase = passwordTxt.stringValue
                share.travel_mode = false
            }
            
            do {
                let decrypt_data = try Crypto().DecryptWithPassword(message:share.encrypted_data!, password:share.passphrase!, verbose: false)
                
                if (decrypt_data.success) {
                    share.plain_data = decrypt_data.string
                }
                else {
                    share.plain_data = nil
                    if (decrypt_data.authFailed) {
                        ok2dismiss = false
                        infoLabel.stringValue = "Authentication failed. Please re-type your password."
                        infoLabel.isHidden = false
                    }
                    returnTitle = "Data Error"
                    returnMsg = decrypt_data.error!
                    returnShowMsg = true
                }
            }
            catch (let status) {
                print("Error decrypting data: \(status)")
            }
        }
        
        if (ok2dismiss) {
            
            let firstViewController = presenting as! TokenListViewController
            if (action_screen_protect) {
                firstViewController.screenprotectCallback()
            } else if (action_setpassword) {
                firstViewController.setpasswordCallback(do_save_as: action_dosaveas, for_change_password: action_for_change_password)
            } else {
                firstViewController.unlockCallback(showMsg: returnShowMsg, title:returnTitle, msg: returnMsg)
            }
            action_setpassword = false // reset
            action_for_change_password = false
            infoLabel.isHidden = true // reset
            passwordTxt.stringValue = ""
            self.dismissViewController(self)
        }
    }
    
    @IBOutlet weak var goBtn: NSButton!
    @IBOutlet weak var passwordTxt: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.isHidden = true
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        infoLabel.stringValue = ""
        infoLabel.isHidden = true
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}
