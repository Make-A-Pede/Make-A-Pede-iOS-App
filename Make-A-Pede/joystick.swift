//
//  joystick.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

import UIKit

class JoystickView: UIView {
	var dot: DotView!

	var width: CGFloat!
	var height: CGFloat!
	var minDimen: CGFloat!
	var joystickListener: ((CGFloat, CGFloat) -> Void)?
	
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

		let circle = CircleView(center: center, size: minDimen)
		self.addSubview(circle)

		dot = DotView(center: center)
		self.addSubview(dot)
	}
	
	func setJoystickListener(listener: @escaping (CGFloat, CGFloat) -> Void) {
		joystickListener = listener
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
		var x = (location.x - center.x) * (100 / (minDimen/2))
		var y = (center.y - location.y) * (100 / (minDimen/2))
		
		var (radius, angle) = polarCoordinatesFrom(x: x, y: y)
		
		if radius > 100 {
			radius = 100
		}

		(x, y) = cartesianCoordinatesFrom(radius: radius, angle: angle)
		
		joystickListener?(x, y)
		
		let xAbsolute = (x * ((minDimen/2) / 100)) + center.x
		let yAbsolute = center.y - (y * ((minDimen/2) / 100))

		dot.moveTo(point: CGPoint(x: xAbsolute, y: yAbsolute))
	}

	func touchEnd() {
		joystickListener?(0, 0)
		
		dot.recenter()
	}
}

class CircleView: UIImageView {
	convenience init(center: CGPoint, size: CGFloat) {
		self.init(frame: CGRect(x: 0, y: 0, width: size, height: size))

		self.center = center
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.image = UIImage(named: "joystick-bg")
	}

	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class DotView: UIImageView {
	var originalCenter = CGPoint(x: 0, y: 0)

	convenience init(center: CGPoint) {
		self.init(frame: CGRect(x: 0, y: 0, width: 75, height: 75))

		originalCenter = center
		self.center = center
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.image = UIImage(named: "joystick-handle")
	}

	func moveTo(point: CGPoint) {
		self.center = point
	}

	func recenter() {
		self.center = originalCenter
	}

	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
