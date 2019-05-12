//  Copyright © 2019 Makeeyaf. All rights reserved

import Cocoa
import Alamofire

class Github: NSObject {
    var originState: String = ""
    var accessToken: String = ""
    @objc dynamic var userName: String = ""
    

    
    struct Gist {
        /**
         Create gist files.
         - Parameter files: Array of FileData.
         - Parameter token: Github access token.
         - Parameter gistID: ID of created gist
         - Parameter error: Error
         */
        static func create(files: [FileData], description: String, token: String) {
            struct CreateGistResponse: Decodable {
                let id: String
                let updated_at: String
            }
            
            var contents: Dictionary<String, Any> = [:]
            for file in files {
                if let title = file.title {
                    contents[title] = [
                        "content": file.contents
                    ]
                }
            }
            
            let parameters: Parameters = ["files": contents, "description": description]
            
            let headers: HTTPHeaders = [
                "Authorization": "token \(token)",
                "Content-Type": "application/vnd.api+json",
                "Accept": "application/json"
            ]
            
            Alamofire.request(Config.Github.Path.createGist(), method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
                switch response.result {
                case .success:
                    do {
                        if let data = response.data {
                            let createGistResult = try JSONDecoder().decode(CreateGistResponse.self, from: data)
                            #if DEBUG
                            print("createGist result: \(createGistResult)")
                            #endif
                            return
                        } else {
                            #if DEBUG
                            print("createGist empty respone data: \(response)")
                            #endif
                            return
                        }
                    } catch {
                        #if DEBUG
                        print("createGist JSONSerialization error: \(error)")
                        #endif
                        return
                    }
                    
                case .failure(let error):
                    #if DEBUG
                    print("createGist error: \(error)")
                    #endif
                    return
                }
            }
        }
        
        /**
         Read gist and run completionHandler when request ends
         - Parameter id: ID of gist
         - Parameter token: Access Token
         - Parameter fileData: An array of FileData
         - Parameter error: Error
         */
        static func readGist(id: String, token: String, completionHandler: @escaping (_ fileData: [FileData]?, _ error: Error?) -> Void){
            struct ResponseFile: Decodable {
                let filename: String
                let content: String
            }
            
            struct ResponseGist: Decodable {
                let updated_at: String
                let files: [String:ResponseFile]
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "token \(token)",
                "Accept": "application/json"
            ]
            
            Alamofire.request(Config.Github.Path.readGist(id), method: .get, parameters: nil, headers: headers).validate().responseJSON { response in
                switch response.result {
                case .success:
                    do {
                        if let data = response.data {
                            let readGistResult = try JSONDecoder().decode(ResponseGist.self, from: data)
                            let dateFormat = DateFormatter()
                            dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            let updatedAt = dateFormat.date(from: readGistResult.updated_at) ?? Date()
                            var fileData: [FileData] = []
                            
                            for item in readGistResult.files {
                                fileData.append(FileData(date: updatedAt, contents: item.value.content, title: item.value.filename))
                            }
                            
                            #if DEBUG
                            print("readGist success: \(fileData.count)")
                            #endif
                            
                            completionHandler(fileData, nil)
                            return
                            
                        } else {
                            #if DEBUG
                            print("readGist empty respone data: \(response)")
                            #endif
                            completionHandler(nil, nil)
                            return
                        }
                        
                    } catch {
                        #if DEBUG
                        print("readGist JSONSerialization error: \(error)")
                        #endif
                        completionHandler(nil, error)
                        return
                    }
                    
                case .failure(let error):
                    #if DEBUG
                    print("readGist response error: \(error)")
                    #endif
                    completionHandler(nil, error)
                    return
                }
            }
        }
        
