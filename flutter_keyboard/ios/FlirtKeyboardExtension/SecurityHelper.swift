import Foundation
import UIKit

/// Security checks for jailbreak, debugging, and tampering detection
final class SecurityHelper {

    static func isSecureEnvironment() -> Bool {
        if isJailbroken() { return false }
        if isDebuggerAttached() { return false }
        if isReverseEngineeringToolPresent() { return false }
        return true
    }

    /// Check for jailbreak indicators
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false // Don't check on simulator during development
        #else
        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/lib/libcycript.dylib",
            "/var/lib/cydia",
            "/usr/bin/ssh",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/cydia",
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if app can write to system directories
        let testPath = "/private/jailbreaktest.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // Shouldn't be able to write here
        } catch {
            // Expected on non-jailbroken device
        }

        // Check for Cydia URL scheme
        if let url = URL(string: "cydia://package/com.example.test"),
           UIApplication.shared.canOpenURL(url) {
            return true
        }

        // Check for suspicious dynamic libraries
        let suspiciousLibs = ["SubstrateLoader", "SSLKillSwitch", "FridaGadget", "frida", "libcycript"]
        for i in 0..<_dyld_image_count() {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName)
            for lib in suspiciousLibs {
                if name.lowercased().contains(lib.lowercased()) {
                    return true
                }
            }
        }

        return false
        #endif
    }

    /// Check if a debugger is attached
    static func isDebuggerAttached() -> Bool {
        #if DEBUG
        return false // Allow during development
        #else
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        return false
        #endif
    }

    /// Check for reverse engineering tools (Frida, etc.)
    static func isReverseEngineeringToolPresent() -> Bool {
        // Check Frida default port
        let fridaPort: UInt16 = 27042
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = fridaPort.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(sock, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        return result == 0 // If connection succeeded, Frida is likely running
    }
}
