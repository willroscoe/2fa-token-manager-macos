//
//  Crypto.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/11.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Foundation

enum CryptoAlgorithm:String {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    static let allValues:[String] = [MD5.rawValue, SHA1.rawValue, SHA224.rawValue, SHA256.rawValue, SHA384.rawValue, SHA512.rawValue] // for popup input
    
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}


class Crypto {
    
    let Crypto_KeyBitSize = 256
    let Crypto_SaltBitSize = 64
    let Crypto_Iterations = 10000
    
    
    // https://stackoverflow.com/documentation/swift/7053/pbkdf2-key-derivation/23715/password-based-key-derivation-2-swift-3#t=201610052358224458869
    
    func pbkdf2SHA1(password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        return pbkdf2(hash:CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1), password:password, salt:salt, keyByteCount:keyByteCount, rounds:rounds)
    }
    
    func pbkdf2SHA256(password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        return pbkdf2(hash:CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256), password:password, salt:salt, keyByteCount:keyByteCount, rounds:rounds)
    }
    
    func pbkdf2SHA512(password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        return pbkdf2(hash:CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512), password:password, salt:salt, keyByteCount:keyByteCount, rounds:rounds)
    }
    
    func pbkdf2(hash :CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
        let passwordData = password.data(using:String.Encoding.utf8)!
        var derivedKeyData = Data(repeating:0, count:keyByteCount)
        
        let derivationStatus = derivedKeyData.withUnsafeMutableBytes {derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password, passwordData.count,
                    saltBytes, salt.count,
                    hash,
                    UInt32(rounds),
                    derivedKeyBytes, derivedKeyData.count)
            }
        }
        if (derivationStatus != 0) {
            print("Error: \(derivationStatus)")
            return nil;
        }
        
        return derivedKeyData
    }
    
    
    
    func EncryptWithPassword(message:String, password:String, verbose:Bool) throws -> String {
        
        let nonSecretPayloadLength = 0;
        var payload:Data
        
        // Use Random Salt to prevent pre-generated weak password attacks.
        // generate cryptSalt and cryptKey
        var cryptSalt = Data(count: Crypto_SaltBitSize/8)
        let cryptSaltResult = cryptSalt.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, cryptSalt.count, mutableBytes)
        }
        if (cryptSaltResult != 0) {
            throw AESError.KeyError(("cryptSalt generation failed", Int(cryptSaltResult)))
        }

        let cryptKey = Crypto().pbkdf2SHA1(password:password, salt:cryptSalt, keyByteCount:Crypto().Crypto_KeyBitSize / 8, rounds:Crypto_Iterations)
        
        
        // Create Non Secret Payload
        payload = cryptSalt
        var payloadIndex = payload.count
        
        // generate AuthSalt and AuthKey
        var authSalt = Data(count: Crypto_SaltBitSize/8)
        let authSaltResult = authSalt.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, authSalt.count, mutableBytes)
        }
        if (authSaltResult != 0) {
            throw AESError.KeyError(("authSalt generation failed", Int(authSaltResult)))
        }
        
        let authKey = Crypto().pbkdf2SHA1(password:password, salt:authSalt, keyByteCount:Crypto().Crypto_KeyBitSize / 8, rounds:Crypto_Iterations)
        
        
        // Create Rest of Non Secret Payload
        payload += authSalt
        
        // User Error Checks
        if (cryptKey == nil || cryptKey?.count != (Crypto_KeyBitSize / 8)) {
            print("cryptKey needs to be \(Crypto_KeyBitSize) bit!")
        }
        if (authKey == nil || authKey?.count != (Crypto_KeyBitSize / 8)) {
            print("authKey needs to be \(Crypto_KeyBitSize) bit!")
        }
        if (message.characters.count < 1) {
            print("Secret Data Required!")
        }
        
        
        // generate random iv
        var iv = Data(count: kCCBlockSizeAES128)
        let ivResult = iv.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, iv.count, mutableBytes)
        }
        if (ivResult != 0) {
            throw AESError.IVError(("iv generation failed", Int(ivResult)))
        }
        
        if verbose {
            print("cryptSalt: \(Data(cryptSalt).base32EncodedString)")
            print("authSalt: \(Data(authSalt).base32EncodedString)")
            print("cryptKey: \(Data(cryptKey!).base32EncodedString)")
            print("authKey: \(Data(authKey!).base32EncodedString)")
            print("payload: \(Data(payload).base32EncodedString)")
            print("iv: \(Data(iv).base32EncodedString)")
        }
        
        // encrypt message
        let encryptedText = try? AES_CBC_Crypt(operation:CCOperation(kCCEncrypt), message: message.data(using:String.Encoding.ascii)!, iv: iv, cryptKey:cryptKey!)
        
        //  assemble encrypted message and add authentication
        //  payload makeup: nonSecretPayload + cryptSalt + authSalt
        let data = payload + iv + encryptedText!
        
        let sig = data.hmac(algorithm: .SHA256, keyData: authKey!)
        
        //  end
        let EncodeMsg = (data + sig).base64EncodedString()
        
        if verbose {
            print("encryptedText: \(Data(encryptedText!).base32EncodedString)")
            print("data: \(Data(data).base32EncodedString)")
            print("sig: \(Data(sig).base32EncodedString)")
            print("")
            print("EncodeMsg: \(EncodeMsg)")
        }
        
        return EncodeMsg
        
    }
    
    
    
    func DecryptWithPassword(message:String, password:String, verbose:Bool) throws -> DecryptResult {
        
        let nonSecretPayloadLength = 0;
        
        if let decodedData = NSData(base64Encoded: message as String, options:NSData.Base64DecodingOptions(rawValue: 0)),
            
            let decodedString = NSString(data: decodedData as Data, encoding: String.Encoding.ascii.rawValue) {
            //print(decodedString)
            
            // Grab Salts from Non-Secret Payload
            
            let cryptSalt = decodedData.subdata(with: NSRange(nonSecretPayloadLength..<nonSecretPayloadLength + (Crypto_SaltBitSize / 8)))
            
            let authSalt = decodedData.subdata(with: NSRange(nonSecretPayloadLength + cryptSalt.count..<nonSecretPayloadLength + cryptSalt.count + (Crypto_SaltBitSize / 8)))
            
            if verbose {
                print("cryptSalt: \(Data(cryptSalt).base32EncodedString)")
                print("authSalt: \(Data(authSalt).base32EncodedString)")
            }
            
            // Generate crypt & auth keys
            
            let cryptKey = Crypto().pbkdf2SHA1(password:password, salt:cryptSalt, keyByteCount:Crypto().Crypto_KeyBitSize / 8, rounds:Crypto_Iterations)
            
            let authKey = Crypto().pbkdf2SHA1(password:password, salt:authSalt, keyByteCount:Crypto().Crypto_KeyBitSize / 8, rounds:Crypto_Iterations)
            
            if verbose {
                print("cryptKey: \(cryptKey!.base32EncodedString)")
                print("authKey: \(authKey!.base32EncodedString)")
            }
            
            // check key lengths are valid
            let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
            
            let authKeyLength = authKey?.count
            if (validKeyLengths.contains(authKeyLength!) == false) {
                //throw Crypto.AESError.KeyError(("authKey: Invalid key length", authKeyLength!))
                return DecryptResult(string: nil, error: "Encryption key (a) failed", authFailed: false, success: false)
            }
            
            let cryptKeyLength = cryptKey?.count
            if (validKeyLengths.contains(cryptKeyLength!) == false) {
                //throw Crypto.AESError.KeyError(("cryptKey: Invalid key length", cryptKeyLength!))
                return DecryptResult(string: nil, error: "Encryption key (c) failed", authFailed: false, success: false)
            }
            
            
            let nonSecretPayloadLengthIncSalts = nonSecretPayloadLength + cryptSalt.count + authSalt.count
            
            // Check message authentication
            // Calculate Signature hash, and check they match
            
            let calcData = decodedData.subdata(with: NSRange(0..<(decodedData.length - (Crypto_KeyBitSize / 8))))
            let calcTag = calcData.hmac(algorithm: .SHA256, keyData: authKey!)
            
            if verbose {
                print("calcTag: \(calcTag.base32EncodedString)")
            }
            
            // Grab Sent Tag - i.e. Signature hash that is included in the message
            
            let sentTag = decodedData.subdata(with: NSRange(decodedData.length - (Crypto_KeyBitSize / 8)..<decodedData.length))
            if verbose {
                print("sentTag: \(sentTag.base32EncodedString)")
            }
            
            if (sentTag.base32EncodedString != calcTag.base32EncodedString)
            {
                print("Data failed authentication!")
                return DecryptResult(string: nil, error: "Data failed authentication!", authFailed: true, success: false)
            }
            
            // Grab iv from message
            let ivLength = kCCBlockSizeAES128
            let iv = decodedData.subdata(with: NSRange(nonSecretPayloadLengthIncSalts..<nonSecretPayloadLengthIncSalts + ivLength))
            
            if verbose {
                print("ivLength: \(ivLength)")
                print("iv: \(iv.base32EncodedString)")
            }
            
            // get the encrypted message data - so we can decrypt it
            let message_section_data = decodedData.subdata(with: NSRange(nonSecretPayloadLengthIncSalts + ivLength..<(decodedData.length - (Crypto_KeyBitSize / 8))))
            
            // decrypt message
            let jsonString = try? AES_CBC_Crypt_String(operation:CCOperation(kCCDecrypt), message: message_section_data, iv: iv, cryptKey:cryptKey!)
            
            return DecryptResult(string: jsonString, error: nil, authFailed: false, success: true)
            
        }
        
        return DecryptResult(string: nil, error: "Data file corrupted", authFailed: false, success: false)
    }
    
    private func AES_CBC_Crypt(operation:CCOperation, message:Data, iv:Data, cryptKey:Data) throws -> Data {
        
        let outputLength = size_t(message.count + kCCBlockSizeAES128)
        var outputData = Data(count:outputLength)
        
        var numBytesCrypted :size_t = 0
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        let ivUnsafe = iv.withUnsafeBytes { UnsafePointer<UInt8>($0) }
        
        let cryptStatus = outputData.withUnsafeMutableBytes {outputBufferBytes in
            message.withUnsafeBytes {inputBytes in
                cryptKey.withUnsafeBytes {cryptKeyBytes in
                    CCCrypt(operation,    // operation: kCCEncrypt or kCCDecrypt
                        CCAlgorithm(kCCAlgorithmAES128), // algorithm: kCCAlgorithmAES128...
                        options,                    // options
                        cryptKeyBytes,              // key
                        cryptKey.count,             // key length
                        ivUnsafe,                   // initialization vector
                        inputBytes,                 // input data
                        message.count,              // input data length
                        outputBufferBytes,          // output data buffer
                        outputLength,               // output data length available
                        &numBytesCrypted            // real output data length generated
                    )
                }
            }
        }
        
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            outputData.count = numBytesCrypted
        }
        else {
            throw AESError.CryptorError(("Cryption failed", Int(cryptStatus)))
        }
        
        return outputData
        //let result = String(data: clearData as Data, encoding: String.Encoding(rawValue: String.Encoding.ascii.rawValue))
        
        //return result!
    }
    
    private func AES_CBC_Crypt_String(operation:CCOperation, message:Data, iv:Data, cryptKey:Data) throws -> String {
        
        //let clearLength = size_t(message.count)
        //var clearData = Data(count:clearLength)
        
        let result = try? AES_CBC_Crypt(operation:operation, message: message, iv: iv, cryptKey:cryptKey)
        
        let stringresult = String(data: result!, encoding: String.Encoding(rawValue: String.Encoding.ascii.rawValue))
        
        return stringresult!
        
    }
    
    enum AESError: Error {
        case KeyError((String, Int))
        case IVError((String, Int))
        case CryptorError((String, Int))
    }
    
}
