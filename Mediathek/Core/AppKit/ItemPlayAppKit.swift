//
//  ItemPlayAppKit.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

#if os(macOS)
import AppKit

func ItemPlayAppKit(_ item: Item, _ url: URL) {
    
    if AppConfig.playWithQuickTimePlayer {
        
        let appleScript = """
        tell application "QuickTime Player"
            activate
            open location "\(url)"
        end tell
        """

//            let process = Process()
//            process.launchPath = "/usr/bin/osascript"
//            process.arguments = ["-e", appleScript]
//
//            process.launch()
//            process.waitUntilExit()

        if let script = NSAppleScript(source: appleScript) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }

    }
    else {
        NSWorkspace.shared.open(url)
    }

}
#endif
