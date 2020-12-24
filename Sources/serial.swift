#if os(macOS)
import Foundation

class cc {
    func pr(){
        print("cc")
    }
}

public final class serial:ObservableObject{
    @Published var ports:[String] = []
    
    private let detector = serialDetector()
    
    init(){
        
    }
    
    private func configure(){
        
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
#endif
