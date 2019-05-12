//  Copyright © 2019 Makeeyaf. All rights reserved

import Cocoa
import ServiceManagement

class ViewController: NSViewController, NSWindowDelegate {
    @IBOutlet weak var launchOnSystemStartupCheckBox: NSButton!
    @IBOutlet weak var accountName: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    let appdelegate = NSApplication.shared.delegate as! AppDelegate
    var observation: NSKeyValueObservation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.delegate = self
        self.view.window?.level = .modalPanel
        
        
        self.observation = appdelegate.github.observe(\Github.userName) { (object, _ ) in
            if object.userName.isEmpty {
                self.accountName.stringValue = "Not logged in"
                self.loginButton.title = "Login"
            } else {
                self.accountName.stringValue = object.userName
                self.loginButton.title = "Logout"
            }
        }
        
        setOptionValues()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        appdelegate.preferenceWindowController = nil
    }
    
    
    
    @IBAction func launchOnSystemStartupPressed(_ sender: Any) {
        let launcherAppId = "io.github.makeeyaf.XcodeSyncLauncher"

        if launchOnSystemStartupCheckBox.state == .on {
            UserDefaults.standard.set(true, forKey: "launchOnStartup")
            SMLoginItemSetEnabled(launcherAppId as CFString, true)
            
        } else if launchOnSystemStartupCheckBox.state == .off {
            UserDefaults.standard.set(false, forKey: "launchOnStartup")
            SMLoginItemSetEnabled(launcherAppId as CFString, false)
            
        }
    }

    @IBAction func loginPressed(_ sender: Any) {
        if appdelegate.github.userName.isEmpty {
            appdelegate.github.initOAuth()
            
        } else {
            try? Model.Keychain.deletePassword()
            appdelegate.github.userName = ""
            appdelegate.github.accessToken = ""
        }
    }

    @IBAction func showLicense(_ sender: Any) {
        NSWorkspace.shared.open(Bundle.main.url(forResource: "Licenses", withExtension: "rtf")!)
    }
    
    
    func setOptionValues() {
        launchOnSystemStartupCheckBox.state = UserDefaults.standard.bool(forKey: "launchOnStartup") ? .on : .off
        
        if appdelegate.github.userName.isEmpty {
            accountName.stringValue = "Not logged in"
            loginButton.title = "Login"
        } else {
            accountName.stringValue = appdelegate.github.userName
            loginButton.title = "Logout"
        }
        
    }
}

extension ViewController {
    static func getWindowController() -> NSWindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "preferenceWindowController") as! NSWindowController
        
        return windowController
    }
}