        /**
         Edit or Delete gist files.
         - Parameter id: Gist ID.
         - Parameter token: Github access token.
         - Parameter files: KVD of file name, FileData. Use FileData() to delete gist.
         - Parameter error: Error
         */
        static func updateGist(id: String, token: String, files: [String:FileData]) {
            let headers: HTTPHeaders = [
                "Authorization": "token \(token)",
                "Content-Type": "application/vnd.api+json",
                "Accept": "application/json"
            ]
            
            var contents: [String: Any] = [:]
            for item in files {
                if item.value.title == nil, item.value.contents == nil {
                    contents[item.key] = NSNull()
                } else {
                    if let title = item.value.title {
                        contents[item.key] = [
                            "filename": title
                        ]
                    }
                    if let content = item.value.contents {
                        contents[item.key] = [
                            "content": content
                        ]
                    }
                }
            }
            
            let parameters: Parameters = ["files": contents]
            
            Alamofire.request(Config.Github.Path.updateGist(id), method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
                switch response.result {
                case .success:
                    #if DEBUG
                    print("updateGist success: \(response)")
                    #endif
                    return
                    
                case .failure(let error):
                    #if DEBUG
                    print("updateGist response error: \(error)")
                    #endif
                    return
                    
                }
            }
        }
        
        /**
         Delete gist
         - Parameter id: ID of gist
         - Parameter token: Access Token
         - Parameter error: Error
         */
        static func deleteGist(id: String, token: String, completionHandler: @escaping (_ error: Error?) -> Void){
            let headers: HTTPHeaders = [
                "Authorization": "token \(token)",
                "Accept": "application/json"
            ]
            
            Alamofire.request(Config.Github.Path.deleteGist(id), method: .delete, parameters: nil, headers: headers).validate().responseString { response in
                switch response.result {
                case .success:
                    #if DEBUG
                    print("deleteGist success)")
                    #endif
                    
                    completionHandler(nil)
                    return
                    
                case .failure(let error):
                    #if DEBUG
                    print("deleteGist response error: \(error)")
                    #endif
                    completionHandler(error)
                    return
                }
            }
        }
        
       
        
        
        /**
         Get gist ID which XcodeSync created.
         - Parameter username: A name of user (**Not** login ID)
         - Parameter token: Access token
         - Parameter id: Gist ID
         - Parameter error: Error
         */
        static func getXcodeSyncGistID(username: String, token: String, completionHandler: @escaping (_ id: String?, _ error: Error?) -> Void) {
            struct ResponseGist: Decodable {
                let updated_at: String
                let id: String
                let description: String
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "token \(token)",
                "Accept": "application/json"
            ]
            
            Alamofire.request(Config.Github.Path.userGist(username), method: .get, parameters: nil, headers: headers).validate().responseJSON { response in
                switch response.result {
                case .success:
                    do {
                        if let data = response.data {
                            let readGistResult = try JSONDecoder().decode([ResponseGist].self, from: data)
                            let targetGist = readGistResult.filter { $0.description == Config.Github.Key.description + username }.first
                            
                            if let id = targetGist?.id {
                                #if DEBUG
                                print("getGistID success: \(id)")
                                #endif
                                
                                completionHandler(id, nil)
                                return
                            } else {
                                #if DEBUG
                                print("getGistID not found: \(readGistResult.debugDescription)")
                                #endif
                                
                                completionHandler(nil, nil)
                                return
                            }
                            
                            
                        } else {
                            #if DEBUG
                            print("getGistID empty respone data: \(response)")
                            #endif
                            completionHandler(nil, nil)
                            return
                        }
                        
                    } catch {
                        #if DEBUG
                        print("getGistID JSONSerialization error: \(error)")
                        #endif
                        completionHandler(nil, error)
                        return
                    }
                    
                case .failure(let error):
                    #if DEBUG
                    print("getGistID response error: \(error)")
                    #endif
                    completionHandler(nil, error)
                    return
                }
            }
        }
        
