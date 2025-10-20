import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private let tokenKey = "savedToken"
    private let linkKey = "savedLink"
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func saveLink(_ link: String) {
        UserDefaults.standard.set(link, forKey: linkKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func getLink() -> String? {
        return UserDefaults.standard.string(forKey: linkKey)
    }
    
    func hasToken() -> Bool {
        return getToken() != nil
    }
}


