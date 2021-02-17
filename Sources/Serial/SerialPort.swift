import Foundation

public enum SerialPortState: Int {
    case open
    case close
    case sleeping
    case removed
}

public enum SerialParity: Int {
    case none
    case even
    case odd
}

public class SerialPort {
    private var fileDescriptor: Int32 = 0
    private var originalPortOptions = termios()
    private var readTimer: DispatchSourceTimer?
    
    public private(set) var name: String = ""
    public private(set) var state: SerialPortState = .close
    
    public var baudRate: BaudRate = .baud115200 {
        didSet { setOptions() }
    }
    public var parity:SerialParity = .none {
        didSet { setOptions() }
    }
    public var stopBits: UInt32 = 1 {
        didSet { setOptions() }
    }
    
    //
    public var received: ((_ texts: String) -> Void)?
    public var failure: ((_ port: SerialPort) -> Void)?
    public var opened: ((_ port: SerialPort) -> Void)?
    public var closed: ((_ port: SerialPort) -> Void)?
    public var removed: ((_ port: SerialPort) -> Void)?
    
    public init(_ portName: String) {
        name = portName
    }
    
    deinit {
        close()
    }
    
    private func error(_ n: Int) {
        failure?(self)
    }
    
    public func open() {
        var fd: Int32 = -1
        
        fd = Darwin.open(name.cString(using: String.Encoding.ascii)!, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if fd == -1 { return error(1) }
        if fcntl(fd, F_SETFL, 0) == -1 { return error(2) }
        
        fileDescriptor = fd
        setOptions()
        readTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        readTimer?.schedule(deadline: DispatchTime.now(),
                            repeating: DispatchTimeInterval.nanoseconds(Int(10 * NSEC_PER_MSEC)),
                            leeway: DispatchTimeInterval.nanoseconds(Int(5 * NSEC_PER_MSEC)))
        readTimer?.setEventHandler(handler: { [weak self] in
            self?.read()
        })
        readTimer?.setCancelHandler(handler: { [weak self] in
            self?.close()
        })
        readTimer?.resume()
        state = .open
        opened?(self)
    }
    
    public func close() {
        readTimer?.cancel()
        readTimer = nil
        if tcdrain(fileDescriptor) == -1 { return }
        var options = termios()
        if tcsetattr(fileDescriptor, TCSADRAIN, &options) == -1 { return }
        Darwin.close(fileDescriptor)
        state = .close
        fileDescriptor = -1
        closed?(self)
    }
    
    public func send(_ text: String) {
        if state != .open { return }
        var bytes: [UInt32] = text.unicodeScalars.map { (uni) -> UInt32 in
            return uni.value
        }
        Darwin.write(fileDescriptor, &bytes, bytes.count)
    }
    
    // ★★★ Set Options ★★★ //
    private func setOptions() {
        if fileDescriptor < 1 { return }
        var options = termios()
        if tcgetattr(fileDescriptor, &options) == -1 {
            return error(3)
        }
        cfmakeraw(&options)
        options.updateC_CC(VMIN, v: 1)
        options.updateC_CC(VTIME, v: 2)

        // DataBits
        options.c_cflag &= ~UInt(CSIZE)
        options.c_cflag |= UInt(CS8)
        
        // StopBits
        if 1 < stopBits {
            options.c_cflag |= UInt(CSTOPB)
        } else {
            options.c_cflag &= ~UInt(CSTOPB)
        }
        
        // Parity
        switch parity {
        case .none:
            options.c_cflag &= ~UInt(PARENB)
        case .even:
            options.c_cflag |= UInt(PARENB)
            options.c_cflag &= ~UInt(PARODD)
        case .odd:
            options.c_cflag |= UInt(PARENB)
            options.c_cflag |= UInt(PARODD)
        }
        
        options.c_cflag &= ~UInt(ECHO)
        options.c_cflag &= ~UInt(CRTSCTS)
        options.c_cflag &= ~UInt(CDTR_IFLOW | CDSR_OFLOW)
        options.c_cflag &= ~UInt(CCAR_OFLOW)
        
        options.c_cflag |= UInt(HUPCL)
        options.c_cflag |= UInt(CLOCAL)
        options.c_cflag |= UInt(CREAD)
        options.c_lflag &= ~UInt(ICANON | ISIG)
        
        cfsetspeed(&options, baudRate.speed)
        
        if tcsetattr(fileDescriptor, TCSANOW, &options) == -1 {
            return error(4)
        }
    }
    
    func portRemoved() {
        readTimer?.cancel()
        readTimer = nil
        if tcdrain(fileDescriptor) == -1 { return }
        if tcsetattr(fileDescriptor, TCSADRAIN, &originalPortOptions) == -1 { return }
        Darwin.close(fileDescriptor)
        state = .removed
        removed?(self)
    }
    
    func fallSleep() {
        readTimer?.suspend()
        state = .sleeping
    }
    
    func wakeUp() {
        readTimer?.resume()
        state = .open
    }
    
    private func read() {
        if state != .open { return }
        var buffer = [UInt8](repeating: 0, count: 1024)
        let readLength = Darwin.read(fileDescriptor, &buffer, 1024)
        if  readLength < 1 { return }
        let data = Data(bytes: buffer, count: readLength)
        let text = String(data: data, encoding: String.Encoding.ascii)!
        received?(text)
    }
    
}

extension termios {
    mutating func updateC_CC(_ n: Int32, v: UInt8) {
        switch n {
        case  0: c_cc.0  = v
        case  1: c_cc.1  = v
        case  2: c_cc.2  = v
        case  3: c_cc.3  = v
        case  4: c_cc.4  = v
        case  5: c_cc.5  = v
        case  6: c_cc.6  = v
        case  7: c_cc.7  = v
        case  8: c_cc.8  = v
        case  9: c_cc.9  = v
        case 10: c_cc.10 = v
        case 11: c_cc.11 = v
        case 12: c_cc.12 = v
        case 13: c_cc.13 = v
        case 14: c_cc.14 = v
        case 15: c_cc.15 = v
        case 16: c_cc.16 = v
        case 17: c_cc.17 = v
        case 18: c_cc.18 = v
        case 19: c_cc.19 = v
        default: break
        }
    }
}
