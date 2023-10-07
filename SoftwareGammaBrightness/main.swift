// Based on https://github.com/MonitorControl/MonitorControl/blob/fe3c463df829de7b5221f7bcbb38d99842fe37a1/MonitorControl/AppDelegate.swift

//
//  main.swift
//  SoftwareGammaBrightness
//
//  Created by sbond75 on 6/29/22.
//

import Foundation

let debugSw: Bool = false
func updateDisplays(dispatchedReconfigureID: Int = 0, firstrun: Bool = false) {
//  guard self.sleepID == 0, dispatchedReconfigureID == self.reconfigureID else {
//    return
//  }
//  os_log("Request for updateDisplay with reconfigreID %{public}@", type: .info, String(dispatchedReconfigureID))
//  self.reconfigureID = 0
  DisplayManager.shared.clearDisplays()
  var onlineDisplayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
  var displayCount: UInt32 = 0
  guard CGGetOnlineDisplayList(10, &onlineDisplayIDs, &displayCount) == .success else {
    print("Unable to get display list.") //os_log("Unable to get display list.", type: .info)
    return
  }
  for onlineDisplayID in onlineDisplayIDs where onlineDisplayID != 0 {
    let name = DisplayManager.shared.getDisplayNameByID(displayID: onlineDisplayID)
    let id = onlineDisplayID
    let vendorNumber = CGDisplayVendorNumber(onlineDisplayID)
    let modelNumber = CGDisplayVendorNumber(onlineDisplayID)
    let display: Display
    var isVirtual: Bool = false
    if #available(macOS 11.0, *) {
      if let dictionary = ((CoreDisplay_DisplayCreateInfoDictionary(onlineDisplayID))?.takeRetainedValue() as NSDictionary?) {
        let isVirtualDevice = dictionary["kCGDisplayIsVirtualDevice"] as? Bool
        let displayIsAirplay = dictionary["kCGDisplayIsAirPlay"] as? Bool
        if isVirtualDevice ?? displayIsAirplay ?? false {
          isVirtual = true
        }
      }
    }
    if !debugSw, CGDisplayIsBuiltin(onlineDisplayID) != 0 { // MARK: (point of interest for testing)
      display = InternalDisplay(id, name: name, vendorNumber: vendorNumber, modelNumber: modelNumber, isVirtual: isVirtual)
    } else {
      display = ExternalDisplay(id, name: name, vendorNumber: vendorNumber, modelNumber: modelNumber, isVirtual: isVirtual)
    }
    DisplayManager.shared.addDisplay(display: display)
  }
//  self.updateArm64AVServices()
//  if firstrun {
//    DisplayManager.shared.resetSwBrightnessForAllDisplays(settingsOnly: true)
//  }
//  NotificationCenter.default.post(name: Notification.Name(Utils.PrefKeys.displayListUpdate.rawValue), object: nil)
//  self.updateMenus()
//  if !firstrun {
//    if prefs.bool(forKey: Utils.PrefKeys.fallbackSw.rawValue) || prefs.bool(forKey: Utils.PrefKeys.lowerSwAfterBrightness.rawValue) {
//      DisplayManager.shared.restoreSwBrightnessForAllDisplays(async: true)
//    }
//  }
//  updateMediaKeyTap()
}

func reset() {
    DisplayManager.shared.getAffectedDisplays()?.forEach{$0.resetSwBrightness()} // 100 is default
}

updateDisplays()
let displays = DisplayManager.shared.getAffectedDisplays()!
displays.forEach{print($0.getSwBrightness())} // 100 is default
//displays.forEach{$0.setSwBrightness(value: 30, smooth: true)}
displays.forEach{$0.setSwBrightness(value:
                                    //10
                                    //20
                                        32 //good
                                        //37
                                        //35
                                    //40
                                    ///45
                                    //50
                                    , smooth: false, redFactor: 1.075, greenFactor: 0.9, blueFactor: 0.8)}

dispatchMain()
//displays.forEach{$0.swBrightnessSemaphore.wait()}
//ensureGlobalQueuesDrained()
//Thread.sleep(forTimeInterval: 5)
