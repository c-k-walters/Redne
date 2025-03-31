//
//  Redne.swift
//  Redne
//
//  Created by Charles Kelley on 3/31/25.
//

import Cocoa
import MetalKit

@main
struct UnnamedGame {
    static func main() {
        // Start the application
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
