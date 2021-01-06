//
//  UserDefaultsManager.swift
//  Test IOs App
//
//  Created by Lenart Velkavrh on 15/12/2020.
//

import Foundation

class UserDefaultsManager {
  private let defaults = UserDefaults.standard
  private var userDefaultsKey = "pairedDeviceIds"
  
  func getKnownDevices() -> [String] {
    let knownIds = defaults.object(forKey: userDefaultsKey) as? [String] ?? [String]()
    return knownIds
  }
  
  func savePairedDevice(identifier: String) {
    var knownIds = defaults.object(forKey: userDefaultsKey) as? [String] ?? [String]()
    let doesContain = knownIds.contains(identifier)
    if !doesContain {
      knownIds.append(identifier)
      defaults.set(knownIds, forKey: userDefaultsKey)
    }
  }
  
  func overridePairedDevices(knownIds: [String]) {
    defaults.set(knownIds, forKey: userDefaultsKey)
  }
}
