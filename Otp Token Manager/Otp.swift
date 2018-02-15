//
//  Totp.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/11.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Foundation

enum OtpAction {
    case Add
    case Edit
}

enum OptType: String {
    case TOTP
    case HOTP
}

class Otp: NSObject {
    public var issuer: String = ""
    //public var name: String = ""
    public var username: String = ""
    public var algorithm: CryptoAlgorithm = CryptoAlgorithm.SHA1
    public var secret: String = ""
    public var digits: Int = 6
    public var interval: Int = 30
    public var action:OtpAction?
    public var type:OptType = OptType.TOTP
    public var clevel:Int = 0
    public var index:Int?
    
    public override init() {
        super.init()
    }
    
    public init?(algorithm: CryptoAlgorithm, username: String, secret: String, digits: Int = 6, interval: Int = 30, type: OptType = OptType.TOTP, clevel: Int = 0, issuer:String = "") {
        self.issuer = issuer
        self.algorithm = algorithm
        self.username = username
        //self.name = name
        self.secret = secret
        self.digits = digits
        self.interval = interval
        self.type = type
        self.clevel = clevel
        super.init()
    }
    
    
    public func toJSON() -> [String : Any] {
        var dictionary: [String : Any] = [:]
        dictionary["issuer"] = self.issuer
        dictionary["username"] = self.username
        //dictionary["name"] = self.name
        dictionary["secret"] = self.secret
        dictionary["digits"] = self.digits
        dictionary["interval"] = self.interval
        dictionary["algorithm"] = self.algorithm.rawValue
        dictionary["type"] = self.type.rawValue
        dictionary["clevel"] = self.clevel
        
        return dictionary
    }
    
    
    public func GenerateToken() -> (OtpResult) {
    
        let secretData = secret.base32DecodedData
        
        let timings = CalcTimings()
        var bigCounter = timings.c.bigEndian
        
        let counterData = Data(bytes: &bigCounter, count: MemoryLayout<UInt64>.size)
        
        let hash = counterData.hmac(algorithm: algorithm, keyData: secretData!)
        
        
        var truncatedHash = hash.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> UInt32 in
            // Use the last 4 bits of the hash as an offset (0 <= offset <= 15)
            let offset = ptr[hash.count - 1] & 0x0f
            
            // Take 4 bytes from the hash, starting at the given byte offset
            let truncatedHashPtr = ptr + Int(offset)
            return truncatedHashPtr.withMemoryRebound(to: UInt32.self, capacity: 1) {
                $0.pointee
            }
        }
        
        // Ensure the four bytes taken from the hash match the current endian format
        truncatedHash = UInt32(bigEndian: truncatedHash)
        // Discard the most significant bit
        truncatedHash &= 0x7fffffff
        // Constrain to the right number of digits
        truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))
        
        
        // Pad the string representation with zeros, if necessary
        //return String(truncatedHash).padded(with: "0", toLength: digits)
        
        var baseToken:String = String(truncatedHash).padded(with: "0", toLength: digits)
        baseToken.insert(" ", at: baseToken.index(baseToken.startIndex, offsetBy: 3))
        
        let result = OtpResult(Token: baseToken, From: timings.From, To: timings.To, Remaining: timings.Remaining, Name: self.username, percentRemaining: timings.percentRemaining)
        
        return(result)
        
    }
    
    public func CalcTimings() -> (TotpTiming) {
        
        let now: Date = Date()
        
        let c = Int64(now.timeIntervalSince1970) / Int64(interval)
        let startDate = Date(timeIntervalSince1970: TimeInterval(c * Int64(interval)))
        let endDate = startDate.addingTimeInterval(TimeInterval(interval))
        
        let secondsRemaining = endDate.timeIntervalSinceNow
        let percentRemaining = (secondsRemaining / Double(interval)) * 100
        
        return(TotpTiming(From: startDate, To: endDate, Remaining: Int(secondsRemaining), c: UInt64(c), percentRemaining: percentRemaining ))
    }
    
}
