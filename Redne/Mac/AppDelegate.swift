//
//  AppDelegate.swift
//  Redne
//
//  Created by Charles Kelley on 3/31/25.
//

import Cocoa
import MetalKit


/**
 TODO: For portability, etc for a final platform layer.
 - saved game location
 - getting a handle on our own executable file
 - asset loading path
 - threading (launch a thread)
 - raw input (support for multiple keyboards)
 - sleep/timeBeginPeriod (laptops, etc, don't melt processor)
 - clipCursor() (for multiple monitor support
 - fullscreen support
 - control cursor visibility
 - query cancel autoplay
 - inactvie (when we are not the active app)
 - Blit speed importments
 - Hardware acceleration
 - GetKeyboardLayout (for french keyboards, international WASD support)
 */

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var mtkView: MTKView!
    var renderer: RenderView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let frame = NSRect(x: 0, y: 0, width: 640, height: 360)
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered,
                          defer: false)
        window.title = "Redne"
        
        mtkView = MTKView(frame: frame)
        mtkView.device = MTLCreateSystemDefaultDevice()
        window.contentView = mtkView
        
        renderer = RenderView(mtkView: mtkView)
        
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            print("key pressed: \(event.characters ?? "")")
            return nil
        })
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown, handler: { event in
            print("left mouse clicked at: \(event.locationInWindow)")
            return event
        })
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown, handler: { event in
            print("right mouse clicked at: \(event.locationInWindow)")
            return event
        })
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
