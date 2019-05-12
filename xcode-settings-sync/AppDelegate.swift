//  Copyright © 2019 Makeeyaf. All rights reserved

import Cocoa
import ServiceManagement


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var preferenceWindowController: NSWindowController? = nil
    let github = Github()
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        launchOnStartUp()
        constructMenu()
        
        if let token = Model.Keychain.getAccessTokenFromKeychian() {
            github.accessToken = token
            github.isValidAccessToken(of: token) { isValid, username, error in
                if error != nil {
                    #if DEBUG
                    print("isValidAccessToken error: \(String(describing: error))")
                    #endif
                    return
                }
                
                if isValid, let username = username {
                    self.github.userName = username
                    #if DEBUG
                    print("userName is set: \(username)")
                    #endif
                    
                } else {
                    try? Model.Keychain.deletePassword()
                    #if DEBUG
                    print("userName is empty")
                    #endif
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }


    @objc func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let appleEventDescription = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else { return }
        guard let appleEventURLString = appleEventDescription.stringValue else { return }

        NotificationCenter.default.post(name: NSNotification.Name(Config.App.URLScheme.notificationName), object: nil, userInfo: [Config.App.URLScheme.userInfo: appleEventURLString])
        
        #if DEBUG
        print("handleAppleEvent: \(appleEventURLString)")
        #endif
    }
    
    func launchOnStartUp() {
        let launcherAppId = "io.github.makeeyaf.XcodeSyncLauncher"
        let isLaunchOnStartup = UserDefaults.standard.bool(forKey: "launchOnStartup")
        
        if isLaunchOnStartup {
            let runningApps = NSWorkspace.shared.runningApplications
            let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
            
            SMLoginItemSetEnabled(launcherAppId as CFString, true)
            
            if isRunning {
                DistributedNotificationCenter.default().post(name: Notification.Name("killXcodeSyncLauncher"),
                                                             object: Bundle.main.bundleIdentifier!)
            }
        } else {
            SMLoginItemSetEnabled(launcherAppId as CFString, false)
        }
    }

    
    func constructMenu() {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        if let button = statusItem.button {
            button.image = NSImage(named:"menubarIcon")
        }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(title: "Upload", action: #selector(AppDelegate.upload(sender:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Download", action: #selector(AppDelegate.download(sender:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preference", action: #selector(AppDelegate.showPreference(sender:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Xcode Sync", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        
        statusItem.menu = menu
        
    }
    
    @objc func showPreference(sender: NSMenuItem) {
        if preferenceWindowController == nil {
            preferenceWindowController = ViewController.getWindowController()
            preferenceWindowController!.showWindow(sender)
            
        } else {
            preferenceWindowController!.window?.orderFrontRegardless()
        }
        
    }
    
    @objc func upload(sender: NSMenuItem) {
        if github.userName == "" {
            showPreference(sender: sender)
            return
        }
        
        sender.isEnabled = false

        github.upload {
            var timeLeft = TimeInterval(Config.App.syncInterval)
            
            let dateFormatter = DateComponentsFormatter()
            dateFormatter.allowedUnits = [.minute, .second]
            dateFormatter.unitsStyle = .positional
            dateFormatter.zeroFormattingBehavior = .pad
            
            let uploadTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: true) { timer in
                if timeLeft == TimeInterval(0) {
                    sender.isEnabled = true
                    sender.title = "Upload"
                    timer.invalidate()
                } else {
                    sender.title = "Upload (\(dateFormatter.string(from: timeLeft) ?? ""))"
                    timeLeft -= TimeInterval(1)
                    
                }
            }
            RunLoop.current.add(uploadTimer, forMode: .common)
        }
    }
    
    @objc func download(sender: NSMenuItem) {
        if github.userName == "" {
            showPreference(sender: sender)
            return
        }
        
        sender.isEnabled = false
        
        github.download {
            sender.isEnabled = true
        }
    }
    
}
