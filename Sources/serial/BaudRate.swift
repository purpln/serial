import Foundation

public enum BaudRate{
    case baud1200
    case baud2400
    case baud4800
    case baud9600
    case baud19200
    case baud38400
    case baud57600
    case baud115200
    case baud230400

    public var speed: speed_t {
        switch self {
        case .baud1200: return speed_t(B1200)
        case .baud2400: return speed_t(B2400)
        case .baud4800: return speed_t(B4800)
        case .baud9600: return speed_t(B9600)
        case .baud19200: return speed_t(B19200)
        case .baud38400: return speed_t(B38400)
        case .baud57600: return speed_t(B57600)
        case .baud115200: return speed_t(B115200)
        case .baud230400: return speed_t(B230400)
        }
    }
    
    public var description: String {
        switch self {
        case .baud1200: return "baud 1200"
        case .baud2400: return "baud 2400"
        case .baud4800: return "baud 4800"
        case .baud9600: return "baud 9600"
        case .baud19200: return "baud 19200"
        case .baud38400: return "baud 38400"
        case .baud57600: return "baud 57600"
        case .baud115200: return "baud 115200"
        case .baud230400: return "baud 230400"
        }
    }
}
