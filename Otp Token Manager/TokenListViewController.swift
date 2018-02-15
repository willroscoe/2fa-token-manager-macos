//
//  ViewController.swift
//  Totp Token Manager
//
//  Created by William Roscoe on 2017/05/09.
//  Copyright © 2017 William Roscoe. All rights reserved.
//

import Cocoa

class TokenListViewController: NSViewController {

    @IBOutlet weak var qrCodeBtn: NSButton!
    var share = DataContainerSingleton.sharedDataContainer
    var prefs = Preferences()
    let userDefaults = UserDefaults.standard
    var selectedIndex:Int?
    var action_do_save_as: Bool = false
    var action_for_change_password: Bool = false
    private var screen_protect_timer: Timer? = nil
    
    @IBOutlet weak var addBtn: NSButton!
    @IBOutlet weak var deleteBtn: NSButton!
    @IBOutlet weak var editBtn: NSButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    @IBAction func qrCodeBtnAction(_ sender: Any) {
        
    }
    @IBAction func addBtnAction(_ sender: Any) {
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "addItemSegue"), sender: self)
    }
    
    @IBAction func deleteBtnAction(_ sender: Any) {
        // confirm delete first
        
        if ((selectedIndex != nil) && (share.otp_items.count > 0)) {
            
            let item = share.otp_items[selectedIndex!]
            
            let message = item.issuer + " " + item.username
            if (dialogOKCancel(title: "Are you sure you want to delete this?", msg: message, cancel: true)) {
                // delete item
                share.otp_items.remove(at: selectedIndex!)
                selectedIndex = nil
                UpdateBtns(enable: false)
                collectionView.reloadData()
                TryStartScreenProtectTimer()
            }
        }
    }
    
    @IBAction func editBtnAction(_ sender: Any) {
        if (selectedIndex != nil) {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "editItemSegue"), sender: self)
        }
    }
    
    /*
    @IBAction func NewMenuAction(_ sender: Any) {
        screen_protect_timer?.invalidate()
        share.reset()
        selectedIndex = nil
        UpdateBtns(enable: false)
        collectionView.reloadData()
    }*/
    
    /*@IBAction func OpenMenuAction(_ sender: Any) { // this is connected via the manual first responder attributes
        // first reset all totp tokens
        share.otp_items = []
        collectionView.reloadData()
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["dat"]
        if (openPanel.runModal() == NSModalResponseOK) {
            for fileitem in openPanel.urls {
                //share.filepath = fileitem.absoluteString
                share.file_url = fileitem.absoluteURL
            }
        }
        
        if (share.file_url != nil) {
            userDefaults.set(share.file_url, forKey: "fileurl")
            // try and load data
            LoadDataFileThenUnlock(url: share.file_url!)
        }
    }*/

    @IBAction func SaveMenuAction(_ sender: Any) { // this is connected via the manual first responder attributes
        
        SaveData()
    }
    
    /*@IBAction func SaveAsMenuAction(_ sender: Any) { // this is connected via the manual first responder attributes
        
        SaveData(saveas: true)
    }*/
    
    @IBAction func ChangePasswordMenuAction(_ sender: Any) { // this is connected via the manual first responder attributes
        if (share.screen_protect) {
            dialogOKCancel(title: "Screen Protect: Change Password is currently disabled", msg: "", cancel: false, cancelTitle: "", alertType: NSAlert.Style.critical)
        } else {
            action_do_save_as = false
            action_for_change_password = true
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "setPasswordSegue"), sender: self)
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        share.screen_protect_timeout = prefs.screen_protect_timeout
        
        TravelMode(set: true)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isSelectable = true
        scrollView.borderType = .lineBorder
        
        UpdateBtns(enable: false)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // try and automatically load data file
        /*if let url = userDefaults.url(forKey: "fileurl") {
            share.file_url = url
            LoadDataFileThenUnlock(url: url, atappstart: true)
        }*/
        
        LoadDataFileThenUnlock(atappstart: true)
        
    }
    
    override func viewWillDisappear() {
        // check if there is any unsaved data
        
        let dataToEncrypt = FileUtils().DeserialiseOtpArrayToJsonString(otp_items: share.otp_items)
        
        if (dataToEncrypt != share.plain_data && !share.screen_protect && share.otp_items.count > 0 && !share.travel_mode) {
            if (dialogOKCancel(title: "You have unsaved data", msg: "Do you want to save it now?", cancel: true, cancelTitle: "No")) {
                // save data
                SaveData()
            }
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
         
        }
    }
    
    
    func TryStartScreenProtectTimer() {
        
        screen_protect_timer?.invalidate()
        if (share.passphrase != nil && !share.screen_protect) {
            if ((share.passphrase?.characters.count)! > 0) {
                screen_protect_timer = Timer.scheduledTimer(timeInterval: share.screen_protect_timeout,
                                    target: self,
                                    selector: (#selector(self.ScreenProtectionTimeout)),
                                    userInfo: nil,
                                    repeats: false)
            }
        }
        
    }
    
    @objc func ScreenProtectionTimeout() {
        // 
        screen_protect_timer?.invalidate()
        if (share.otp_items.count > 0) {
            share.screen_protect = true
            if (selectedIndex != nil) {
                var indexes:Set<IndexPath> = Set<IndexPath>()
                indexes.insert(IndexPath(item: selectedIndex!, section: 0))
                collectionView.deselectItems(at: indexes)
            }
            UpdateBtns(enable: false)
            
            // update menu items
            if let appDel = NSApplication.shared.delegate as? AppDelegate {
                appDel.enableMenus(new: true, save: false, saveAs: false, changePassord: false, prefs: false)
            }
            
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "screenProtectSegue"), sender: self)
        }

    }
    
    func TravelMode(set:Bool) {
        if (set) {
            editBtn.isHidden = true
            qrCodeBtn.isHidden = true
            if let appDel = NSApplication.shared.delegate as? AppDelegate {
                appDel.hideMenus(new: true, save: false, saveAs: true, changePassord: true, prefs: true)
            }

        } else {
            editBtn.isHidden = false
            qrCodeBtn.isHidden = false
            if let appDel = NSApplication.shared.delegate as? AppDelegate {
                appDel.hideMenus(new: false, save: false, saveAs: false, changePassord: false, prefs: false)
            }

        }
    }
    
    /*---------------------------
       LOAD & SAVE FUNCTIONS
     - - - - - - - - - - - - - */
    
    func LoadDataFileThenUnlock(atappstart:Bool = false) {
        let data = FileUtils().LoadDataFile()
        
        //if (data.success) { // go to unlock view
            share.encrypted_data = data.string
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "unlockSegue"), sender: self)
        /*}
        else
        {
            share.file_url = nil
            if (atappstart) {
                var detail = "Oops! The file did not open."
                if (data.error != nil) {
                    detail = data.error!
                }
                dialogOKCancel(title: "File Error", msg: detail)
            }
            TryStartScreenProtectTimer()
        }*/
    }
    
    
    /*func SaveAsPanel() -> Bool {
        let savePanel = NSSavePanel()
        
        // this is a preferred method to get the desktop URL
        savePanel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        savePanel.title = "Save As"
        savePanel.message = "Select where you want to save the data file."
        savePanel.nameFieldStringValue = "2fa_otp.dat"
        savePanel.showsHiddenFiles = false
        savePanel.showsTagField = false
        savePanel.canCreateDirectories = true
        savePanel.allowsOtherFileTypes = false
        savePanel.isExtensionHidden = false
        
        if let url = savePanel.url, savePanel.runModal() == NSFileHandlingPanelOKButton {
            share.file_url = url.absoluteURL
            return true
            
        } else {
            print("SaveAs canceled")
        }
        return false
    }*/
    
    func SaveData(saveas:Bool = false, for_change_password: Bool = false) {
        
        action_do_save_as = saveas // action used in the segue to the password controller
        action_for_change_password = for_change_password
        
        // first check there is a password set
        if (!share.travel_mode) { // don't save anything in travel mode
            
            if (share.screen_protect) {
                dialogOKCancel(title: "Screen Protect: Save is currently disabled", msg: "", cancel: false, cancelTitle: "", alertType: NSAlert.Style.critical)
            } else if (share.passphrase != nil) {
                
                let dataToEncrypt = FileUtils().DeserialiseOtpArrayToJsonString(otp_items: share.otp_items)
                
                // encrypt data
                if let encryptedData = try? Crypto().EncryptWithPassword(message: dataToEncrypt, password: share.passphrase!, verbose: false) {
                    
                    // save to file
                    if (FileUtils().SaveDataFile(data: encryptedData)) {
                        // saved ok
                        var dialog_title = "Success. Data saved Ok"
                        var dialog_msg = ""//"Location: " + share.file_url!.absoluteString
                        
                        if (for_change_password) {
                            dialog_title = "Password updated"
                            dialog_msg = ""
                        } else {
                            share.plain_data = dataToEncrypt
                        }
                        if (!saveas || for_change_password) {
                            dialogOKCancel(title: dialog_title, msg: dialog_msg, cancel: false, cancelTitle: "", alertType: NSAlert.Style.informational)
                        }
                        
                    } else {
                        // save error
                        dialogOKCancel(title: "Error: The data was not saved", msg: "", cancel: false, cancelTitle: "", alertType: NSAlert.Style.critical)
                    }
                } else {
                    dialogOKCancel(title: "Error: There was a problem encrypting the data", msg: "", cancel: false, cancelTitle: "", alertType: NSAlert.Style.critical)
                }
                
                
            } else {
                // send to password controller
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "setPasswordSegue"), sender: self)
            }
        }
        TryStartScreenProtectTimer()
    }
    
    /* - - - - - - - - - - - -
       LOAD & SAVE FUNCTIONS
     ------------------------*/

    
    /*------------------
       SEGUE FUNCTIONS
     - - - - - - - - - */
    
    func unlockCallback(showMsg: Bool, title:String, msg:String)
    {
        if (showMsg) {
            dialogOKCancel(title: title, msg:msg)
        }
        if (share.travel_mode) {
            TravelMode(set: true)
            share.do_travel_mode()
        } else {
            editBtn.isHidden = false
            if let appDel = NSApplication.shared.delegate as? AppDelegate {
                appDel.hideMenus(new: false, save: false, saveAs: false, changePassord: false, prefs: false)
            }
        }
        collectionView.reloadData()
        TryStartScreenProtectTimer()
    }
    
    func setpasswordCallback(do_save_as: Bool, for_change_password:Bool) {
        SaveData(saveas: do_save_as, for_change_password:for_change_password)
    }
    
    func screenprotectCallback() {
        if (!share.screen_protect) {
            addBtn.isEnabled = true
            collectionView.reloadData()
            TryStartScreenProtectTimer()
            // enable menu items
            if let appDel = NSApplication.shared.delegate as? AppDelegate {
                appDel.enableMenus(new: true, save: true, saveAs: true, changePassord: true, prefs: true)
            }
        }
        
    }
    
    func editItemCallback(otp: Otp) {

        collectionView.reloadData()
        TryStartScreenProtectTimer()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        if(segue.identifier!.rawValue == "unlockSegue") {
            let nextViewController = (segue.destinationController as! PasswordViewController)
            nextViewController.action_setpassword = false
        } else if (segue.identifier!.rawValue == "setPasswordSegue") {
            let nextViewController = (segue.destinationController as! PasswordViewController)
            nextViewController.action_setpassword = true
            nextViewController.action_dosaveas = action_do_save_as
            nextViewController.action_for_change_password = action_for_change_password
        } else if (segue.identifier!.rawValue == "screenProtectSegue") {
            let nextViewController = (segue.destinationController as! PasswordViewController)
            nextViewController.action_setpassword = false
            nextViewController.action_dosaveas = false
            nextViewController.action_for_change_password = false
        } else if (segue.identifier!.rawValue == "editItemSegue") {
            let nextViewController = (segue.destinationController as! EditItemViewController)
            var thisItem = share.otp_items[selectedIndex!]
            thisItem.action = OtpAction.Edit
            thisItem.index = selectedIndex
            nextViewController.otp_item = share.otp_items[selectedIndex!]
        } else if (segue.identifier!.rawValue == "addItemSegue") {
            let nextViewController = (segue.destinationController as! EditItemViewController)
            var thisItem: Otp = Otp()
            thisItem.action = OtpAction.Add
            thisItem.index = nil
            nextViewController.otp_item = thisItem
        }
    }
    
    /* - - - - - - - -
      SEGUE FUNCTIONS
     -----------------*/
    
    
    func UpdateBtns(enable:Bool) {
        
        if (!enable && share.screen_protect) {
            addBtn.isEnabled = false
            qrCodeBtn.isHidden = false
        }
        if (enable) {
            addBtn.isEnabled = true
            qrCodeBtn.isHidden = true
        }
        
        editBtn.isEnabled = enable
        deleteBtn.isEnabled = enable
        TryStartScreenProtectTimer()
    }
    
    func dialogOKCancel(title: String, msg:String, cancel:Bool = false, cancelTitle:String = "Cancel", alertType: NSAlert.Style = NSAlert.Style.warning) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = title
        myPopup.informativeText = msg
        myPopup.alertStyle = alertType
        myPopup.addButton(withTitle: "OK")
        if (cancel) {
            myPopup.addButton(withTitle: cancelTitle)
        }
        TryStartScreenProtectTimer()
        return myPopup.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

}



/*----------------------------
   COLLECTION VIEW EXTENSIONS
 - - - - - - - - - - - - - - */

extension TokenListViewController : NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return share.otp_items.count
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath) as! CollectionViewItem
        
        let token = share.otp_items[indexPath.item]
        cell.otp = token
        
        return cell
    }
}

extension TokenListViewController : NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
        guard let indexPath = indexPaths.first else {
            return
        }
        guard let item = collectionView.item(at: indexPath as IndexPath) else {
            return
        }
        if (share.screen_protect) {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "screenProtectSegue"), sender: self)
        } else {
            selectedIndex = indexPath.item
            UpdateBtns(enable: true)
        }
        
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        
        guard let indexPath = indexPaths.first else {
            return
        }
        guard let item = collectionView.item(at: indexPath as IndexPath) else {
            return
        }
        //(item as! CollectionViewItem).highlightState = .forDeselection
        
        if (selectedIndex == indexPath.item) {
            selectedIndex = nil
            UpdateBtns(enable: false)
        }
    }
}

/*- - - - - - - - - - - - -
 COLLECTION VIEW EXTENSIONS
----------------------------*/

