//  Copyright © 2019 Makeeyaf. All rights reserved

import Foundation

struct Model {
    struct File {
        static func getLocalData() -> [FileData] {
            return Model.File.getFilesData(atFilePath: Config.App.Path.keyBindings) + Model.File.getFilesData(atFilePath: Config.App.Path.colorThemes) + Model.File.getFilesData(atFilePath: Config.App.Path.ideTemplateMacros)
        }
        
        static func setLocalData(writeData: [FileData]) {
            for item in writeData {
                guard let title = item.title else { continue }
                
                let folders = [Config.App.Path.colorThemes, Config.App.Path.keyBindings, Config.App.Path.ideTemplateMacros]
                guard let folder = folders.first(where: { title.hasSuffix($0.type) }) else { continue }
                let atPath = folder.path + "/" + title
                
                guard let contents = item.contents else { continue }
                #if DEBUG
                print("setLocalData: Writing", atPath)
                #endif
                Model.File.writeFile(atPath: atPath, contents: contents)
            }
        }
        
        static func clearLocalData() {
            let localData = Model.File.getLocalData()
            for item in localData {
                guard let title = item.title else { continue }
                
                let folders = [Config.App.Path.colorThemes, Config.App.Path.keyBindings, Config.App.Path.ideTemplateMacros]
                guard let folder = folders.first(where: { title.hasSuffix($0.type) }) else { continue }
                let atPath = folder.path + "/" + title
                
                #if DEBUG
                print("clearLocalData: Deleting", atPath)
                #endif
                
                Model.File.deleteFile(atPath: atPath)
            }
        }
        
        
        /**
         Write contents in file at atPath
         - Parameter atPath: Path String include file name
         - Parameter contents: Content string
         */
        static func writeFile(atPath: String, contents: String) {
            do {
                try contents.write(toFile: atPath, atomically: true, encoding: .utf8)
                
            } catch {
                #if DEBUG
                print("writeFile error: \(error)")
                #endif
            }
        }
        
        /**
         Delete file at atPath
         - Parameter atPath: Path String include file name
         */
        static func deleteFile(atPath: String) {
            let fileManager = FileManager()
            if fileManager.fileExists(atPath: atPath), fileManager.isDeletableFile(atPath: atPath) {
                do {
                    try fileManager.removeItem(atPath: atPath)
                    
                } catch {
                    #if DEBUG
                    print(error)
                    #endif
                }
                
            }
        }
        
        /**
         Read file at atPath and convert it to FileData object.
         If modification date of file not available, it uses current datetime instead.
         - Parameter atPath: Path String include file name
         - Returns: FileData object
         */
        static func readFile(atPath: String) -> FileData? {
            let fileManager = FileManager()
            
            do {
                var fileData = FileData()
                
                fileData.contents = try String(contentsOfFile: atPath)
                
                if let title = atPath.split(separator: "/").last {
                    fileData.title = String(title)
                } else {
                    #if DEBUG
                    print("readFile Invalid filename: \(atPath)")
                    #endif
                    
                    return nil
                }
                
                let fileAttribute = try fileManager.attributesOfItem(atPath: atPath)
                if let modificationDate = fileAttribute[FileAttributeKey.modificationDate] as? Date {
                    fileData.date = modificationDate
                } else {
                    #if DEBUG
                    print(CustomError.modificationDateNotFound)
                    #endif
                    fileData.date = Date()
                }
                
                return fileData
                
            } catch {
                #if DEBUG
                print(error)
                #endif
                
                return nil
                
            }
        }
        
        /**
         Get [filename:FileData] Dictionary at atFilePath.path directory
         - Parameter atFilePath: directory infomation about file to read
         - Returns: [filename:FileData] Dictionary
         */
        static func getFilesData(atFilePath: FilePath) -> [FileData] {
            let fileManager = FileManager()
            let fileNames: [String]
            var files: [FileData] = []
            
            do {
                if atFilePath.isFolder {
                    fileNames = try fileManager.contentsOfDirectory(atPath: atFilePath.path).filter { $0.hasSuffix(atFilePath.type) }
                } else {
                    fileNames = try fileManager.contentsOfDirectory(atPath: atFilePath.path).filter { $0 == atFilePath.type }
                }
                
                for fileName in fileNames {
                    if let file = readFile(atPath: "\(atFilePath.path)/\(fileName)") {
                        files.append(file)
                    }
                }
                
            } catch {
                #if DEBUG
                print(error)
                #endif
            }
            
            return files
        }
    }
    
    struct Keychain {
        /**
         Get access token from Keychian.
         - Returns: Access token
         */
        static func getAccessTokenFromKeychian() -> String? {
            do {
                let accessToken = try loadPassword()
                return accessToken
                
            } catch CustomError.loadKeychainError(KeychainPasswordItem.KeychainError.noPassword) {
                #if DEBUG
                print("getAccessToken password not set")
                #endif
                return nil
                
            } catch {
                #if DEBUG
                print("getAccessToken error: \(error)")
                #endif
                return nil
                
            }
        }
        
        /**
         Save a dictionary in Keychian.
         - Parameter password: Value of dictionary
         */
        static func savePassword(_ password: String, account: String = Config.App.name) throws {
            if !password.isEmpty {
                do {
                    #if DEBUG
                    print("savePassword password for account \(account): \(password)")
                    #endif
                    //                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: XcodeSync.accountName.rawValue, accessGroup: KeychainConfiguration.accessGroup)
                    let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
                    try passwordItem.savePassword(password)
                } catch {
                    #if DEBUG
                    print("savePassword error for account \(account): \(error)")
                    #endif
                    throw(CustomError.saveKeychainError(error))
                }
            } else {
                #if DEBUG
                print("savePassword error: empty password")
                #endif
                throw(CustomError.emptyPassword)
            }
        }
        
        /**
         Load a dictionary from Keychian.
         - Returns: Value of dictionary
         */
        static func loadPassword(account: String = Config.App.name) throws -> String {
            do {
                //            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: XcodeSync.accountName.rawValue, accessGroup: KeychainConfiguration.accessGroup)
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
                let password = try passwordItem.readPassword()
                #if DEBUG
                print("loadPassword password for account \(account): \(password)")
                #endif
                return password
            } catch {
                #if DEBUG
                print("loadPassword error for account \(account): \(error)")
                #endif
                
                throw(CustomError.loadKeychainError(error))
            }
        }
        
        /**
         Delete dictionary in Keychian.
         */
        static func deletePassword(account: String = Config.App.name) throws {
            do {
                #if DEBUG
                print("deletePassword")
                #endif
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
                try passwordItem.deleteItem()
            } catch {
                #if DEBUG
                print("savePassword error for account \(account): \(error)")
                #endif
                throw(CustomError.deleteKeychainError(error))
            }
        }

    }
    
}

