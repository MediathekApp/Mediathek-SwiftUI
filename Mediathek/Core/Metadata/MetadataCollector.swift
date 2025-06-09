//
//  MetadataCollector.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import Foundation
import JavaScriptCore

class MetadataCollector {
    
    static let shared = MetadataCollector()
    var jsManager = JavaScriptManager()
    
    #if DEBUG
    var lastLoad: Date = Date.distantPast
    #endif
    
    func prepare(_ callback: @escaping () -> Void) {
        #if DEBUG
        // Use a fresh context for each request during debugging
        if Date.now.timeIntervalSince(lastLoad) > 5 {
            self.lastLoad = Date.now
            CloudBundle.shared.download(from: URL(string: AppConfig.cloudBundleURL)!) { result in
                self.jsManager = JavaScriptManager()
                callback()
            }
        } else {
            callback()
        }
        #else
        callback()
        #endif
    }
    
    func collectMetadataForItem(urn: String, _ callback: @escaping (String?) -> Void) {
        prepare {
            self.jsManager.getMetadataForItem(urn: urn, callback: callback)
        }
    }
    
    func collectMetadataForProgram(urn: String, _ callback: @escaping (String?) -> Void) {
        prepare {
            self.jsManager.getMetadataForProgram(urn: urn, callback: callback)
        }
    }
    
    func getUrnForUrl(url: String, callback: @escaping (String?) -> Void) {
        prepare {
            if url.starts(with: "urn:") {
                callback(url)
                return
            }
            self.jsManager.getUrnForUrl(url: url) { result in
                callback(result)
            }
        }
    }

    func collectProgramFeed(urn: String, callback: @escaping (String?) -> Void) {
        prepare {
            self.jsManager.getProgramFeed(urn: urn, callback: callback)
        }
    }
    
    func collectProgramList(publisherId: String, callback: @escaping (String?) -> Void) {
        prepare {
            self.jsManager.getProgramList(publisherId: publisherId, callback: callback)
        }
    }

}

class JavaScriptManager {
    let context: JSContext
    
