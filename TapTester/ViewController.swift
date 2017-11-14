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
	
	typealias TouchData = (location: (start: CGPoint, last: CGPoint), label: SKLabelNode)
	
	// SpriteKit scene displaying touch visualisations
	let scene = SKScene()
	
	// Dictionary holding the first and last location for each active touch
	var touchHistory = [UITouch:TouchData]()
	
	// Font name for labels
	let labelFontName = "ChalkboardSE-Bold"
	let labelFontSize:CGFloat = 24
	let labelFontMaxSize:CGFloat = 48
	
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
	
	private func startHistory(ofTouch touch: UITouch, inScene scene: SKScene) {
		if touchHistory[touch] == nil {
			let labelNode = SKLabelNode(fontNamed: labelFontName)
			labelNode.text = "0"
			labelNode.fontSize = 12
			labelNode.fontColor = touchStartColor
			labelNode.isHidden = true
			labelNode.zPosition = 100
			scene.addChild(labelNode)
			
			let location = touch.location(in: scene)
			touchHistory[touch] = (location: (start:location, last:location), label: labelNode)
		}
	}
	
	private func endHistory(ofTouch touch: UITouch) {
		if let touchItem = touchHistory[touch] {
			touchItem.label.removeFromParent()
			touchHistory.removeValue(forKey: touch)
		}
	}
	
	private func set(position: CGPoint, andForce force: CGFloat, ofLabel label: SKLabelNode) {
		label.fontSize = labelFontSize + (labelFontMaxSize - labelFontSize) * force
		label.text = String(format: "%.0lf", force * 10.0)
		label.position = CGPoint(x: position.x, y: position.y + 36.0)
		label.isHidden = false
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
			if let touchItem = touchHistory[touch] {
				// Put label indicating touch force
				set(position: location, andForce: touch.force / touch.maximumPossibleForce, ofLabel: touchItem.label)
				// Touch cached, check the distance
				let distance = hypot(location.x - touchItem.location.last.x, location.y - touchItem.location.last.y)
				if distance > minimumDistanceForMovement {
					// If distance is long enough, draw a line indicating this touch movement
					drawLine(from: touchItem.location.last, to: location, startWidth: lineStartSize, endWidth: lineEndSize)
					// Remember the last position
					touchHistory[touch]?.location.last = location
				}
			}
			else {
				// Touch not cached yet, make this the beginning
				startHistory(ofTouch: touch, inScene: scene)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			// Get location of the touch
			let location = touch.location(in: scene)
			// Check if we have already cached this touch
			if let touchItem = touchHistory[touch] {
				// Touch cached, check the distance
				let distance = hypot(location.x - touchItem.location.start.x, location.y - touchItem.location.start.y)
				if distance < minimumDistanceForMovement {
					// If distance is short enough, this is a tap only (not touch movement)
					// Draw a big (and shrinking) dot
					drawLine(from: touchItem.location.start, to: location, startWidth: tapDotStartSize, endWidth: tapDotEndSize)
				}
			}
			endHistory(ofTouch: touch)
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
}
