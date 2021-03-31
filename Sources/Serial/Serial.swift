import AppKit
import IOKit
import IOKit.serial

public protocol SerialProtocol {
    func ports(ports: [SerialPort])
}

public class Serial {
    public static let shared: Serial = Serial()
    public var delegate: SerialProtocol?
    public private(set) var ports = [SerialPort]()
    
    private let detector = SerialDetector()
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    
    private init() {
        registerNotifications()
        setAvailablePorts()
    }
    
    deinit {
        let wsnc = NSWorkspace.shared.notificationCenter
        if let sleepObserver = sleepObserver { wsnc.removeObserver(sleepObserver) }
        if let wakeObserver = wakeObserver { wsnc.removeObserver(wakeObserver) }
        if terminateObserver != nil { NotificationCenter.default.removeObserver(terminateObserver!) }
    }
    
    private func registerNotifications() {
        
        detector.addedDeviceHandler = {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.addedPorts()
            }
        }
        detector.removedDeviceHandler = { self.removedPorts() }
        detector.start()
        
        let wsnc = NSWorkspace.shared.notificationCenter
        sleepObserver = wsnc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.ports.forEach { (port) in
                if port.state == .open {
                    port.fallSleep()
                }
            }
        }
        wakeObserver = wsnc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.ports.forEach { (port) in
                if port.state == .sleeping {
                    port.wakeUp()
                }
            }
        }
        
        let nc = NotificationCenter.default
        terminateObserver = nc.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] (n) in
            self?.ports.forEach{ port in
                port.close()
            }
            self?.ports.removeAll()
        }
    }
    
    private func setAvailablePorts() {
        let device = findDevice()
        let portList = getPortList(device)
        portList.forEach { portName in
            ports.append(SerialPort(portName))
        }
        delegate?.ports(ports: ports)
    }
    
    private func addedPorts() {
        let device = findDevice()
        let portList = getPortList(device)
        portList.forEach { portName in
            if !ports.contains(where: { port -> Bool in
                port.port == portName
            }) {
                ports.insert(SerialPort(portName), at: 0)
            }
        }
        delegate?.ports(ports: ports)
    }
    
    private func removedPorts() {
        let device = findDevice()
        let portList = getPortList(device)
        let removedPorts: [SerialPort] = ports.filter { port -> Bool in
            !portList.contains(port.port)
        }
        removedPorts.forEach { port in
            port.portRemoved()
            ports = ports.filter { available -> Bool in
                port.port != available.port
            }
        }
        delegate?.ports(ports: ports)
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
        if result != KERN_SUCCESS { return 0 }
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
