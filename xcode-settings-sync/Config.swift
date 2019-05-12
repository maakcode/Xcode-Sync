//  Copyright © 2019 Makeeyaf. All rights reserved

import Foundation


struct Config {
    struct App {
        static let name = "xcode-sync"
        static let syncInterval = 30
        
        struct URLScheme {
            static let notificationName = "getCustomURLScheme"
            static let userInfo = "urlString"
            static let url = "m-xcode-sync://auth/callback"
        }
        
        struct Path {
            static let home = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Developer/Xcode/UserData"    //AppSandbox should off
            static let colorThemes = FilePath(path: home + "/FontAndColorThemes", type: "xccolortheme", isFolder: true)
            static let keyBindings = FilePath(path: home + "/KeyBindings", type: "idekeybindings", isFolder: true)
            static let ideTemplateMacros = FilePath(path: home, type: "IDETemplateMacros.plist", isFolder: false)
        }
        
    }
    
    struct Github {
        struct Key {
            static let id = APP_ID
            static let secret = APP_SECRET
            static let scope = "gist"
            static let description = "XcodeSync for "
        }
        
        struct Path {
            static func authorize(_ state: String) -> URL {
                return URL(string: "https://github.com/login/oauth/authorize?client_id=\(Config.Github.Key.id)&state=\(state)&scope=\(Config.Github.Key.scope)")!
            }
            
            static func createGist() -> URL {
                return URL(string: "https://api.github.com/gists")!
            }
            
            static func readGist(_ id: String) -> URL {
                return URL(string: "https://api.github.com/gists/\(id)")!
            }
            
            static func updateGist(_ id: String) -> URL {
                return URL(string: "https://api.github.com/gists/\(id)")!
            }
            
            static func deleteGist(_ id: String) -> URL {
                return URL(string: "https://api.github.com/gists/\(id)")!
            }
            
            static func userGist(_ userName: String) -> URL {
                return URL(string: "https://api.github.com/users/\(userName)/gists")!
            }
            
        }
        
    }
}


struct FilePath {
    let path: String
    let type: String
    let isFolder: Bool
}


struct FileData {
    var date: Date?
    var contents: String?
    var title: String?
}


enum CustomError: Error {
    case modificationDateNotFound
    case emptyAccountName
    case emptyPassword
    case saveKeychainError(Error)
    case loadKeychainError(Error)
    case deleteKeychainError(Error)
}
