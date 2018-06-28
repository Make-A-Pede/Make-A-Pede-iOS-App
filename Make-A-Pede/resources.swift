//
//  resources.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import CoreBluetooth

// Colors
// r: 141, g: 200, b: 50
let redValue = CGFloat(0.55)
let greenValue = CGFloat(0.81)
let blueValue = CGFloat(0.2)

public let greenColor = UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 1.0)

// Bluetooth
public let serviceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
public let characteristicUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
public let MESSAGE_INTERVAL = 20.0/1000.0

// Coordinates
public func polarCoordinatesFrom(x: CGFloat, y: CGFloat) -> (radius: CGFloat, angle: CGFloat) {
	let radius = sqrt((x*x) + (y*y))
	let angle = atan2(y, x)
	
	return (radius, angle)
}

public func cartesianCoordinatesFrom(radius: CGFloat, angle: CGFloat) -> (x: CGFloat, y: CGFloat) {
	let x = radius * cos(angle)
	let y = radius * sin(angle)
	
	return (x, y)
}

public func degreesFromRadians(_ radians: CGFloat) -> CGFloat { return (radians * 180) / .pi }

// Extensions
extension String {
	func truncate(length: Int) -> String {
		return (self.count > length) ? String(self.prefix(length)) : self
	}
}

extension Numeric {
	func trimToLength(length: Int) -> String {
		return "\(self)".truncate(length: 3)
	}
}