    init() {
        context = JSContext()!
        
        // Error logging
        context.exceptionHandler = { _, exception in
            guard let exception = exception else {
                log("❌ JS Exception: unknown error", .error)
                return
            }

            let exceptionMessage = exception.toString() ?? "Unknown error"
            
            // These properties are often present on JS Error objects
            let lineNumber = exception.objectForKeyedSubscript("line")?.toInt32() ?? -1
            let columnNumber = exception.objectForKeyedSubscript("column")?.toInt32() ?? -1
            let stackTrace = exception.objectForKeyedSubscript("stack")?.toString() ?? "No stack trace"

            log(
                """
                ❌ JS Exception: \(exceptionMessage)
                ➤ Line: \(lineNumber), Column: \(columnNumber)
                ➤ Stack trace:
                \(stackTrace)
                """,
                .error
            )
        }
        
        // Swift network function exposed to JS
        let swiftNetworkFunction: @convention(block) (String, JSValue, JSValue) -> Void =
        { urlString, headers, jsCallback in
            
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    jsCallback.call(withArguments: [
                        "Invalid URL", NSNull(),
                    ])
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Convert JSValue headers to [String: String]
            if let headerDict = headers.toDictionary() as? [String: Any] {
                for (key, value) in headerDict {
                    if let stringValue = value as? String {
                        request.addValue(stringValue, forHTTPHeaderField: key)
                        //log("Setting header \(key): \(stringValue)", .debug)
                    }
                }
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        jsCallback.call(withArguments: [
                            error.localizedDescription, NSNull(),
                        ])
                    } else if
                        let data = data,
                        let responseString = String(
                            data: data,
                            encoding: .utf8
                        ),
                        let responseCode = (response as? HTTPURLResponse)?.statusCode
                    {
                        jsCallback.call(withArguments: [
                            NSNull(), responseString, responseCode
                        ])
                    } else {
                        jsCallback.call(withArguments: [
                            "Unknown error", NSNull(),
                        ])
                    }
                }
            }.resume()
        }
        
        // Inject into JS context
        context.setObject(
            swiftNetworkFunction,
            forKeyedSubscript: "readContentsOfURLAsString" as NSString
        )
        
        let swiftLogFunction: @convention(block) (String, String) -> Void = {
            message,
            logLevelString in
            let logLevel: LogMessageLevel =
            switch logLevelString {
            case "warn", "warning": .warning
            case "error": .error
            case "debug": .debug
            case "info": .info
            default: .info
            }
            
            log(message, logLevel)
            
        }
        
        context.setObject(
            swiftLogFunction,
            forKeyedSubscript: "nativeLog" as NSString
        )
        
        func userDefaultsKeyForTokenName(_ tokenName: String) -> String {
            return "APIToken "+tokenName
        }
        
        
        let swiftSetTokenFunction: @convention(block) (String, String) -> Void = {
            tokenName,
            tokenValue in
            
            UserDefaults.standard.setValue(tokenValue, forKey: userDefaultsKeyForTokenName(tokenName))
            
        }

        context.setObject(
            swiftSetTokenFunction,
            forKeyedSubscript: "saveToken" as NSString
        )
        
        let swiftGetTokenFunction: @convention(block) (String) -> String? = {
            tokenName in
            
            return UserDefaults.standard.string(forKey: userDefaultsKeyForTokenName(tokenName))
            
        }

        context.setObject(
            swiftGetTokenFunction,
            forKeyedSubscript: "getToken" as NSString
        )

        
        // Load the JavaScript from our cloud bundle:
        guard let jsCode = CloudBundle.shared.getJS() else {
            log("Failed to load JavaScript from cloud bundle", .error)
            return
        }

        context.evaluateScript(jsCode)

    }

    func getUrnForUrl(url: String, callback: @escaping (String?) -> Void) {
        runJavaScriptCode(syncFunctionNameOrSilentExceptions: "getUrnForUrl", stringArgument: url, callback: callback)
    }

    func getMetadataForItem(urn: String, callback: @escaping (String?) -> Void) {
        runJavaScriptCode(syncFunctionNameOrSilentExceptions: "getMetadataForItem", stringArgument: urn, callback: callback)
    }

    func getMetadataForProgram(urn: String, callback: @escaping (String?) -> Void) {
        runJavaScriptCode(syncFunctionNameOrSilentExceptions: "getMetadataForProgram", stringArgument: urn, callback: callback)
    }

    func getProgramFeed(urn: String, callback: @escaping (String?) -> Void) {
        runJavaScriptCode(syncFunctionNameOrSilentExceptions: "getProgramFeed", stringArgument: urn, callback: callback)
    }
    
    func getProgramList(publisherId: String, callback: @escaping (String?) -> Void) {
        runJavaScriptCode(syncFunctionNameOrSilentExceptions: "getProgramList", stringArgument: publisherId, callback: callback)
    }

    internal func runJavaScriptCode(syncFunctionNameOrSilentExceptions: String, stringArgument: String, callback: @escaping (String?) -> Void) {
                
        // Get JS function
        guard let fetchData = context.objectForKeyedSubscript(syncFunctionNameOrSilentExceptions)
        else {
            log("⚠️ fetchData function not found in JS context.", .warning)
            callback(nil)
            return
        }
        
        // Define Swift callback
        let swiftCallback: @convention(block) (JSValue?, JSValue?) -> Void = {
            error,
            result in
            if let error = error, !error.isNull {
                log(
                    "🔴 Adapter Error: \(error.toString() ?? "Unknown error")",
                    .error
                )
                callback(nil)
            } else {
//                    log(
//                        "✅ Adapter Response: \(result?.toString() ?? "No result")",
//                        .debug
//                    )
                callback(result?.toString())
            }
        }
        
        // Wrap Swift callback in JSValue
        let jsCallback = JSValue(object: swiftCallback, in: context)!
        
        // Call JS function with callback
        fetchData.call(withArguments: [jsCallback, stringArgument])

    }
    
    
}
