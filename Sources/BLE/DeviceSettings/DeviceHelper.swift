//
//  DeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import SwiftyBluetooth
import CoreBluetooth
import OSLog

final class DeviceHelper {
    static let shared = DeviceHelper()
    
    let devicesSettingsCollection = DevicesSettingsCollection()
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DeviceHelper.self)
    )
    
    private init() {}
    
    var hasPairedDevices: Bool {
        devicesSettingsCollection.hasPairedDevices
    }
    
    var connectedDevices = [Device]()
    
    func restoreConnectedDevices(with peripherals: [Peripheral]) {
        if let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() {
           let devices = DeviceHelper.shared.getDevicesFrom(peripherals: peripherals, pairedDevices: pairedDevices)
            updateConnected(devices: devices)
        } else {
            Self.logger.warning("restoreConnectedDevices peripherals is empty")
        }
    }
    
    func updateConnected(devices: [Device]) {
        devices.forEach { device in
            if !connectedDevices.contains(where: { $0.id == device.id }) {
                device.peripheral?.connect(withTimeout: 10) { [weak self] result in
                    guard let self else { return }
                    if case .success = result {
                        device.addObservers()
                        device.notifyRSSI()
                        DeviceHelper.shared.setDevicePaired(device: device, isPaired: true)
                    }
                    connectedDevices.append(device)
                }
            }
        }
    }
    
    func addConnected(device: Device) {
        guard !connectedDevices.contains(where: { $0.id == device.id }) else {
            return
        }
        connectedDevices.append(device)
        print("addConnected: \(connectedDevices)")
    }
    
    func removeDisconnected(device: Device) {
        connectedDevices = connectedDevices.filter { $0.id != device.id }
        print("remove: \(connectedDevices)")
    }
    
    func getSettingsForPairedDevices() -> [DeviceSettings]? {
        devicesSettingsCollection.getSettingsForPairedDevices()
    }
    
//    func getDevicesFromDeviceSettings(items: [DeviceSettings]) -> [Device] {
//        return items.map{ item in
//            let device = Device()
//            device.deviceName = item.deviceName
//            device.deviceType = item.deviceType
//            device.addObservers()
//            return device
//        }
//    }
    
    func getDevicesFrom(peripherals: [Peripheral], pairedDevices: [DeviceSettings]) -> [Device] {
        return peripherals.map { item in
            if let savedDevice = pairedDevices.first(where: { $0.deviceId == item.identifier.uuidString }) {
                let device = getDeviceFor(type: savedDevice.deviceType)
                device.deviceName = savedDevice.deviceName
                device.deviceType = savedDevice.deviceType
                device.peripheral = item
                device.addObservers()
                return device
            } else {
                fatalError("getDevicesFrom")
                // TODO: use services
               // device.deviceName = item.name ?? ""
                //device.deviceType = savedDevice.deviceType
            }
        }
    }
        
    func isDeviceEnabled(for id: String) -> Bool {
        if let deviceSettings = devicesSettingsCollection.getDeviceSettings(deviceId: id) {
            return deviceSettings.deviceEnabled
        }
        return false
    }
    
    func setDevicePaired(device: Device, isPaired: Bool) {
        if isPaired {
            if !isPairedDevice(id: device.id) {
                devicesSettingsCollection.createDeviceSettings(device: device, deviceEnabled: true)
            }
        } else {
            dropUnpairedDevice(device: device)
        }
    }
    
    func isPairedDevice(id: String) -> Bool {
        devicesSettingsCollection.getDeviceSettings(deviceId: id) != nil
    }
    
    func changeDeviceName(with id: String, name: String) {
        devicesSettingsCollection.changeDeviceName(with: id, name: name)
    }
    
    private func dropUnpairedDevice(device: Device) {
        device.peripheral?.disconnect { result in }
        devicesSettingsCollection.removeDeviceSetting(with: device.id)
    }
    
    private func getDeviceFor(type: DeviceType) -> Device {
        switch type {
        case .BLE_HEART_RATE:
            return BLEHeartRateDevice()
        default:
            fatalError("not impl")
        }
    }
}

extension DeviceHelper {
    func clearPairedDevices() {
        // add test func
    }
}
