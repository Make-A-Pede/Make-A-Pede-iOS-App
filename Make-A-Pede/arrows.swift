//
//  joystick.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit

class ArrowsView: UIView {
	var width: CGFloat!
	var height: CGFloat!
	var minDimen: CGFloat!
	var arrowsListener: ((Int) -> Void)?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		initView()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
		initView()
	}
	
	func initView() {
		width = self.frame.width
		height = self.frame.height
		minDimen = min(width, height)
		
		let center = CGPoint(x: width/2, y: height/2)
		
		let circle = ArrowBackgroundView(center: center, size: minDimen)
		self.addSubview(circle)
	}
	
	func setArrowsListener(listener: @escaping (Int) -> Void) {
		arrowsListener = listener
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		
		touchMove(touch: touches.first!)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesMoved(touches, with: event)
		
		touchMove(touch: touches.first!)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesEnded(touches, with: event)
		
		touchEnd()
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesCancelled(touches, with: event)
		
		touchEnd()
	}
	
	func touchMove(touch: UITouch) {
		let location = touch.location(in: self)
		
		let center = CGPoint(x: width/2, y: height/2)
		let x = (location.x - center.x) * (100 / (minDimen/2))
		let y = (center.y - location.y) * (100 / (minDimen/2))
		
		var (radius, angle) = polarCoordinatesFrom(x: x, y: y)
		
		angle = degreesFromRadians(angle)
		
		var arrow = 0;
		if radius > 30 {
			switch angle {
			case 0...60:
				arrow = 1
			case 60...120:
				arrow = 2
			case 120...180:
				arrow = 3
			case -60...0:
				arrow = -1
			case -120...(-60):
				arrow = -2
			default:
				arrow = -3
			}
		}
		
		arrowsListener?(arrow)
	}
	
	func touchEnd() {
		arrowsListener?(0)
	}
}

class ArrowBackgroundView: UIImageView {
	convenience init(center: CGPoint, size: CGFloat) {
		self.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
		
		self.center = center
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.image = UIImage(named: "arrows-bg")
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
