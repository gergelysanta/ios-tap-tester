//
//  TouchIndicator.swift
//  TapTester
//
//  Created by Gergely Sánta on 15/11/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import UIKit
import SpriteKit

class TouchIndicator: SKShapeNode {
	
	private let labelNode = SKLabelNode()
	
	// MARK: - Properties
	
	weak var touch:UITouch?
	
	var backgroundCornerRounding:CGFloat = 10.0 {
		didSet {
			drawBackground()
		}
	}
	
	// Position properties
	
	var anchor = CGPoint(x: 0.5, y: 0.5)
	
	// Label properties
	
	var labelFontName = "ChalkboardSE-Bold" {
		didSet {
			labelNode.fontName = labelFontName
			actualizeVisual()
		}
	}
	var labelFontSize:CGFloat = 24 {
		didSet {
			actualizeVisual()
		}
	}
	var labelFontColor:UIColor = .black {
		didSet {
			labelNode.fontColor = labelFontColor
			centerLabel()
		}
	}
	
	// Size properties
	
	var size:CGSize = CGSize(width: 50.0, height: 50.0) {
		didSet {
			actualizeVisual()
		}
	}
	var sizeAtMaxForce = CGSize(width: 200.0, height: 200.0) {
		didSet {
			actualizeVisual()
		}
	}
	
	// Color properties
	
	var color = UIColor(red:0.14, green:0.62, blue:0.96, alpha:1.0) {
		didSet {
			actualizeVisual()
		}
	}
	var borderColor = UIColor(red:0.13, green:0.44, blue:0.93, alpha:1.0) {
		didSet {
			actualizeVisual()
		}
	}
	var colorAtMaxForce = UIColor(red:0.79, green:0.25, blue:0.16, alpha:1.00) {
		didSet {
			actualizeVisual()
		}
	}
	
	// Force (touch force)
	
	private var _force:CGFloat = 0.0
	var force:CGFloat {
		get {
			return _force
		}
		set {
			_force = (newValue < 0.0) ? 0.0 : ((newValue > 1.0) ? 1.0 : newValue)
			actualizeVisual()
		}
	}
	
	// MARK: - Initialization
	
	override init() {
		super.init()
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	private func initialize() {
		drawBackground(size: self.size)
		
		self.fillColor   = color
		self.strokeColor = borderColor
		self.lineWidth   = 3.0
		
		labelNode.fontName = labelFontName
		labelNode.fontSize = labelFontSize
		labelNode.fontColor = labelFontColor
		labelNode.zPosition = 100
		
		self.force = 0.0
		
		self.addChild(labelNode)
		self.centerLabel()
	}
	
	// MARK: - Private methods
	
	private func color(between colorA: UIColor, and colorB: UIColor, atPhase phase: CGFloat) -> UIColor {
		var redA:CGFloat = 0, greenA:CGFloat = 0, blueA:CGFloat = 0, alphaA:CGFloat = 0
		var redB:CGFloat = 0, greenB:CGFloat = 0, blueB:CGFloat = 0, alphaB:CGFloat = 0
		colorA.getRed(&redA, green: &greenA, blue: &blueA, alpha: &alphaA)
		colorB.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB)
		
		let modifier = (phase < 0.0) ? 0.0 : ((phase > 1.0) ? 1.0 : phase)

		return UIColor(red: redA + (redB - redA) * modifier,
					   green: greenA + (greenB - greenA) * modifier,
					   blue: blueA + (blueB - blueA) * modifier,
					   alpha: alphaA + (alphaB - alphaA) * modifier)
	}
	
	private func scaledSize() -> CGSize {
		return CGSize(width: size.width + (sizeAtMaxForce.width - size.width) * _force,
					  height: size.height + (sizeAtMaxForce.height - size.height) * _force)
	}
	
	private func drawBackground(size: CGSize) {
		if size.width > 0.0 && size.height > 0.0 {
			let backgroundShape = CGMutablePath()
			backgroundShape.addRoundedRect(in: CGRect(origin: CGPoint.zero, size: size),
										   cornerWidth: backgroundCornerRounding,
										   cornerHeight: backgroundCornerRounding)
			self.path = backgroundShape
		}
		else {
			self.path = nil
		}
	}
	
	private func drawBackground() {
		drawBackground(size: scaledSize())
	}

	private func centerLabel() {
		let scaledSize = self.scaledSize()
		labelNode.position = CGPoint(x: scaledSize.width * 0.5,
									 y: (scaledSize.height - labelNode.frame.height) * 0.52)
	}
	
	private func actualizeVisual() {
		// Get old position of anchor point
		let oldAnchorPosition = CGPoint(x: self.position.x + (self.frame.size.width * self.anchor.x),
										y: self.position.y + (self.frame.size.height * self.anchor.y))
		
		labelNode.text = String(format: "%.0lf", _force * 10.0)
		centerLabel()
		
		drawBackground()
		
		let sizeScale:CGFloat = (self.sizeAtMaxForce.width < self.sizeAtMaxForce.height)
			? self.sizeAtMaxForce.width / self.size.width
			: self.sizeAtMaxForce.height / self.size.height
		let maxFontSize = self.labelFontSize * sizeScale
		labelNode.fontSize = self.labelFontSize + (maxFontSize - self.labelFontSize) * _force

		fillColor = self.color(between: color, and: colorAtMaxForce, atPhase: _force)
		strokeColor = self.color(between: borderColor, and: colorAtMaxForce, atPhase: _force)
		
		// Get new position of anchor point
		let newAnchorPosition = CGPoint(x: self.position.x + (self.frame.size.width * self.anchor.x),
										y: self.position.y + (self.frame.size.height * self.anchor.y))
		
		// Seet new position (based of anchor points change)
		self.position = CGPoint(x: self.position.x + oldAnchorPosition.x - newAnchorPosition.x,
								y: self.position.y + oldAnchorPosition.y - newAnchorPosition.y)
	}
	
}
