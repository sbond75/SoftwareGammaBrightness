// Based on https://github.com/MonitorControl/MonitorControl/blob/fe3c463df829de7b5221f7bcbb38d99842fe37a1/MonitorControl/Model/Display.swift

//
//  Display.swift
//  MonitorControl
//
//  Created by Joni Van Roost on 24/01/2020.
//  Copyright © 2020 MonitorControl. All rights reserved.
//

import Foundation
import os.log

enum OSDImage: Int64 {
  case brightness = 1
  case audioSpeaker = 3
  case audioSpeakerMuted = 4
}

class Display {
  internal let identifier: CGDirectDisplayID
  internal let name: String
  internal var vendorNumber: UInt32?
  internal var modelNumber: UInt32?
  internal var isEnabled: Bool {
    get {
      self.prefs.object(forKey: "\(self.identifier)-state") as? Bool ?? true
    }
    set {
      self.prefs.set(newValue, forKey: "\(self.identifier)-state")
    }
  }

  var forceSw: Bool {
    get {
      return self.prefs.bool(forKey: "forceSw-\(self.identifier)")
    }
    set {
      self.prefs.set(newValue, forKey: "forceSw-\(self.identifier)")
      os_log("Set `forceSw` to: %{public}@", type: .info, String(newValue))
//      print("Set `forceSw` to: \(String(newValue))")
    }
  }

  var isVirtual: Bool = false

  var defaultGammaTableRed = [CGGammaValue](repeating: 0, count: 256)
  var defaultGammaTableGreen = [CGGammaValue](repeating: 0, count: 256)
  var defaultGammaTableBlue = [CGGammaValue](repeating: 0, count: 256)
  var defaultGammaTableSampleCount: UInt32 = 0
  var defaultGammaTablePeak: Float = 1

  private let prefs = UserDefaults.standard

  internal init(_ identifier: CGDirectDisplayID, name: String, vendorNumber: UInt32?, modelNumber: UInt32?, isVirtual: Bool = false) {
    self.identifier = identifier
    self.name = name
    self.vendorNumber = vendorNumber
    self.modelNumber = modelNumber
    self.isVirtual = isVirtual
    self.swUpdateDefaultGammaTable()
  }

  func stepBrightness(isUp _: Bool, isSmallIncrement _: Bool) {}

  func setFriendlyName(_ value: String) {
    self.prefs.set(value, forKey: "friendlyName-\(self.identifier)")
  }

  func getFriendlyName() -> String {
    return self.prefs.string(forKey: "friendlyName-\(self.identifier)") ?? self.name
  }

//  func getShowOsdDisplayId() -> CGDirectDisplayID {
//    if CGDisplayIsInHWMirrorSet(self.identifier) != 0 || CGDisplayIsInMirrorSet(self.identifier) != 0, CGDisplayMirrorsDisplay(self.identifier) != 0 {
//      for mirrorMaestro in DisplayManager.shared.getAllNonVirtualDisplays() where CGDisplayMirrorsDisplay(self.identifier) == mirrorMaestro.identifier {
//        if let externalMirrorMaestro = mirrorMaestro as? ExternalDisplay, externalMirrorMaestro.isSw() {
//          var thereAreOthers = false
//          for mirrorMember in DisplayManager.shared.getAllNonVirtualDisplays() where CGDisplayMirrorsDisplay(mirrorMember.identifier) == CGDisplayMirrorsDisplay(self.identifier) && mirrorMember.identifier != self.identifier {
//            thereAreOthers = true
//          }
//          if !thereAreOthers {
//            return externalMirrorMaestro.identifier
//          }
//        }
//      }
//    }
//    return self.identifier
//  }

  func swUpdateDefaultGammaTable() {
    CGGetDisplayTransferByTable(self.identifier, 256, &self.defaultGammaTableRed, &self.defaultGammaTableGreen, &self.defaultGammaTableBlue, &self.defaultGammaTableSampleCount)
    let redPeak = self.defaultGammaTableRed.max() ?? 0
    let greenPeak = self.defaultGammaTableGreen.max() ?? 0
    let bluePeak = self.defaultGammaTableBlue.max() ?? 0
    self.defaultGammaTablePeak = max(redPeak, greenPeak, bluePeak)
  }

  func swBrightnessTransform(value: Float, reverse: Bool = false) -> Float {
    let lowTreshold: Float = 0.1 // We don't allow decrease lower than 5% for safety reasons and because some displays blank off after a while on full black screen due to energy saving settings
    if !reverse {
      return value * (1 - lowTreshold) + lowTreshold
    } else {
      return (value - lowTreshold) / (1 - lowTreshold)
    }
  }