        /**
         Get gist which XcodeSync created.
         - Parameter gistID: Gist ID
         - Parameter token: Access token
         */
        static func getGistData(_ gistID: String, token: String, completion: @escaping ([FileData]?) -> Void) {
            Gist.readGist(id: gistID, token: token) { xcodeGist, error in
                if let xcodeGist = xcodeGist {
                    completion(xcodeGist)
                } else {
                    completion(nil)
                }
            }
            return
        }
    
    }
   
    
    /**
     Upload local files to Gist.
     */
    func upload(completion: @escaping () -> Void) {
        if userName == "" {
            completion()
            return
        }
        
        let localData = Model.File.getLocalData()
        
        Gist.getXcodeSyncGistID(username: userName, token: accessToken) { (gistID, _) in
            if let gistID = gistID {
                
                Gist.getGistData(gistID, token: self.accessToken) { (gistData) in
                    guard let gistData = gistData else {
                        completion()
                        return
                    }
                    
                    if gistData.count == 0 {
                        Gist.create(files: localData, description: Config.Github.Key.description + self.userName, token: self.accessToken)
                    } else {
                        var updateData: [String: FileData] = [:]
                        
                        for item in gistData {
                            if !localData.contains { $0.title == item.title } {
                                if let title = item.title {
                                    var deleteItem: FileData = item
                                    deleteItem.contents = nil
                                    deleteItem.title = nil
                                    updateData[title] = deleteItem
                                }
                            }
                        }
                        
                        for item in localData {
                            if let title = item.title {
                                updateData[title] = item
                            }
                        }
                        
                        Gist.updateGist(id: gistID, token: self.accessToken, files: updateData)
                    }
                    
                }
            }
            
        }
        
        completion()
        return
    }
    
    /**
     Download files from Gist.
     */
    func download(completion: @escaping () -> Void) {
        if userName == "" {
            completion()
            return
        }
        
        Gist.getXcodeSyncGistID(username: userName, token: accessToken) { (gistID, _) in
            if let gistID = gistID {
                
                Gist.getGistData(gistID, token: self.accessToken) { (gistData) in
                    guard let gistData = gistData else { return }
                    
                    if gistData.count > 0 {
                        Model.File.clearLocalData()
                        Model.File.setLocalData(writeData: gistData)
                    }
                    
                }
            }
        }
        
        completion()
        return
    }
    
    /**
     Initialize Github OAuth
     */
    func initOAuth() {
        originState = getState()
        let url = Config.Github.Path.authorize(originState)
        
        NotificationCenter.default.addObserver(self, selector: #selector(getCustomURLScheme(_:)), name: NSNotification.Name(rawValue: Config.App.URLScheme.notificationName), object: nil)
        
        NSWorkspace.shared.open([url], withAppBundleIdentifier: "com.apple.Safari", options: NSWorkspace.LaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        
        #if DEBUG
        print("Init OAuth: \(url.absoluteString)")
        #endif
        
    }
    
    /**
     Get "code" from Github when CustomURL clicked. Then, run aquireAccessToken
     */
    @objc func getCustomURLScheme(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Config.App.URLScheme.notificationName), object: nil)
        
        if let urlString = notification.userInfo?.first(where: {$0.key == AnyHashable(Config.App.URLScheme.userInfo)})?.value as? String {
            if let queryItems = URLComponents(string: urlString)?.queryItems {
                if queryItems.contains(where: { $0.name == "state" }), queryItems.contains(where: { $0.name == "code" }) {
                    let code = queryItems.first(where: { $0.name == "code" })!.value!
                    let replyState = queryItems.first(where: { $0.name == "state" })!.value!
                    
                    if replyState != originState {
                        #if DEBUG
                        print("getCustomURLScheme error: state contamination. origin \(originState), reply \(replyState)")
                        #endif
                        return
                    } else {
                        #if DEBUG
                        print("getCustomURLScheme complete. code: \(code)")
                        #endif
                        
                        aquireAccessToken(with: code) { token, error in
                            if let error = error {
                                #if DEBUG
                                print("getCustomURLScheme aquireAccessToken error: \(error)")
                                #endif
                                return
                            }
                            if let token = token {
                                self.isValidAccessToken(of: token) { isValid, username, error in
                                    if error != nil {
                                        #if DEBUG
                                        print("isValidAccessToken error: \(String(describing: error))")
                                        #endif
                                        return
                                    }
                                    
                                    if isValid, let username = username {
                                        self.userName = username
                                        try? Model.Keychain.savePassword(token)
                                        #if DEBUG
                                        print("token is set: \(username)")
                                        #endif
                                        
                                    } else {
                                        #if DEBUG
                                        print("token is invalid")
                                        #endif
                                    }
                                }
                            } else {
                                #if DEBUG
                                print("getCustomURLScheme token empty")
                                #endif
                                return
                            }
                        }
                    }
                    
                    
                } else {
                    #if DEBUG
                    print("getCustomURLScheme error: Some arguments are missing \(queryItems.debugDescription)")
                    #endif
                }
            }
            
        } else {
            #if DEBUG
            print("getCustomURLScheme error: urlString nil")
            #endif
            return
        }
        
    }
    
