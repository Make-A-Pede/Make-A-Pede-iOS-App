//
//  ArrowControlViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import BlueCapKit

class ArrowControlViewController: UIViewController {
	@IBOutlet weak var arrows: ArrowsView!
	
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
			} else if (navController.viewControllers[controllers.count-2] as? JoystickViewController) != nil  {
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
		
		arrows.setArrowsListener { angle in
			if (ProcessInfo.processInfo.systemUptime - self.lastMessageTime > MESSAGE_INTERVAL) || (angle == 0) {
				let dataString = self.createMessage(angle: angle)
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
	
	func createMessage(angle: Int) -> String {
		switch angle {
		case 1:
			return createMessage(left: 255, right: 80)
		case 2:
			return createMessage(left: 255, right: 255)
		case 3:
			return createMessage(left: 80, right: 255)
		case -1:
			return createMessage(left: -255, right: -80)
		case -2:
			return createMessage(left: -255, right: -255)
		case -3:
			return createMessage(left: -80, right: -255)
		default:
			return createMessage(left: 0, right: 0)
		}
	}
	
	func createMessage(left: CGFloat, right: CGFloat) -> String {
		print("Left: \(left), Right: \(right)")
		
		var leftString = Int(left+255).trimToLength(length: 3)
		var rightString = Int(right+255).trimToLength(length: 3)
		
		while leftString.count < 3 {
			leftString = "0" + leftString
		}
		
		while rightString.count < 3 {
			rightString = "0" + rightString
		}
		
		return leftString + ":" + rightString + ":"
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? JoystickViewController {
			vc.peripheral = peripheral
		} else if let vc = segue.destination as? SliderControlViewController {
			vc.peripheral = peripheral
		}
	}
}