  let swBrightnessSemaphore = DispatchSemaphore(value: 1)
    func setSwBrightness(value: UInt8, smooth: Bool = false) { //}-> Bool {
    let brightnessValue: UInt8 = min(getSwMaxBrightness(), value)
    var currentValue = Float(self.getSwBrightnessPrefValue()) / Float(self.getSwMaxBrightness())
    self.saveSwBirghtnessPrefValue(Int(brightnessValue))
    var newValue = Float(Float(brightnessValue)) / Float(self.getSwMaxBrightness())
    currentValue = self.swBrightnessTransform(value: currentValue)
    newValue = self.swBrightnessTransform(value: newValue)
    os_log("setting software brightness to: %{public}@", type: .debug, String(newValue))
//    print("setting software brightness to: \(String(newValue))")
    if smooth {
        fatalError("TODO: not yet implemented") // TODO: Make this like the else branch of this if statement.
//      DispatchQueue.global(qos: .userInteractive).async {
//        self.swBrightnessSemaphore.wait()
//        for transientValue in stride(from: currentValue, to: newValue, by: 0.005 * (currentValue > newValue ? -1 : 1)) {
//          let gammaTableRed = self.defaultGammaTableRed.map { $0 * transientValue }
//          let gammaTableGreen = self.defaultGammaTableGreen.map { $0 * transientValue }
//          let gammaTableBlue = self.defaultGammaTableBlue.map { $0 * transientValue }
////          guard app.reconfigureID == 0 else {
////            return
////          }
//          os_log("smooth: setting software brightness to: %{public}@", type: .debug, String(transientValue))
////          CGSetDisplayTransferByTable(self.identifier, self.defaultGammaTableSampleCount, gammaTableRed, gammaTableGreen, gammaTableBlue)
//          Thread.sleep(forTimeInterval: 0.001) // Let's make things quick if not performed in the background
//        }
//        self.swBrightnessSemaphore.signal()
//      }
    } else {
      let gammaTableRed = self.defaultGammaTableRed.map { $0 * /* transientValue */ newValue }
      let gammaTableGreen = self.defaultGammaTableGreen.map { $0 * /* transientValue */ newValue }
      let gammaTableBlue = self.defaultGammaTableBlue.map { $0 * /* transientValue */ newValue }
      //CGSetDisplayTransferByTable(self.identifier, self.defaultGammaTableSampleCount, gammaTableRed, gammaTableGreen, gammaTableBlue)
        
        // Based on https://cpp.hotexamples.com/examples/-/-/CGGetDisplayTransferByFormula/cpp-cggetdisplaytransferbyformula-function-examples.html
        var redMin: CGGammaValue = 0, redMax: CGGammaValue = 0, redGamma: CGGammaValue = 0, greenMin: CGGammaValue = 0, greenMax: CGGammaValue = 0, greenGamma: CGGammaValue = 0, blueMin: CGGammaValue = 0, blueMax: CGGammaValue = 0, blueGamma: CGGammaValue = 0
        let err1 = CGGetDisplayTransferByFormula(self.identifier, &redMin, &redMax, &redGamma, &greenMin, &greenMax, &greenGamma, &blueMin, &blueMax, &blueGamma)
        print("Current display transfer formula values:", redMin, redMax, redGamma, greenMin, greenMax, greenGamma, blueMin, blueMax, blueGamma)
        print("err1:",err1.rawValue)
        guard err1 == .success else { fatalError() }
        
        let transientValue = -newValue
//        let err = CGSetDisplayTransferByFormula(self.identifier, transientValue, 1.0, 1.0, transientValue, 1.0, 1.0, transientValue, 1.0, 1.0) // Frosty/whitish tint, cool
//        let err2 = CGSetDisplayTransferByFormula(self.identifier, redMin + transientValue*1.1, redMax, redGamma, greenMin + transientValue*1.1, greenMax, greenGamma, blueMin + transientValue, blueMax, blueGamma)
        
        // Based on `C' = amplitude * pow(C, exponent) + offset` from https://www.w3.org/TR/SVG11/filters.html (where it says "For gamma, the function is defined by the following exponential function"), i.e. as used in within contentscripts/content.js in https://chrome.google.com/webstore/detail/video-styler-brightness-a/bfmgdnjlifbmedglimhnbhgkefanaiep?hl=en : {"
        /*
         <svg style="display: none;"><filter id="_videostyler_filter_"><feComponentTransfer>
           <feFuncR type="gamma" amplitude="1" exponent="0.5" offset="0"></feFuncR>
           <feFuncG type="gamma" amplitude="1" exponent="0.5" offset="0"></feFuncG>
           <feFuncB type="gamma" amplitude="1" exponent="0.5" offset="0"></feFuncB>
         </feComponentTransfer></filter></svg>
         */
        // "}
        // and also based on https://developer.apple.com/documentation/coregraphics/1454126-cgsetdisplaytransferbyformula :
        // {"
        // This function uses the specified parameter values to compute a gamma correction table for the specified display. The values in the table are computed by sampling the following gamma transfer formula for a range of indices from 0 to 1:
        // value = Min + ((Max - Min) * pow(index, Gamma))
        // The resulting values are converted to a machine-specific format and loaded into display hardware.
        // "} :
        let err2 = CGSetDisplayTransferByFormula(self.identifier, redMin, redMax, redGamma + transientValue, greenMin, greenMax, greenGamma + transientValue, blueMin, blueMax, blueGamma + transientValue)
        
        print("err2:",err2.rawValue)
        guard err2 == .success else { fatalError() }
    }
    return //true
  }

