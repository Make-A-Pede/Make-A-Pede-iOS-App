//
//  ViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class JoystickViewController: UIViewController {
	@IBOutlet weak var joystick: JoystickView!
	
	var peripheral: Peripheral?
	var characteristic: Characteristic?
	var lastMessageTime = ProcessInfo.processInfo.systemUptime
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UIGraphicsBeginImageContext(self.view.frame.size)
		UIImage(named: "bg-dark")!.draw(in: self.view.bounds)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.view.backgroundColor = UIColor(patternImage: image!)
		
		if let navController = self.navigationController, var controllers = self.navigationController?.viewControllers, controllers.count >= 2 {
			if (navController.viewControllers[controllers.count-2] as? SliderControlViewController) != nil  {
				controllers.remove(at: controllers.count-2)
				navController.setViewControllers(controllers, animated: true)
			} else if (navController.viewControllers[controllers.count-2] as? ArrowControlViewController) != nil  {
				controllers.remove(at: controllers.count-2)
				navController.setViewControllers(controllers, animated: true)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
		
		if let peripheral = peripheral {
			let connectionFuture = peripheral.connect(connectionTimeout: 10.0)
			connectionFuture.flatMap() { [weak peripheral] () -> Future<Void> in
				guard let peripheral = peripheral else {
					throw AppError.unlikely
				}
				
				return peripheral.discoverServices([serviceUUID])
			}.flatMap { [weak peripheral] () -> Future<Void> in
				guard let peripheral = peripheral, let service = peripheral.services(withUUID: serviceUUID)?.first else {
					throw AppError.serviceNotFound
				}
				
				return service.discoverCharacteristics([characteristicUUID])
			}.map { [weak peripheral] () in
				guard let peripheral = peripheral, let service = peripheral.services(withUUID: serviceUUID)?.first else {
					throw AppError.serviceNotFound
				}
				guard let dataCharacteristic = service.characteristics(withUUID: characteristicUUID)?.first else {
					throw AppError.dataCharactertisticNotFound
				}
				self.characteristic = dataCharacteristic
			}.onFailure { [weak peripheral] error in
				switch error {
				case PeripheralError.disconnected:
					peripheral?.reconnect()
				case AppError.serviceNotFound:
					print("Service not found")
					break
				case AppError.dataCharactertisticNotFound:
					print("Characteristic not found")
					break
				default:
					break
				}
			}
		}
		
		joystick.setJoystickListener() { x, y in
			if (ProcessInfo.processInfo.systemUptime - self.lastMessageTime > MESSAGE_INTERVAL) || (x == 0 && y == 0) {
				print("X: \(x), Y: \(y)")
				
				let dataString = self.createMessage(x: x, y: y)
				print("Message: \(dataString)")
				self.sendMessage(message: dataString)
				
				self.lastMessageTime = ProcessInfo.processInfo.systemUptime
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		AppUtility.lockOrientation(.all)
		
		if let peripheral = peripheral {
			peripheral.disconnect()
		}
	}
	
	func sendMessage(message: String) {
		let data = message.data(using: String.Encoding.utf8)
		
		if let data = data, let characteristic = characteristic {
			characteristic.write(data: data, type: .withoutResponse).onFailure { error in
				print("Write failed")
				print(error.localizedDescription)
			}
		}
	}
	
	func createMessage(x: CGFloat, y: CGFloat) -> String {
		var left = y+x;
		var right = y-x;
		
		if left.sign != right.sign {
			if y >= 0 {
				left = max(0, left)
				right = max(0, right)
			} else {
				left = min(0, left)
				right = min(0, right)
			}
		}
		
		if y < 0 {
			let temp = left
			left = right
			right = temp
		}
		
		left = left * (255/50)
		right = right * (255/50)
		
		left = min(left, 255)
		left = max(left, -255)
		
		right = min(right, 255)
		right = max(right, -255)
		
		print("Left: \(left), Right: \(right)")
		
		left = left + 255
		right = right + 255
		
		return createMessage(left: left, right: right)
	}
	
	func createMessage(left: CGFloat, right: CGFloat) -> String {
		var leftString = Int(left).trimToLength(length: 3)
		var rightString = Int(right).trimToLength(length: 3)
		
		while leftString.count < 3 {
			leftString = "0" + leftString
		}
		
		while rightString.count < 3 {
			rightString = "0" + rightString
		}
		
		return leftString + ":" + rightString + ":"
	}
	
	func createMessage(radius: CGFloat, angle: CGFloat) -> String {
		var degrees = degreesFromRadians(angle)
		
		if degrees < 0 {
			degrees = 360-abs(degrees)
		}
		
		var radiusString = Int(radius).trimToLength(length: 3)
		var angleString = Int(degrees).trimToLength(length: 3)
		
		while radiusString.count < 3 {
			radiusString = "0" + radiusString
		}
		
		while angleString.count < 3 {
			angleString = "0" + angleString
		}
		
		return radiusString + ":" + angleString + ":"
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? SliderControlViewController {
			vc.peripheral = peripheral
		} else if let vc = segue.destination as? ArrowControlViewController {
			vc.peripheral = peripheral
		}
	}
}
