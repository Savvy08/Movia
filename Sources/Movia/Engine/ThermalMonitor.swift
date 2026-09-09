import Foundation

public final class ThermalMonitor: ObservableObject {
    public static let shared = ThermalMonitor()
    
    @Published public private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    @Published public private(set) var statusMessage: String = "Apple Neural Engine активен"
    @Published public private(set) var isThrottled: Bool = false
    
    private init() {
        let current = ProcessInfo.processInfo.thermalState
        self.thermalState = current
        self.updateState(current)
        
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let state = ProcessInfo.processInfo.thermalState
            self.thermalState = state
            self.updateState(state)
        }
    }
    
    private func updateState(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal, .fair:
            self.isThrottled = false
            self.statusMessage = "Apple Neural Engine активен"
        case .serious:
            self.isThrottled = true
            self.statusMessage = "Умеренный нагрев: снижена скорость"
        case .critical:
            self.isThrottled = true
            self.statusMessage = "Высокая температура: защита от троттлинга"
        @unknown default:
            self.isThrottled = false
            self.statusMessage = "Apple Neural Engine активен"
        }
    }
}
