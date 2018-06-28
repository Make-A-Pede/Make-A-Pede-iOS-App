//
//  ViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class DeviceListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	let manager = CentralManager(options: [CBCentralManagerOptionShowPowerAlertKey: true]) //(options: [CBCentralManagerOptionRestoreIdentifierKey : "com.automatadev.makeapede.central-manager" as NSString])
	
	private var data: [Peripheral] = []
	private var selectedPeripheral: Peripheral?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UIGraphicsBeginImageContext(self.view.frame.size)
		//UIImage(named: "metal-bg-l-phone")!.draw(in: self.view.bounds)
		UIImage(named: "bg-dark")!.draw(in: self.view.bounds)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.tableView.backgroundColor = UIColor(patternImage: image!)
		
		tableView.dataSource = self
		tableView.delegate = self
		
		manager.whenStateChanges().flatMap { [weak manager] state -> FutureStream<Peripheral> in
			guard let manager = manager else {
				throw AppError.unlikely
			}
			
			switch state {
			case .poweredOn:
				//return manager.startScanning(timeout: 10.0)
				return manager.startScanning(forServiceUUIDs: [serviceUUID], timeout: 10.0)
			case .poweredOff:
				throw AppError.poweredOff
			case .unauthorized, .unsupported:
				throw AppError.invalidState
			case .resetting:
				throw AppError.resetting
			case .unknown:
				throw AppError.unknown
			}
		}.andThen(completion: peripheralDiscovered).onFailure(completion: scanFailed)
	}
	
	@objc func stopScanning() {
		print("Stopping scan")
		manager.stopScanning()
	}
	
	@IBAction func rescanClicked(_ sender: Any) {
		print("Rescan clicked")
		stopScanning()
		data.removeAll()
		tableView.reloadData()
		_ = manager.startScanning(forServiceUUIDs: [serviceUUID], timeout: 10.0).andThen(completion: peripheralDiscovered)
	}
	
	func peripheralDiscovered(discoveredPeripheral: Peripheral) {
		if !self.data.contains(discoveredPeripheral) {
			self.data.append(discoveredPeripheral)
			self.tableView.beginUpdates()
			self.tableView.insertRows(at: [IndexPath(row: self.data.count-1, section: 0)], with: UITableViewRowAnimation.bottom)
			self.tableView.endUpdates()
		}
	}
	
	func scanFailed(error: Error) {
		guard let appError = error as? AppError else {
			return
		}
		switch appError {
		case .resetting:
			manager.reset()
		case .invalidState:
			let alertController = UIAlertController(title: "Error", message: "Bluetooth Low Energy is not supported by your device", preferredStyle: .alert)
			let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
			alertController.addAction(okAction)
			self.present(alertController, animated: true)
		default:
			break
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if data.count == 0 {
			let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
			let messageLabel = UILabel(frame: rect)
			messageLabel.text = "No devices available"
			messageLabel.textColor = UIColor.white
			messageLabel.numberOfLines = 0;
			messageLabel.textAlignment = .center;
			messageLabel.sizeToFit()
			
			self.tableView.backgroundView = messageLabel
			self.tableView.separatorStyle = .none
		} else {
			self.tableView.backgroundView = nil
			self.tableView.separatorStyle = .singleLine
		}
		
		return 1;
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCellIdentifier")!
		//cell.backgroundColor = UIColor.clear
		
		let peripheral = data[indexPath.row]
		
		cell.textLabel?.text = peripheral.name + ": " + peripheral.identifier.uuidString
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.backgroundColor = UIColor.clear
		cell.textLabel?.textColor = UIColor.white
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		stopScanning()
		selectedPeripheral = data[indexPath.item]
		print(selectedPeripheral!.name)
		performSegue(withIdentifier: "showSliders", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? JoystickViewController {
			vc.peripheral = selectedPeripheral
		} else if let vc = segue.destination as? SliderControlViewController {
			vc.peripheral = selectedPeripheral
		} else if let vc = segue.destination as? ArrowControlViewController {
			vc.peripheral = selectedPeripheral
		}
	}
}
