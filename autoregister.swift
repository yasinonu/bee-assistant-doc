    
    
@MainActor
class RegisterViewModel: ObservableObject {
    // MARK: Automatic Registration
    
    @Published var watching: Bool = false
    
    public func startWatching(time: Date) {
        // Prevent starting multiple watchers
        if watching {
            print("already watching, ignoring startWatching call")
            return
        }
        watching = true
        print("watching registration time...")
        let now = Date()
        
        // If it's within 15 seconds of the start time, start polling immediately
        if now >= time.addingTimeInterval(-15) {
            print("started polling")
            startPolling()
        } else {
            // Schedule to start polling 15 seconds before the start time
            print("will start polling soon")
            let delay = max(0, time.timeIntervalSince(now) - 15)
            print("Delay until polling starts: \(delay) seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                print("started polling")
                self.startPolling()
            }
        }
    }
    
    public func startPolling() {
        Task {
            while true {
                isPolling = true
                
                print("Checking registration time")
                
                #if DEBUG
                
                let dateStr = "2026-02-01T19:36:30"
                
                let formatter = DateFormatter.app
                
                let date = formatter.date(from: dateStr)!
                
                let openRegister = Date.now >= date && Date.now <= date.addingTimeInterval(2 * 60 * 60)
                
                let check: RegistrationTimeCheck? = RegistrationTimeCheck(registrationTypeName: nil, explanation: nil, explanationCode: "kayit-zamani-bulunamadi", canStudentRegister: openRegister, canStudentWithdraw: false, canStudentDrop: openRegister, canRegisterWithAdvisor: false, canWithdrawWithAdvisor: false, canDropWithAdvisor: false, startDate: nil, endDate: nil, studentClass: 3, academicTermId: 0, academicTermCode: nil, registrationTimeList: [])
                #else
                let check = try? await service.checkRegistrationTime().registrationTimeCheckResult
                #endif
                
                
                
                print("Check: \(check?.canStudentRegister ?? false)")
                
                if let check, (check.canStudentRegister || check.canStudentDrop) {
                    print("Registration opened, updating state variables...")
                    self.canRegister = check.canStudentRegister
                    self.canDrop = check.canStudentDrop
                    
                    self.registrationType = check.registrationTypeName
                    
                    print("Can drop: \(canDrop)")
                    print("Can register: \(canRegister)")
                    
                    isPolling = false
                    watching = false
                    
                    return
                }
            }
        }
    }
    
    func register() async throws -> [ResultList] {
        let crns = crns.filter { !$0.isEmpty }
        return try await register(crns: crns)
    }
    
    func drop() async throws -> [ResultList] {
        guard let droppingCourse else {
            throw AppError.RequestFailed
        }
        
        return try await drop(crns: [droppingCourse.crn])
    }
}