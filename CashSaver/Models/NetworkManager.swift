import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseRequest = "https://wallen-eatery.space"
    private let path = "/ios-vdm-9/server.php"
    private let paramP = "Bs2675kDjkb5Ga"
    
    private var paramOS: String {
        return UIDevice.current.systemVersion
    }
    
    private var paramLng: String {
        if let language = Locale.preferredLanguages.first {
            let languageCode = language.components(separatedBy: "-").first ?? language
            return languageCode
        }
        return Locale.current.languageCode ?? "11"
    }
    
    private var paramDevice: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private var paramCountry: String {
        if let regionCode = Locale.current.regionCode {
            return regionCode
        }
        if let language = Locale.preferredLanguages.first {
            let components = Locale.components(fromIdentifier: language)
            if let regionCode = components[NSLocale.Key.countryCode.rawValue] {
                return regionCode
            }
        }
        return "00"
    }
    
    private init() {}
    
    func checkServerRequest(completion: @escaping (Bool, String?, String?) -> Void) {
        var components = URLComponents(string: baseRequest + path)
        components?.queryItems = [
            URLQueryItem(name: "p", value: paramP),
            URLQueryItem(name: "os", value: paramOS),
            URLQueryItem(name: "lng", value: paramLng),
            URLQueryItem(name: "devicemodel", value: paramDevice),
            URLQueryItem(name: "country", value: paramCountry)
        ]
        
        guard let requestAddress = components?.url else {
            completion(false, nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: requestAddress) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(false, nil, nil)
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                if responseString.contains("#") {
                    let components = responseString.components(separatedBy: "#")
                    if components.count == 2 {
                        let token = components[0]
                        let link = components[1]
                        DispatchQueue.main.async {
                            completion(true, token, link)
                        }
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(false, nil, nil)
            }
        }
        
        task.resume()
    }
}
