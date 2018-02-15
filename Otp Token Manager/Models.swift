//
//  Models.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/11.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Foundation

struct OtpResult {
    let Token: String
    let From: Date
    let To: Date
    let Remaining: Int
    let Name: String
    let percentRemaining: Double
}

struct TotpTiming {
    let From: Date
    let To: Date
    let Remaining: Int
    let c: UInt64
    let percentRemaining: Double
}

struct StringResult {
    let string:String?
    let error:String?
    var success:Bool = false
}

struct DecryptResult {
    let string:String?
    let error:String?
    var authFailed:Bool = false
    var success:Bool = false
}

struct Preferences {
    
    var screen_protect_timeout: TimeInterval {
        get {
            let savedTime = UserDefaults.standard.double(forKey: "screen_protect_timeout")
            if savedTime > 0 {
                return savedTime
            }
            return 60 // default
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "screen_protect_timeout")
        }
    }
    
    var travel_mode_chars: String {
        get {
            let _travelmodechars = UserDefaults.standard.string(forKey: "travel_mode_chars")
            if (!(_travelmodechars ?? "").isEmpty) {
                return _travelmodechars!
            }
            return "*tm" // default
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "travel_mode_chars")
        }
    }
    
}
