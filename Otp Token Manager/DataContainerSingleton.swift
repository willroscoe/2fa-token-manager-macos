//
//  DataContainerSingleton.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/16.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Foundation

class DataContainerSingleton {
    
    static let sharedDataContainer = DataContainerSingleton()
    
    var travel_mode:Bool = false
    var screen_protect:Bool = false
    var screen_protect_timeout:TimeInterval = 90
    //var file_url: URL?
    var passphrase: String?
    var otp_items: [Otp] = []
    var encrypted_data: String?
    var plain_data: String? {
        didSet {
            if !(plain_data ?? "").isEmpty {
                otp_items = FileUtils().ConvertStringToOtpArray(plainString: plain_data!)
            } else {
                otp_items = []
            }
        }
    }
    
    func do_travel_mode(level:Int = 1) {
        var results: [Otp] = []
        for item in otp_items {
            if (item.clevel < level) { // only allow items below the level
                results.append(item)
            }
        }
        otp_items = results
    }
    
    func sort_otp_items() {
        if (otp_items.count > 1) {
            otp_items =  otp_items.sorted(by: { $0.username < $1.username })
        }
    }
    
    func reset() {
        screen_protect = false
        //file_url = nil
        passphrase = nil
        otp_items = []
        encrypted_data = nil
        plain_data = nil
    }
}
