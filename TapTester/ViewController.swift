//
//  ViewController.swift
//  TapTester
//
//  Created by Gergely Sánta on 08/11/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import UIKit
import SpriteKit
import CoreGraphics

class ViewController: UIViewController {
	
	typealias TouchMove = (start: CGPoint, last: CGPoint)
	
	// SpriteKit scene displaying touch visualisations
	let scene = SKScene()
	
	// Dictionary holding the first and last location for each active touch
	var touchHistory = [UITouch:TouchMove]()
	
	// Duration of animations
	let actionChangeInterval:CGFloat = 0.7
	
	// Starting and ending size of touch lines (touch movement visualisation)
	let lineStartSize:CGFloat = 10.0
	let lineEndSize:CGFloat = 2.0
	
	// Starting and ending size of tap dots (tap visualisation)
	let tapDotStartSize:CGFloat = 50.0
	let tapDotEndSize:CGFloat = 8.0

	// Starting and ending color of touch lines / tap dots
	let touchStartColor = UIColor.red
	let touchEndColor = UIColor.lightGray
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let skView = view as? SKView {
			scene.size = view.frame.size
			skView.presentScene(scene)
		}
		view.isMultipleTouchEnabled = true
		scene.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
	}
	
	// MARK: - Private methods
	
	private func drawLine(from: CGPoint, to: CGPoint, startWidth: CGFloat, endWidth: CGFloat) {
		let line = SKShapeNode()
		let path = CGMutablePath()
		path.move(to: from)
		path.addLine(to: to)
		line.path = path
		line.lineCap = .round
		line.strokeColor = touchEndColor
		line.lineWidth = startWidth
		
		let action = SKAction.customAction(withDuration: TimeInterval(actionChangeInterval)) { (node: SKNode, elapsedTime: CGFloat) in
			let step = elapsedTime/self.actionChangeInterval
			
			var startRed:CGFloat = 0, startGreen:CGFloat = 0, startBlue:CGFloat = 0, startAlpha:CGFloat = 0
			var endRed:CGFloat = 0, endGreen:CGFloat = 0, endBlue:CGFloat = 0, endAlpha:CGFloat = 0
			self.touchStartColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
			self.touchEndColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
			
			if let line = node as? SKShapeNode {
				line.lineWidth = startWidth + (endWidth - startWidth) * step
				line.strokeColor = UIColor(red: startRed + (endRed - startRed) * step,
										   green: startGreen + (endGreen - startGreen) * step,
										   blue: startBlue + (endBlue - startBlue) * step,
										   alpha: startAlpha + (endAlpha - startAlpha) * step)
			}
		}
		line.run(action)
		
		scene.addChild(line)
	}
	
	// MARK: - Touches
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			let location = touch.location(in: scene)
			touchHistory[touch] = (start:location, last:location)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			let location = touch.location(in: scene)
			if let oldLocation = touchHistory[touch] {
				let distance = hypot(location.x - oldLocation.last.x, location.y - oldLocation.last.y)
				if distance > lineStartSize {
					drawLine(from: oldLocation.last, to: location, startWidth: lineStartSize, endWidth: lineEndSize)
					touchHistory[touch]?.last = location
				}
			}
			else {
				touchHistory[touch] = (start:location, last:location)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			let location = touch.location(in: scene)
			if let oldLocation = touchHistory[touch] {
				let distance = hypot(location.x - oldLocation.start.x, location.y - oldLocation.start.y)
				if distance < lineStartSize {
					drawLine(from: oldLocation.start, to: location, startWidth: tapDotStartSize, endWidth: tapDotEndSize)
				}
			}
			touchHistory.removeValue(forKey: touch)
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
}