  func getSwBrightness() -> UInt8 {
    var gammaTableRed = [CGGammaValue](repeating: 0, count: 256)
    var gammaTableGreen = [CGGammaValue](repeating: 0, count: 256)
    var gammaTableBlue = [CGGammaValue](repeating: 0, count: 256)
    var gammaTableSampleCount: UInt32 = 0
    if CGGetDisplayTransferByTable(self.identifier, 256, &gammaTableRed, &gammaTableGreen, &gammaTableBlue, &gammaTableSampleCount) == CGError.success {
      let redPeak = gammaTableRed.max() ?? 0
      let greenPeak = gammaTableGreen.max() ?? 0
      let bluePeak = gammaTableBlue.max() ?? 0
      let gammaTablePeak = max(redPeak, greenPeak, bluePeak)
      let peakRatio = gammaTablePeak / self.defaultGammaTablePeak
      let brightnessValue = UInt8(round(self.swBrightnessTransform(value: peakRatio, reverse: true) * Float(self.getSwMaxBrightness())))
      os_log("Current software gammatable brightness is: %{public}@", type: .debug, String(brightnessValue))
//      print("Current software gammatable brightness is: \(String(brightnessValue))")
      return brightnessValue
    }
    return self.getSwMaxBrightness()
  }

  func resetSwBrightness() { //-> Bool {
    return self.setSwBrightness(value: self.getSwMaxBrightness())
  }

  func saveSwBirghtnessPrefValue(_ value: Int) {
    self.prefs.set(value, forKey: "SwBrightness-\(self.identifier)")
  }

  func getSwBrightnessPrefValue() -> Int {
    return self.prefs.integer(forKey: "SwBrightness-\(self.identifier)")
  }

  func getSwMaxBrightness() -> UInt8 {
    return 100
  }

  func isSwBrightnessNotDefault() -> Bool {
    guard !self.isVirtual else {
      return false
    }
    if self.getSwBrightness() < self.getSwMaxBrightness() {
      return true
    }
    return false
  }

//  func showOsd(command: Command, value: Int, maxValue: Int = 100, roundChiclet: Bool = false, lock: Bool = false) {
//    guard let manager = OSDManager.sharedManager() as? OSDManager else {
//      return
//    }
//
//    var osdImage: OSDImage
//    switch command {
//    case .audioSpeakerVolume:
//      osdImage = value > 0 ? .audioSpeaker : .audioSpeakerMuted
//    case .audioMuteScreenBlank:
//      osdImage = .audioSpeakerMuted
//    default:
//      osdImage = .brightness
//    }
//
//    let filledChiclets: Int
//    let totalChiclets: Int
//
//    if roundChiclet {
//      let osdChiclet = OSDUtils.chiclet(fromValue: Float(value), maxValue: Float(maxValue))
//
//      filledChiclets = Int(round(osdChiclet))
//      totalChiclets = 16
//    } else {
//      filledChiclets = value
//      totalChiclets = maxValue
//    }
//
//    manager.showImage(osdImage.rawValue,
//                      onDisplayID: self.getShowOsdDisplayId(),
//                      priority: 0x1F4,
//                      msecUntilFade: 1000,
//                      filledChiclets: UInt32(filledChiclets),
//                      totalChiclets: UInt32(totalChiclets),
//                      locked: lock)
//  }
}
