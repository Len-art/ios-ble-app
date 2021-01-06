//
//  ContentView.swift
//  Test IOs App
//
//  Created by Lenart Velkavrh on 14/12/2020.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
  @ObservedObject var bleManager = BLEManager()
  var body: some View {
    VStack (spacing: 10) {
      Text("Devices In Range")
        .font(.largeTitle)
        .frame(maxWidth: .infinity, alignment: .center)
      List(bleManager.discoveredPeripherals) { data in
        Button(action: {
          bleManager.stopScanning()
          bleManager.connectToPeripheral(peripheral: data.peripheral)
        }) {
          Text(data.name)
          Spacer()
          Text(String(data.rssi))
        }
      }.frame(height: 300)
      
      
      if bleManager.isSwitchedOn {
        Text("Bluetooth active").foregroundColor(.green)
      } else {
        Text("Bluetooth inactive").foregroundColor(.red)
      }
      
      List{
        ForEach(bleManager.pairedPeripherals,  id: \.identifier) {connectedPeripheral in
          HStack {
            Text("\(connectedPeripheral.name!) is \(getConnectedValue(val: connectedPeripheral.state))")
            if let batteryLevelInteger = bleManager.peripheralValues[connectedPeripheral.identifier] {
              if let batteryLevel = String(batteryLevelInteger) {
                Text("- Battery: \(batteryLevel)%")
              }
            }
          }
        }.onDelete(perform: deleteFromList)
      }
      
      HStack (spacing: 30) {
        Button(action: { self.bleManager.startScanning()}) {
          Text("Start Scanning")
        }
        Button(action: { self.bleManager.stopScanning()}) {
          Text("Stop Scanning")
        }
      }
    }
  }
  
  func deleteFromList(at offsets: IndexSet) {
    print(offsets)
    for index in offsets {
      bleManager.cancelConnection(index: index)
    }
    
    
  }
  
  func getConnectedValue(val: CBPeripheralState) -> String {
    switch val {
    case CBPeripheralState.connected:
      return "connected"
    default:
      return "not connected"
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

