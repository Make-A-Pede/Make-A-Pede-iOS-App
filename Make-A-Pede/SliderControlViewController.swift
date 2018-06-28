//
//  SliderControlViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import VerticalSlider
import BlueCapKit

class SliderControlViewController: UIViewController {

	@IBOutlet weak var turnSlider: UISlider!
	@IBOutlet weak var speedSlider: VerticalSlider!
	
	var peripheral: Peripheral?
	var characteristic: Characteristic?
	var lastMessageTime = ProcessInfo.processInfo.systemUptime
	
	override func viewDidLoad() {
        super.viewDidLoad()
	
		turnSlider.addTarget(self, action: #selector(turnSliderReleased), for: [.touchUpInside, .touchUpOutside])
		speedSlider.addTarget(self, action: #selector(speedSliderReleased), for: [.touchUpInside, .touchUpOutside])
		
		let turnPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(turnSliderPanned(gestureRecognizer:)))
		turnSlider.addGestureRecognizer(turnPanGestureRecognizer)
	
		let speedPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(speedSliderPanned(gestureRecognizer:)))
		speedSlider.slider.addGestureRecognizer(speedPanGestureRecognizer)
		
		turnSlider.setThumbImage(UIImage(named: "sliderHandle"), for: .normal)
		speedSlider.slider.setThumbImage(UIImage(named: "sliderHandle"), for: .normal)
		
		UIGraphicsBeginImageContext(self.view.frame.size)
		UIImage(named: "bg-dark")!.draw(in: self.view.bounds)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.view.backgroundColor = UIColor(patternImage: image!)
		
		if let navController = self.navigationController, var controllers = self.navigationController?.viewControllers, controllers.count >= 2 {
			if (navController.viewControllers[controllers.count-2] as? JoystickViewController) != nil  {
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
		
		AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
		
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
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		AppUtility.lockOrientation(.all)
		
		if let peripheral = peripheral {
			peripheral.disconnect()
		}
	}
	
	func sendMessage() {
		if (ProcessInfo.processInfo.systemUptime - self.lastMessageTime > MESSAGE_INTERVAL) || (turnSlider.value == 50 && speedSlider.value == 50) {
			let x = turnSlider.value - 50
			let y = speedSlider.value - 50
			
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
			
			sendMessage(message: createMessage(left: left, right: right))
			
			self.lastMessageTime = ProcessInfo.processInfo.systemUptime
		}
	}
	
	func sendMessage(message: String) {
		print("Sending message: \(message)")
		let data = message.data(using: String.Encoding.utf8)
		
		if let data = data, let characteristic = characteristic {
			characteristic.write(data: data, type: .withoutResponse).onFailure { error in
				print("Write failed")
				print(error.localizedDescription)
			}
		}
	}
	
	func createMessage(left: Float, right: Float) -> String {
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
	
	@objc func turnSliderPanned(gestureRecognizer: UIGestureRecognizer) {
		if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
			let pointTapped: CGPoint = gestureRecognizer.location(in: self.view)
			
			let positionOfSlider: CGPoint = turnSlider.frame.origin
			let widthOfSlider: CGFloat = turnSlider.frame.size.width
			let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(turnSlider.maximumValue) / widthOfSlider)
			
			turnSlider.setValue(Float(newValue), animated: true)
			sendMessage()
		} else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
			turnSlider.setValue(50, animated: true)
			sendMessage()
		}
	}
	
	@objc func speedSliderPanned(gestureRecognizer: UIGestureRecognizer) {
		if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
			let pointTapped: CGPoint = gestureRecognizer.location(in: self.view)
			
			let positionOfSlider: CGPoint = speedSlider.frame.origin
			let heightOfSlider: CGFloat = speedSlider.frame.size.height
			let newValue = ((pointTapped.y - positionOfSlider.y) * CGFloat(speedSlider.maximumValue) / heightOfSlider)
			
			speedSlider.slider.setValue(100 - Float(newValue), animated: true)
			sendMessage()
		} else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
			speedSlider.slider.setValue(50, animated: true)
			sendMessage()
		}
	}
	
	@objc func turnSliderReleased() {
		turnSlider.setValue(50, animated: true)
		sendMessage()
	}
	
	@objc func speedSliderReleased() {
		speedSlider.slider.setValue(50, animated: true)
		sendMessage()
	}

	@IBAction func turnSliderChanged(_ sender: Any) {
		sendMessage()
	}
	@IBAction func speedSliderChanged(_ sender: Any) {
		sendMessage()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? JoystickViewController {
			vc.peripheral = peripheral
		} else if let vc = segue.destination as? ArrowControlViewController {
			vc.peripheral = peripheral
		}
	}
}
