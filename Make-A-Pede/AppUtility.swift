//
//  AppUtility.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit

struct AppUtility {
	
	static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
		
		if let delegate = UIApplication.shared.delegate as? AppDelegate {
			delegate.orientationLock = orientation
		}
	}
	
	static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
		
		self.lockOrientation(orientation)
		
		UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
	}
	
}
