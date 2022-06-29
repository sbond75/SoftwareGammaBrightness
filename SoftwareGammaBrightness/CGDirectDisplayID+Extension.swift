// Based on https://github.com/MonitorControl/MonitorControl/blob/fe3c463df829de7b5221f7bcbb38d99842fe37a1/MonitorControl/Extensions/CGDirectDisplayID%2BExtension.swift

import Cocoa

public extension CGDirectDisplayID {
  var vendorNumber: UInt32? {
    return CGDisplayVendorNumber(self)
  }

  var modelNumber: UInt32? {
    return CGDisplayModelNumber(self)
  }

  var serialNumber: UInt32? {
    return CGDisplaySerialNumber(self)
  }
}
