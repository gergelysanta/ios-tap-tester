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
	
	typealias TouchData = (location: (start: CGPoint, last: CGPoint), moved: Bool)
	
	// SpriteKit scene displaying touch visualisations
	let scene = SKScene()
	
	let forceTapIndicator = TouchIndicator()
	
	// Dictionary holding the first and last location for each active touch
	var touchHistory = [UITouch:TouchData]()
	
	// Duration of animations
	let actionChangeInterval:TimeInterval = 0.7
	
	// Minimum distance to detect movement
	let minimumDistanceForMovement:CGFloat = 4.0
	
	// Starting and ending size of touch lines (touch movement visualisation)
	let lineStartSize:CGFloat = 10.0
	let lineEndSize:CGFloat = 2.0
	
	// Starting and ending size of tap dots (tap visualisation)
	let tapDotStartSize:CGFloat = 50.0
	let tapDotEndSize:CGFloat = 8.0

	// Starting and ending color of touch lines / tap dots
	let touchStartColor = UIColor.red
	let touchEndColor = UIColor.lightGray
	
	private let indicatorsPadding:CGFloat = 16.0
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let skView = view as? SKView {
			scene.size = view.frame.size
			skView.presentScene(scene)
		}
		view.isMultipleTouchEnabled = true
		scene.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
		
		forceTapIndicator.isHidden = true
		forceTapIndicator.position = CGPoint(x: (scene.size.width - forceTapIndicator.frame.size.width) * 0.5,
											 y: scene.size.height - forceTapIndicator.frame.size.height - 36.0)
		forceTapIndicator.anchor = CGPoint(x: 0.5, y:1.0)
		forceTapIndicator.zPosition = 100
		forceTapIndicator.sizeAtMaxForce = CGSize(width: scene.frame.width*0.7, height: scene.frame.width*0.7)
		scene.addChild(forceTapIndicator)
	}
	
	// MARK: - Private methods
	
	private func startHistory(ofTouch touch: UITouch, inScene scene: SKScene) {
		if touchHistory[touch] == nil {
			let location = touch.location(in: scene)
			touchHistory[touch] = (location: (start:location, last:location), moved: false)
		}
	}
	
	private func endHistory(ofTouch touch: UITouch) {
		if touchHistory[touch] != nil {
			touchHistory.removeValue(forKey: touch)
		}
	}
	
	private func drawLine(from: CGPoint, to: CGPoint, startWidth: CGFloat, endWidth: CGFloat) {
		let line = SKShapeNode()
		let path = CGMutablePath()
		path.move(to: from)
		path.addLine(to: to)
		line.path = path
		line.lineCap = .round
		line.strokeColor = touchEndColor
		line.lineWidth = startWidth
		
		let action = SKAction.customAction(withDuration: actionChangeInterval) { (node: SKNode, elapsedTime: CGFloat) in
			let step = elapsedTime/CGFloat(self.actionChangeInterval)
			
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
			// Cache touch
			startHistory(ofTouch: touch, inScene: scene)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			// Get location of the touch
			let location = touch.location(in: scene)
			// Check if we have already cached this touch
			if let touchData = touchHistory[touch] {
				// Touch cached, check the distance
				let distance = hypot(location.x - touchData.location.last.x, location.y - touchData.location.last.y)
				if distance > minimumDistanceForMovement {
					// If distance is long enough, draw a line indicating this touch movement
					drawLine(from: touchData.location.last, to: location, startWidth: lineStartSize, endWidth: lineEndSize)
					// Remember the last position
					touchHistory[touch]?.moved = true
					touchHistory[touch]?.location.last = location
				}
			}
			else {
				// Touch not cached yet, make this the beginning
				startHistory(ofTouch: touch, inScene: scene)
			}
		}
		
		// Display touch indicator if force tap detected
		var maxForcedTouch: UITouch? = nil
		for (touch, touchData) in touchHistory where !touchData.moved {
			if (maxForcedTouch == nil) || (touch.force > maxForcedTouch!.force) {
				maxForcedTouch = touch
			}
		}
		if let touch = maxForcedTouch {
			let force = touch.force / touch.maximumPossibleForce
			if force >= 0.1 {
				forceTapIndicator.touch = touch
				forceTapIndicator.force = force
				forceTapIndicator.isHidden = false
			}
		}
		else {
			forceTapIndicator.isHidden = true
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			// Get location of the touch
			let location = touch.location(in: scene)
			// Check if we have already cached this touch
			if let touchData = touchHistory[touch] {
				// Touch cached, check the distance
				let distance = hypot(location.x - touchData.location.start.x, location.y - touchData.location.start.y)
				if distance < minimumDistanceForMovement {
					// If distance is short enough, this is a tap only (not touch movement)
					// Draw a big (and shrinking) dot
					drawLine(from: touchData.location.start, to: location, startWidth: tapDotStartSize, endWidth: tapDotEndSize)
				}
			}
			endHistory(ofTouch: touch)
			if forceTapIndicator.touch == touch {
				forceTapIndicator.touch = nil
				forceTapIndicator.isHidden = true
			}
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
}
