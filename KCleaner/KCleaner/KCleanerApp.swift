//
//  Keyboard_CleanerApp.swift
//  Keyboard Cleaner
//
//  Created by Dheeraj Gosula on 2/10/25.
//
import SwiftUI
import Cocoa
import Foundation


@main
struct Keyboard_CleanerApp: App {
    @StateObject private var keyModifier = KeyModifierApp()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    keyModifier.setupEventTap()
                }
        }
    }
}

class KeyModifierApp: ObservableObject {
    var optionKeyCount = 0
    var isModificationActive = false
    var eventTap: CFMachPort?
    
    let modifierKeyCodes: Set<Int64> = [
        58, 61,  // Option keys (left, right)
    ]
    
    let functionKeyCodes: Set<Int64> = [
        53, 107, 122, 113, 120, 160, 99, 131, 118, 96, 97, 98, 100, 101, 109, 103, 111
    ]
    
    func isSpecialKey(_ keyCode: Int64) -> Bool {
        return functionKeyCodes.contains(keyCode) || modifierKeyCodes.contains(keyCode)
    }

    func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
        guard let refcon = refcon else { return Unmanaged.passRetained(event) }
        let app = Unmanaged<KeyModifierApp>.fromOpaque(refcon).takeUnretainedValue()
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Handle Option key presses
        if type == .flagsChanged && (keyCode == 58 || keyCode == 61) {
            app.optionKeyCount += 1
            if app.optionKeyCount == 6 {
                app.isModificationActive.toggle()
                print("Key modification \(app.isModificationActive ? "Activated" : "Deactivated")")
                app.optionKeyCount = 0
            }
            
            return Unmanaged.passRetained(event)
        }
        
        if app.isModificationActive {
            app.dimScreen()
        }
        else {
            app.restoreScreenBrightness()
        }
        
        // Reset option key count for non-option key presses
        if type == .keyDown && !(keyCode == 58 || keyCode == 61) {
            app.optionKeyCount = 0
        }
        
        // Handle key modification
        if app.isModificationActive && !app.isSpecialKey(keyCode) {
            switch type {
            case .keyDown:
                // Create new keyDown event for 'b' (keycode 11)
                if let newEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0xFF, keyDown: true) {
                    newEvent.flags = event.flags
                    return Unmanaged.passRetained(newEvent)
                }
            case .keyUp:
                // Create corresponding keyUp event for 'b'
                if let newEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0xFF, keyDown: false) {
                    newEvent.flags = event.flags
                    return Unmanaged.passRetained(newEvent)
                }
            default:
                break
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private var originalBrightness: Float = 1.0
    private let brightnessControl = BrightnessControl()
    
    private func setBrightnessLevel(level: Float) {
        _ = brightnessControl.setBrightness(level)
    }
    
    private func getBrightness() -> Float {
        return brightnessControl.getBrightness() ?? 1.0
    }
    
    private func dimScreen() {
        originalBrightness = getBrightness()
        setBrightnessLevel(level: 0.0)
    }
    
    private func restoreScreenBrightness() {
        setBrightnessLevel(level: originalBrightness)
    }
}
