import Foundation

enum SessionState {
    case idle
    case running
    case paused
    case completed
}

enum SessionDurationPreset: TimeInterval, CaseIterable, Identifiable {
    case five = 300
    case ten = 600
    case fifteen = 900
    case twenty = 1200
    
    var id: TimeInterval { rawValue }
    
    var label: String {
        switch self {
        case .five: return "5 min"
        case .ten: return "10 min"
        case .fifteen: return "15 min"
        case .twenty: return "20 min"
        }
    }
}
