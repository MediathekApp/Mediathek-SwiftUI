//
//  Bundle.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

class CloudBundle {
    
    static let shared = CloudBundle()
    
    private var config: [String: Any]?
    private var jsCode: String?
    
    // File path where bundles will be stored persistently
    private var bundleFileURL: URL
    
    init(filename: String = "bundle.js") {
        // Use Application Support directory for persistent, user-specific storage
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Create directory if doesn't exist
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        
        self.bundleFileURL = appSupportDir.appending(component: filename)
        
        let json = try? String(contentsOfFile: bundleFileURL.path, encoding: .utf8)
        if let json  {
            try? load(from: json)
        }
        
    }
    
    /// Downloads the bundle from a given URL and saves it persistently
    func download(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        
        log("Downloading cloud bundle from \(url)", .debug)
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let self = self, let data = data, let bundleString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "CloudBundle", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])))
                return
            }
            
            do {
                try bundleString.write(to: self.bundleFileURL, atomically: true, encoding: .utf8)
                try? load(from: bundleString)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Loads bundle from a given string, parsing config JSON and JS code into memory
    func load(from bundleString: String) throws {
        // 1. Extract config JSON block between "//config-json-start" and "//config-json-end"
        guard let configRangeStart = bundleString.range(of: "//config-json-start"),
              let configRangeEnd = bundleString.range(of: "//config-json-end") else {
            throw NSError(domain: "BundleManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Config block not found"])
        }
        
        // Extract the config block content
        let configBlockRange = configRangeStart.upperBound..<configRangeEnd.lowerBound
        let configBlockString = String(bundleString[configBlockRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse the config JSON from the config block
        // The config block looks like: const config = { ... }
        // So extract the { ... } part by searching for first '{' and last '}'
        guard let jsonStart = configBlockString.firstIndex(of: "{"),
              let jsonEnd = configBlockString.lastIndex(of: "}") else {
            throw NSError(domain: "BundleManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Malformed config JSON"])
        }
        
        let jsonString = String(configBlockString[jsonStart...jsonEnd])
        
        // Convert JSON string to Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "BundleManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to encode config JSON"])
        }
        
        // Deserialize JSON into dictionary
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let configDict = jsonObject as? [String: Any] else {
            throw NSError(domain: "BundleManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Config JSON is not a dictionary"])
        }
        
        self.config = configDict
        
        // Extract JS code after the config block end marker
        let jsStartIndex = configRangeEnd.upperBound
        let jsCodeString = String(bundleString[jsStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.jsCode = jsCodeString
    }
    
    /// Loads the bundle from the locally saved file (if exists)
    func loadFromFile() throws {
        let bundleString = try String(contentsOf: bundleFileURL, encoding: .utf8)
        try load(from: bundleString)
    }
    
    /// Getters for config and JS code
    func getConfig() -> [String: Any]? {
        return config
    }
    
    func getConfigString(_ key: String) -> String? {
        return (config?[key] as? String?) ?? nil
    }
    
    func getJS() -> String? {
        return jsCode
    }

}
