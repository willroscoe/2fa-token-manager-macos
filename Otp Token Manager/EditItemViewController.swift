//
//  EditItemViewController.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/18.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

class EditItemViewController: NSViewController {

    public var otp_item: Otp?
    var share = DataContainerSingleton.sharedDataContainer
    
    @IBOutlet weak var issuerBox: NSTextField!
    @IBAction func clevelAction(_ sender: Any) {
    }
    @IBOutlet weak var clevelDD: NSPopUpButton!
    @IBOutlet weak var secretNotValidLabel: NSTextField!
    @IBOutlet weak var algorithmDD: NSPopUpButton!
    
    @IBAction func updateBtnAction(_ sender: NSButton) {
        // validate inputs
        
        var isValid = true
        
        // check issuer
        if (issuerBox.stringValue == "") {
            issuerBox.layer?.borderColor = NSColor.red.cgColor
            isValid = false
        }
        else {
            issuerBox.layer?.borderColor = CGColor.clear
        }
        
        // check name
        if (nameBox.stringValue == "") {
            nameBox.layer?.borderColor = NSColor.red.cgColor
            isValid = false
        }
        else {
            nameBox.layer?.borderColor = CGColor.clear
        }
        
        // check secret
        if (secretBox.stringValue == "") {
            secretBox.layer?.borderColor = NSColor.red.cgColor
            isValid = false
            secretNotValidLabel.isHidden = true
        }
        else {
            // validate seachet is base32
            let base32test = secretBox.stringValue.base32DecodedData
            if (base32test == nil) {
                secretBox.layer?.borderColor = NSColor.red.cgColor
                secretNotValidLabel.isHidden = false
                isValid = false
            }
            else {
                secretBox.layer?.borderColor = CGColor.white
                secretNotValidLabel.isHidden = true
            }
        }
        
        if (isValid) {
            
            //update the totp model with updated values
            otp_item?.algorithm = CryptoAlgorithm(rawValue: algorithmDD.titleOfSelectedItem!)!
            //otp_item?.name = nameBox.stringValue
            otp_item?.username = nameBox.stringValue
            otp_item?.secret = secretBox.stringValue
            otp_item?.issuer = issuerBox.stringValue
            
            if (clevelDD.titleOfSelectedItem == "Show") {
                otp_item?.clevel = 0
            } else {
                otp_item?.clevel = 1
            }
            
            // update shared object
            if (otp_item?.action == OtpAction.Add) {
                share.otp_items.append(otp_item!)
            } else if (otp_item?.action == OtpAction.Edit) {
                share.otp_items[(otp_item?.index!)!] = otp_item!
            }
            // sort items
            share.sort_otp_items()
            
            let firstViewController = presenting as! TokenListViewController
            firstViewController.editItemCallback(otp: otp_item!)
            self.dismiss(self)
        }
        
    }
    
    @IBAction func digitsAction(_ sender: NSSegmentedControl) {
        let clickedSegment = Int64(sender.selectedSegment)
        if (clickedSegment == 0) {
            if (otp_item?.digits == 8) {
                otp_item?.digits = 6
                digitsBox.integerValue = (otp_item?.digits)!
            }
        } else {
            if (otp_item?.digits == 6) {
                otp_item?.digits = 8
                digitsBox.integerValue = (otp_item?.digits)!
            }
        }
        
    }
    @IBAction func intervalAction(_ sender: NSSegmentedControl) {
        let clickedSegment = Int64(sender.selectedSegment)
        if (clickedSegment == 0) {
            if ((otp_item?.interval)! > 5) {
                otp_item?.interval -= 1
            } else {
                otp_item?.interval = 5
            }
            intervalBox.integerValue = (otp_item?.interval)!
        } else {
            if ((otp_item?.interval)! < 600) {
                otp_item?.interval += 1
            } else {
                otp_item?.interval = 600
            }
            intervalBox.integerValue = (otp_item?.interval)!
        }
    }
    @IBOutlet weak var digitsBox: NSTextField!
    @IBOutlet weak var intervalBox: NSTextField!
    @IBOutlet weak var secretBox: NSTextField!
    @IBOutlet weak var nameBox: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        InitialiseView()
        
    }
    
    
    func InitialiseView() {
        
        secretNotValidLabel.isHidden = true
        
        algorithmDD.removeAllItems()
        algorithmDD.addItems(withTitles: CryptoAlgorithm.allValues)
        algorithmDD.selectItem(withTitle: CryptoAlgorithm.SHA1.rawValue)
        
        clevelDD.removeAllItems()
        clevelDD.addItem(withTitle: "Show")
        clevelDD.addItem(withTitle: "Hide")
        clevelDD.selectItem(withTitle: "Show")
        
        nameBox.wantsLayer = true
        //let nameBoxLayer = CALayer()
        //nameBox.layer = nameBoxLayer
        nameBox.layer?.borderWidth = 2.0
        nameBox.layer?.borderColor = CGColor.white
        
        issuerBox.wantsLayer = true
        //let nameBoxLayer = CALayer()
        //nameBox.layer = nameBoxLayer
        issuerBox.layer?.borderWidth = 2.0
        issuerBox.layer?.borderColor = CGColor.white
        
        
        secretBox.wantsLayer = true
        //let secretBoxLayer = CALayer()
        //secretBox.layer = secretBoxLayer
        secretBox.layer?.borderColor = CGColor.white
        secretBox.layer?.borderWidth = 2.0
        
        UpdateForm()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
    }
    
    func UpdateForm() {
        if (otp_item != nil) {
            issuerBox.stringValue = (otp_item?.issuer)!
            nameBox.stringValue = (otp_item?.username)!
            secretBox.stringValue = (otp_item?.secret)!
            digitsBox.integerValue = (otp_item?.digits)!
            intervalBox.integerValue = (otp_item?.interval)!
            algorithmDD.selectItem(withTitle: (otp_item?.algorithm.rawValue)!)
            
            if (otp_item?.clevel == 0) {
                clevelDD.selectItem(withTitle: "Show")
            } else {
                clevelDD.selectItem(withTitle: "Hide")
            }
            
        }
    }

}
