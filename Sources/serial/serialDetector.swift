#if os(macOS)
import IOKit.usb

final class serialDetector {
    private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    var addedDeviceHandler: (() -> Void)?
    var removedDeviceHandler: (() -> Void)?
    
    func start() {
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
        
        let runLoop = IONotificationPortGetRunLoopSource(notificationPort)!.takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, CFRunLoopMode.defaultMode)
        
        // MARK: ★★★ Added Notification ★★★ //
        let addedCallback: IOServiceMatchingCallback = { (pointer, iterator) in
            let detector = Unmanaged<serialDetector>.fromOpaque(pointer!).takeUnretainedValue()
            detector.addedDeviceHandler?()
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                IOObjectRelease(device)
            }
        }
        IOServiceAddMatchingNotification(notificationPort, kIOPublishNotification, matchingDict, addedCallback, opaqueSelf, &addedIterator)
        while case let device = IOIteratorNext(addedIterator), device != IO_OBJECT_NULL {
            IOObjectRelease(device)
        }
        
        // MARK: ★★★ Removed Notification ★★★ //
        let removedCallback: IOServiceMatchingCallback = { (pointer, iterator) in
            let watcher = Unmanaged<serialDetector>.fromOpaque(pointer!).takeUnretainedValue()
            watcher.removedDeviceHandler?()
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                IOObjectRelease(device)
            }
        }
        IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, matchingDict, removedCallback, opaqueSelf, &removedIterator)
        while case let device = IOIteratorNext(removedIterator), device != IO_OBJECT_NULL {
            IOObjectRelease(device)
        }
    }
    
    
    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}
#endif
