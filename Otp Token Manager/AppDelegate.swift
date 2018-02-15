//
//  AppDelegate.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/09.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var prefsMenuItem: NSMenuItem!

    //@IBOutlet weak var newMenuItem: NSMenuItem!
    @IBOutlet weak var saveMenuItem: NSMenuItem!
    
    //@IBOutlet weak var saveAsMenuItem: NSMenuItem!
    
    @IBOutlet weak var changePasswordMenuItem: NSMenuItem!
    
    //let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        //statusItem.image = icon
        /*statusItem.title = "OPT"
        statusItem.highlightMode = false
        statusItem.toolTip = "2FA OTP token Manager"*/
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func enableMenus(new:Bool, save: Bool, saveAs: Bool, changePassord: Bool, prefs: Bool) {
        //newMenuItem.isEnabled = new
        saveMenuItem.isEnabled = save
        //saveAsMenuItem.isEnabled = saveAs
        changePasswordMenuItem.isEnabled = changePassord
        prefsMenuItem.isEnabled = prefs
    }
    
    func hideMenus(new:Bool = true, save: Bool = true, saveAs: Bool = true, changePassord: Bool = true, prefs: Bool = true) {
        //newMenuItem.isHidden = new
        saveMenuItem.isHidden = save
        //saveAsMenuItem.isHidden = saveAs
        changePasswordMenuItem.isHidden = changePassord
        prefsMenuItem.isHidden = prefs
    }


}

