import Foundation
import IOKit

class BrightnessControl {
    private var originalBrightness: Float = 1.0

    init() {
        print("Initializing BrightnessControl")
        originalBrightness = getBrightness() ?? 1.0
    }

    // Get the current brightness of the main display
    func getBrightness() -> Float? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("AppleDisplay"))
        guard service != 0 else {
            print("Unable to find AppleDisplay service")
            return nil
        }

        defer { IOObjectRelease(service) }

        var brightness: Float = 0
        let result = IODisplayGetFloatParameter(service,
                                                0,
                                                kIODisplayBrightnessKey as CFString,
                                                &brightness)

        guard result == kIOReturnSuccess else {
            print("Error getting brightness: \(result)")
            return nil
        }

        print("Current brightness: \(brightness)")
        return brightness
    }

    // Set the brightness of the main display
    func setBrightness(_ brightness: Float) -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("AppleDisplay"))
        guard service != 0 else {
            print("Unable to find AppleDisplay service")
            return false
        }

        defer { IOObjectRelease(service) }

        let clampedBrightness = max(0.0, min(1.0, brightness))
        let result = IODisplaySetFloatParameter(service,
                                                0,
                                                kIODisplayBrightnessKey as CFString,
                                                clampedBrightness)

        guard result == kIOReturnSuccess else {
            print("Error setting brightness: \(result)")
            return false
        }

        print("Successfully set brightness to: \(clampedBrightness)")
        return true
    }
}
