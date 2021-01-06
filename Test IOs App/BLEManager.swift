//
//  BLEManager.swift
//  Test IOs App
//
//  Created by Lenart Velkavrh on 14/12/2020.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
  let id: Int
  let name: String
  let rssi: Int
  let peripheral: CBPeripheral
}

class BLEManager: NSObject, ObservableObject, CBPeripheralDelegate, CBCentralManagerDelegate {
  // Properties
  private var centralManager: CBCentralManager!
  private var peripheral: CBPeripheral!
  private var userDefaultsKey = "pairedDeviceIds"
  
  var userDefaultsManager = UserDefaultsManager()
  
  let batteryUUID = CBUUID(string: "180F")
  
  @Published var discoveredPeripherals = [Peripheral]()
  @Published var pairedPeripherals = [CBPeripheral]()
  @Published var peripheralValues = [UUID: UInt8]()
  
  @Published var isSwitchedOn = false
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.meerkat.app"])
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      print("central.state is .unknown")
      isSwitchedOn = false
    case .resetting:
      print("central.state is .resetting")
      isSwitchedOn = false
    case .unsupported:
      print("central.state is .unsupported")
      isSwitchedOn = false
    case .unauthorized:
      print("central.state is .unauthorized")
      isSwitchedOn = false
    case .poweredOff:
      print("central.state is .poweredOff")
      isSwitchedOn = false
      resetPeripheralValues()
    case .poweredOn:
      print("central.state is .poweredOn")
      isSwitchedOn = true
      handleBluetoothOn()
    @unknown default:
      print("central.state is .default")
    }
  }
  
  func resetPeripheralValues() {
    peripheralValues = [UUID: UInt8]()
  }
  
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    print("willRestoreState");
    let peripheralsToRestore = dict[CBCentralManagerRestoredStatePeripheralsKey] as! [CBPeripheral]
    pairedPeripherals.append(contentsOf: peripheralsToRestore)
  }
  
  func getKnownDevices() {
    let knownIds = userDefaultsManager.getKnownDevices()
    
    for id in knownIds {
      print(id)
      if let uuid = UUID(uuidString: id) {
        let retrieved = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        for retrievedPeripheral in retrieved {
          if !pairedPeripherals.contains(where: {$0.identifier == uuid}) {
            pairedPeripherals.append(retrievedPeripheral)
          }
        }
      }
    }
  }
  
  
  func handleBluetoothOn() {
    getKnownDevices()
    if pairedPeripherals.isEmpty {
      startScanning()
    } else {
      for peripheral in pairedPeripherals {
        connectToPeripheral(peripheral: peripheral)
      }
    }
  }
  
  func startScanning() {
    print("start scanning")
    centralManager.scanForPeripherals(withServices: nil, options: nil)
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    var peripheralName: String!
    
    if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
      peripheralName = name
    }
    else {
      peripheralName = "Unknown"
    }
    
    let newPeripheral = Peripheral(id: discoveredPeripherals.count, name: peripheralName, rssi: RSSI.intValue, peripheral: peripheral)
    
    discoveredPeripherals.append(newPeripheral)
  }
  
  func stopScanning() {
    print("stop scanning")
    centralManager.stopScan()
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("didConnect", peripheral.name ?? "unknown")
    if let index = pairedPeripherals.firstIndex(where: {$0.identifier == peripheral.identifier}) {
      print("updating")
      pairedPeripherals[index] = peripheral
    } else {
      pairedPeripherals.append(peripheral)
    }
    peripheral.delegate = self
    
    peripheral.discoverServices([batteryUUID])
    
    
    storeConnected(peripheral: peripheral)
  }
  
  
  func storeConnected(peripheral: CBPeripheral) {
    let id = peripheral.identifier
    userDefaultsManager.savePairedDevice(identifier: id.uuidString)
  }
  
  
  func connectToPeripheral(peripheral: CBPeripheral) {
    centralManager.connect(peripheral)
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("didDisconnect", peripheral.name ?? "unknown")
    print(error ?? "")
    if let index = pairedPeripherals.firstIndex(where: {$0.identifier == peripheral.identifier}) {
      pairedPeripherals[index] = peripheral
    }
    peripheralValues.removeValue(forKey: peripheral.identifier)
    
    centralManager.connect(peripheral)
  }
  
  func cancelConnection(index: IndexSet.Element) {
    let peripheralToRemove = pairedPeripherals[index]
    centralManager.cancelPeripheralConnection(pairedPeripherals[index])
    
    var devices = userDefaultsManager.getKnownDevices()
    devices.removeAll(where: {$0 == peripheralToRemove.identifier.uuidString})
    
    
    pairedPeripherals.remove(at: index)
    
    userDefaultsManager.overridePairedDevices(knownIds: devices)
  }
  
  //  peripheral methods
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    print("did discover included services", service)
  }
  
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print("did discover services", peripheral)
    print(error ?? "")
    for service in peripheral.services! {
      if (service.uuid == batteryUUID) {
        peripheral.discoverCharacteristics(nil, for: service)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    print("did discover characteristics", service)
    print(error ?? "")
    if let characteristics = service.characteristics {
      print("characteristic", characteristics)
      for characteristic in characteristics {
        peripheral.readValue(for: characteristic)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    print("did update value for", characteristic)
    let identifier = characteristic.service.peripheral.identifier
    if let batteryLevel = characteristic.value?[0] {
      peripheralValues.updateValue(batteryLevel, forKey: identifier)
    }
  }
}