    /**
     Get access token with "code"
     - Parameter code: A string that Github sent.
     - Parameter token: Access token
     - Parameter error: Error
     */
    func aquireAccessToken(with code: String, completionHandler: @escaping (_ token: String?, _ error: Error?) -> Void) {
        struct ResponseToken: Decodable {
            let access_token: String
        }
        
        originState = getState()
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        let parameters: Parameters = [
            "client_id": Config.Github.Key.id,
            "client_secret": Config.Github.Key.secret,
            "code": code,
            "state": originState
        ]
        
        Alamofire.request("https://github.com/login/oauth/access_token", method: .post, parameters: parameters, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    if let data = response.data {
                        let token = try JSONDecoder().decode(ResponseToken.self, from: data).access_token
                        #if DEBUG
                        print("setAccessToken token: \(token)")
                        #endif
                        completionHandler(token, nil)
                        return
                    } else {
                        #if DEBUG
                        print("setAccessToken empty respone data: \(response)")
                        #endif
                        completionHandler(nil, nil)
                        return
                    }
                    
                } catch {
                    #if DEBUG
                    print("setAccessToken JSONSerialization error: \(error)")
                    #endif
                    completionHandler(nil, error)
                    return
                }
                
            case .failure(let error):
                #if DEBUG
                print("setAccessToken response error: \(error)")
                #endif
                completionHandler(nil, error)
                return
            }
        }
    }
    
    /**
     Check if access token is valid, And get user name.
     - Parameter token: Access token
     - Parameter isValid: Whether Access token is valid or not
     - Parameter userName: A name of user (**Not** login ID)
     - Parameter error: Error
     */
    func isValidAccessToken(of token: String, completionHandler: @escaping (_ isValid: Bool, _ userName: String?, _ error: Error?) -> Void) {
        struct ResponseUserInfo: Decodable {
            let name: String
        }
        
        var headers: HTTPHeaders = [:]
        if let authHeader = Request.authorizationHeader(user: Config.Github.Key.id, password: token) {
            headers[authHeader.key] = authHeader.value
        }
        
        Alamofire.request("https://api.github.com/user", headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    if let data = response.data {
                        let userInfo = try JSONDecoder().decode(ResponseUserInfo.self, from: data)
                        #if DEBUG
                        print("AccessToken is Valid for this user: \(userInfo.name)")
                        #endif
                        completionHandler(true, userInfo.name, nil)
                        
                    } else {
                        #if DEBUG
                        print("AccessToken is Valid but can't get userdata: \(response)")
                        #endif
                        completionHandler(false, nil, nil)
                    }
                    
                } catch {
                    #if DEBUG
                    print("AccessToken is Valid but can't find username: \(response)")
                    #endif
                    completionHandler(false, nil, nil)
                }
                
            case .failure(let error):
                #if DEBUG
                print("AccessToken is Invalid: \(error)")
                #endif
                completionHandler(false, nil, error)
            }
            return
        }
        
    }
    
    /**
     Create random hash string
     - Parameter radix: Default 32
     - Parameter uppercase: Whether hash string should uppercase or not. Default true
     - Returns: Hash string
     */
    func getState(radix: Int = 32, uppercase: Bool = true) -> String {
        return String(abs(Int.random(in: 1...Int.max).hashValue), radix: radix, uppercase: uppercase)
    }
}
