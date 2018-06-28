//
//  HomeViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit
import MaterialComponents

class HomeViewController: UIViewController {

	@IBOutlet weak var connectButton: MDCRaisedButton!
	@IBOutlet weak var websiteButton: MDCRaisedButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		connectButton.setTitle("Connect to Make-A-Pede", for: .normal)
		connectButton.sizeToFit()
		connectButton.setBackgroundColor(greenColor)
		connectButton.setTitleColor(.black, for: .normal)
		connectButton.addTarget(self, action: #selector(showConnectController), for: .touchUpInside)
		
		websiteButton.setTitle("Open Website", for: .normal)
		websiteButton.sizeToFit()
		websiteButton.setBackgroundColor(greenColor)
		websiteButton.setTitleColor(.black, for: .normal)
		websiteButton.addTarget(self, action: #selector(showWebsite), for: .touchUpInside)

        UIGraphicsBeginImageContext(self.view.frame.size)
		//UIImage(named: "metal-bg-l-phone")!.draw(in: self.view.bounds)
		UIImage(named: "bg-dark")!.draw(in: self.view.bounds)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.view.backgroundColor = UIColor(patternImage: image!)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		AppUtility.lockOrientation(.all)
	}
	
	@objc func showConnectController() {
		//performSegue(withIdentifier: "showConnectController", sender: self)
		performSegue(withIdentifier: "showDeviceList", sender: self)
	}
	
	@objc func showWebsite() {
		let url = URL(string: "http://makeapede.com")
		if #available(iOS 10.0, *) {
			UIApplication.shared.open(url!)
		} else {
			UIApplication.shared.openURL(url!)
		}
	}

}
