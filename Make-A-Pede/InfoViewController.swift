//
//  InfoViewController.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit

class InfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		UIGraphicsBeginImageContext(self.view.frame.size)
		UIImage(named: "bg-dark")!.draw(in: self.view.bounds)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		self.view.backgroundColor = UIColor(patternImage: image!)
    }
	
	@IBAction func linkClicked(_ sender: Any) {
		if let button = sender as? UIButton {
			if let link = button.currentTitle {
				openWebsite(url: link)
			}
		}
	}
	
	func openWebsite(url: String) {
		let url = URL(string: url)
		if #available(iOS 10.0, *) {
			UIApplication.shared.open(url!)
		} else {
			UIApplication.shared.openURL(url!)
		}
	}
}
