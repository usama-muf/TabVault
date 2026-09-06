import AppKit
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    var action: (() -> Void)?

    func register() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x54564C54) // "TVLT"
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        InstallEventHandler(GetApplicationEventTarget(), { (_, _, _) -> OSStatus in
            HotKeyManager.shared.action?()
            return noErr
        }, 1, &eventType, nil, nil)

        var hotKeyRef: EventHotKeyRef?
        // kVK_ANSI_V is 0x09
        // cmdKey and optionKey are defined in Carbon
        let modifiers = UInt32(cmdKey | optionKey)
        
        RegisterEventHotKey(UInt32(kVK_ANSI_V), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
