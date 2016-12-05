//
//    The MIT License (MIT)
//
//    Copyright (c) 2016 Oktawian Chojnacki
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import UIKit

enum InsomniaMode {
    case disabled
    case always
    case whenCharging
}

protocol BatteryStateReporting : class {
    var batteryStateHandler: ((_ isPlugged: Bool) -> Void)? { get set }
}

final class Insomnia : BatteryStateReporting {

    var mode: InsomniaMode {
        didSet {
            updateInsomniaMode()
        }
    }
    private unowned let device: UIDevice
    private unowned let notificationCenter: NotificationCenter
    private unowned let application: UIApplication

    var batteryStateHandler: ((_ isPlugged: Bool) -> Void)? {
        didSet {
            notifyAboutCurrentBatteryState()
        }
    }

    init(mode: InsomniaMode,
         device: UIDevice = UIDevice.current,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         application: UIApplication = UIApplication.shared) {
        self.device = device
        self.mode = mode
        self.notificationCenter = notificationCenter
        self.application = application
        startMonitoring()
    }

    private func startMonitoring() {
        device.isBatteryMonitoringEnabled = true
        notificationCenter.addObserver(self,
                                       selector: #selector(batteryStateDidChange),
                                       name: NSNotification.Name.UIDeviceBatteryStateDidChange, object: nil)
        updateInsomniaMode()
    }

    @objc private func batteryStateDidChange(notification: NSNotification){
        updateInsomniaMode()
    }

    private func updateInsomniaMode() {
        notifyAboutCurrentBatteryState()
        application.isIdleTimerDisabled = mode == .whenCharging ? isPlugged : (mode != .disabled)
    }

    private func notifyAboutCurrentBatteryState() {
        batteryStateHandler?(isPlugged)
    }

    private var isPlugged: Bool {
        switch device.batteryState {
        case .unknown, .unplugged:
            return false
        default:
            return true
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
        device.isBatteryMonitoringEnabled = false
        application.isIdleTimerDisabled = false
    }
}
