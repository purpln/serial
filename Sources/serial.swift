import AppKit
import IOKit
import IOKit.serial

public final class serial:ObservableObject{
    @Published var ports:[String] = []
    
    public private(set) var availablePorts = [serialPort]()
    //public var updatedAvailablePortsHandler: (() -> Void)?

    private let detector = serialDetector()
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    
    public init() {
        registerNotifications()
        setAvailablePorts()
    }
    
    deinit {
        let wsnc = NSWorkspace.shared.notificationCenter
        if let sleepObserver = sleepObserver {
            wsnc.removeObserver(sleepObserver)
        }
        if let wakeObserver = wakeObserver {
            wsnc.removeObserver(wakeObserver)
        }
        let nc = NotificationCenter.default
        if terminateObserver != nil {
            nc.removeObserver(terminateObserver!)
        }
    }
    
    // MARK: ★★★ Notifications ★★★
    private func registerNotifications() {
        
        // MARK: ★★★ USB Detector ★★★
        detector.addedDeviceHandler = {
            // It is necessary to wait for a while to be updated.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.addedPorts()
            }
        }
        detector.removedDeviceHandler = {
            self.removedPorts()
        }
        detector.start()
        
        // MARK: ★★★ Sleep/Wake ★★★
        let wsnc = NSWorkspace.shared.notificationCenter
        sleepObserver = wsnc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.availablePorts.forEach { (port) in
                if port.state == .open {
                    port.fallSleep()
                }
            }
        }
        wakeObserver = wsnc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.availablePorts.forEach { (port) in
                if port.state == .sleeping {
                    port.wakeUp()
                }
            }
        }
        
        // MARK: ★★★ Terminate ★★★
        let nc = NotificationCenter.default
        terminateObserver = nc.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.availablePorts.forEach({ (port) in
                port.close()
            })
            self?.availablePorts.removeAll()
        }
    }
    
    // MARK: ★★★ Serial Ports ★★★
    private func setAvailablePorts() {
        let device = findDevice()
        let portList = getPortList(device)
        portList.forEach { portName in
            ports.append(portName)
            availablePorts.append(serialPort(portName))
        }
    }
    
    private func addedPorts() {
        let device = findDevice()
        let portList = getPortList(device)
        portList.forEach { portName in
            if !availablePorts.contains(where: { port -> Bool in
                return port.name == portName
            }) {
                availablePorts.insert(serialPort(portName), at: 0)
            }
            
            if !ports.contains(portName){
                ports.insert(portName, at: 0)
            }
        }
        //updatedAvailablePortsHandler?()
    }
    
    private func removedPorts() {
        let device = findDevice()
        let portList = getPortList(device)
        let removedPorts: [serialPort] = availablePorts.filter { (port) -> Bool in
            return !portList.contains(port.name)
        }
        removedPorts.forEach { (port) in
            port.portRemoved()
            availablePorts = availablePorts.filter({ (availablePort) -> Bool in
                return port.name != availablePort.name
            })
            ports = ports.filter{$0 != port.name}
        }
        //updatedAvailablePortsHandler?()
    }
    
    private func findDevice() -> io_iterator_t {
        var portIterator: io_iterator_t = 0
        let matchingDict: CFMutableDictionary = IOServiceMatching(kIOSerialBSDServiceValue)
        let typeKey_cf: CFString = kIOSerialBSDTypeKey as NSString
        let allTypes_cf: CFString = kIOSerialBSDAllTypes as NSString
        let typeKey = Unmanaged.passRetained(typeKey_cf).autorelease().toOpaque()
        let allTypes = Unmanaged.passRetained(allTypes_cf).autorelease().toOpaque()
        CFDictionarySetValue(matchingDict, typeKey, allTypes)
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &portIterator)
        if result != KERN_SUCCESS {
            print("error")
            return 0
        }
        return portIterator
    }
    
    private func getPortList(_ iterator: io_iterator_t) -> [String] {
        var ports = [String]()
        while case let object = IOIteratorNext(iterator), object != IO_OBJECT_NULL {
            let cfKey: CFString = kIOCalloutDeviceKey as NSString
            let cfStr = IORegistryEntryCreateCFProperty(object, cfKey, kCFAllocatorDefault, 0)!.takeUnretainedValue()
            ports.append(cfStr as! String)
            IOObjectRelease(object)
        }
        IOObjectRelease(iterator)
        return ports.reversed()
    }
    
}
