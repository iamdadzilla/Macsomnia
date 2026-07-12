import Foundation
import ServiceManagement
import MacsomniaCore

enum HelperManager {
    static var service: SMAppService { SMAppService.daemon(plistName: MacsomniaHelperInfo.daemonPlistName) }
    static var status: SMAppService.Status { service.status }
    static var isEnabled: Bool { status == .enabled }
    static func register() throws { try service.register() }
    static func openLoginItemsSettings() { SMAppService.openSystemSettingsLoginItems() }
}
