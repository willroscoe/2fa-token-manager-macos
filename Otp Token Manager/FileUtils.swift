//
//  FileUtils.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/17.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Foundation

class FileUtils {
    
    
    /*--------------------
     LOAD FUNCTIONS
     - - - - - - - - - - */
    
    public func GetDatafilePath() -> URL? {
        
        var tmpsdf = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        
        if let pathURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        {
            return pathURL.appendingPathComponent("2fa_otp.otp");
        }
        
        return nil;
    }
    
    public func ConvertStringToOtpArray(plainString:String) -> [Otp] {
        
        let json_array = ConvertStringToJsonObject(plainString: plainString)
        
        return SerialiseJsonObjectToOtpObject(json_array: json_array)
        
    }
    
    
    public func ConvertStringToJsonObject(plainString:String) -> [[String:Any]] {
        
        let jsonData = plainString.data(using: .ascii)!
        
        let parsedJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as! [String:Any]
        
        let json_items = parsedJson?["data"] as! [[String:Any]] // cast to Array
        
        let json_items_sorted = SortJsonObject(json_items: json_items)
        
        //print(json_items_sorted)
        
        return json_items_sorted
        
    }

    
    public func SortOtpArray(otp_items: [Otp]) -> [Otp] {
        return otp_items.sorted(by: { $0.username > $1.username })
    }
    
    
    public func DeserialiseOtpArrayToJsonString(otp_items: [Otp]) -> String {
        let otp_items = SortOtpArray(otp_items: otp_items)
        
        var jsonresult:[String:Any]?
        
        var json_items:[Any] = []
        for item in otp_items {
            json_items.append(item.toJSON())
        }
        json_items = FileUtils().SortJsonObject(json_items: json_items as! [[String : Any]])
        
        jsonresult = ["data" : json_items]
        
        return JSONStringify(value: jsonresult as AnyObject)
    }
    
    
    func JSONStringify(value: AnyObject, prettyPrinted:Bool = false) -> String{
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions.init(rawValue: 0)
        
        
        if JSONSerialization.isValidJSONObject(value) {
            do{
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                if let string = String(data: data, encoding: .ascii ) {
                    return string as String
                }
            } catch {
                print("error")
            }
            
        }
        return ""
        
    }
    
    
    public func SortJsonObject(json_items: [[String:Any]]) -> [[String:Any]] {
        return json_items.sorted
            {
                ($0["username"] as! String).localizedCaseInsensitiveCompare($1["username"] as! String) == ComparisonResult.orderedAscending
        }
    }
    
    
    public func SerialiseJsonObjectToOtpObject(json_array:[[String:Any]]) -> [Otp] {
        var results:[Otp] = []
        for item in json_array {
            var algor:CryptoAlgorithm = .SHA1
            if let algorHolder = item["algorithm"] {
                algor = CryptoAlgorithm(rawValue: algorHolder as! String)! // convert string to enum
            }
            var interval:Int = 30
            if let intervalHolder = item["interval"] {
                interval = intervalHolder as! Int
            }
            var type:OptType = OptType.TOTP
            if let typeHolder = item["type"] {
                type = OptType(rawValue : typeHolder as! String)! // convert string to enum
            }
            var clevel:Int = 0
            if let clevelHolder = item["clevel"] {
                clevel = clevelHolder as! Int
            }
            var issuer:String = ""
            if let issuerHolder = item["issuer"] {
                issuer = issuerHolder as! String
            }
            
            /*var name:String = ""
            if let nameHolder = item["name"] {
                name = nameHolder as! String
            }*/
            var username:String = ""
            if let usernameHolder = item["username"] {
                username = usernameHolder as! String
            }

            
            results.append(Otp(algorithm: algor, username: username, secret: item["secret"] as! String, digits: item["digits"] as! Int, interval: interval, type: type, clevel: clevel, issuer: issuer )!)
        }
        
        return results
    }

    
    public func SaveDataFile(data: String) -> Bool {
        
        var url = GetDatafilePath();
        do {
            try data.write(to: url!, atomically: true, encoding: .ascii)
            return true
        } catch {
            print("Failed writing to URL: \(url), Error: " + error.localizedDescription)
            
        }
        return false
        
    }
    
    
    public func LoadDataFile() -> StringResult {
        
        var url = GetDatafilePath();
        var inString = ""
        do {
            inString = try String(contentsOf: url!)
            //txtBox.string = inString;
            return StringResult(string: inString, error: nil, success: true)
        } catch {
            //print("Failed reading from URL: \(url), Error: " + error.localizedDescription)
            //return StringResult(string: nil, error: error.localizedDescription, success: false)
            
        }
        return StringResult(string: inString, error: nil, success: true)
        //return StringResult(string: nil, error: nil, success: false)
        
    }
    
}
