// Based on https://github.com/MonitorControl/MonitorControl/blob/fe3c463df829de7b5221f7bcbb38d99842fe37a1/MonitorControl/Extensions/Display%2BExtension.swift

import Foundation

extension Display: Equatable {
  static func == (lhs: Display, rhs: Display) -> Bool {
    return lhs.identifier == rhs.identifier
  }
}
