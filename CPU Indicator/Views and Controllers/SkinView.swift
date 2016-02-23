/*
 * SkinView.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 29/11/15.
 * Copyright © 2015 Frost Land. All rights reserved.
 */

import Cocoa



class SkinView : NSView {
	
	/* The three methods below are not useful on Xcode > 3 as the support for
	 * displaying custom bindings in the Interface Editor (aka. Interface Builder
	 * on Xcode 3) has been removed...
	 * In the meantime, we have cheated in the storyboard to have a binding with
	 * the sizedSkin property anyway by editing the storyboard XML manually... */
	/*
	override static func initialize() {
		if self == SkinCell.self {
			self.exposeBinding("sizedSkin")
		}
		
		super.initialize()
	}
	
	override func valueClassForBinding(binding: String) -> AnyClass? {
		switch binding {
		case "sizedSkin":
			return SizedSkin.self
		default:
			return super.valueClassForBinding(binding)
		}
	}
	
	override func optionDescriptionsForBinding(binding: String) -> [NSAttributeDescription] {
		switch binding {
		case "sizedSkin":
			/* Not sure about what should be in the returned array... but I can't
			 * test! */
			let attr1 = NSAttributeDescription()
			attr1.name = NSAllowsNullArgumentBindingOption
			attr1.attributeType = .BooleanAttributeType
			attr1.defaultValue = true
			let attr2 = NSAttributeDescription()
			attr2.name = NSRaisesForNotApplicableKeysBindingOption
			attr2.attributeType = .BooleanAttributeType
			attr2.defaultValue = false
			return [attr1, attr2]
		default:
			return super.optionDescriptionsForBinding(binding)
		}
	}*/
	
	class PreviewProgress {
		private static let sharedPreviewProgress = PreviewProgress()
		private static let kPreviewProgressChangeNotificationName = "SkinView Preview Progress Change Notification"
		
		private let previewFPS: Int
		private let previewTimeBetweenFirstAndLastImage: Int
		private let nFramesBetweenFirstAndLastImage: Int
		
		private var delta = 1
		private var curProgress = 0
		
		convenience init() {
			self.init(FPS: 15, timeBetweenFirstAndLastImage: 5)
		}
		
		init(FPS: Int, timeBetweenFirstAndLastImage: Int) {
			previewFPS = FPS
			previewTimeBetweenFirstAndLastImage = timeBetweenFirstAndLastImage
			nFramesBetweenFirstAndLastImage = previewFPS * previewTimeBetweenFirstAndLastImage
		}
		
		private var timerUpdatePreviewProgress: NSTimer?
		private var nPreviewProgressObserver: Int = 0 {
			didSet {
				if oldValue > 0 && nPreviewProgressObserver == 0 {
					/* Let's stop the preview progress observer as nobobdy observes it... */
					timerUpdatePreviewProgress?.invalidate()
					timerUpdatePreviewProgress = nil
				} else if oldValue == 0 && nPreviewProgressObserver > 0 {
					/* Let's start the preview progress observer: somebody is interested... */
					timerUpdatePreviewProgress?.invalidate()
					timerUpdatePreviewProgress = NSTimer.scheduledTimerWithTimeInterval(1.0/Double(previewFPS), target: self, selector: #selector(PreviewProgress.advancePreviewProgress(_:)), userInfo: nil, repeats: true)
				}
			}
		}
		var currentProgress: Float {
			return Float(curProgress)/Float(nFramesBetweenFirstAndLastImage)
		}
		
		@objc
		private func advancePreviewProgress(timer: NSTimer!) {
			curProgress += delta
			if curProgress >= nFramesBetweenFirstAndLastImage || curProgress <= 0 {
				delta *= -1
			}
			NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.kPreviewProgressChangeNotificationName, object: self)
		}
	}
	
	var sizedSkin: SizedSkin? {
		didSet {
			self.setNeedsDisplayInRect(self.bounds)
		}
	}
	
	/**
   If lower than 0, the shared "preview" progress will be used, else the actual
	given value will be used.
	
	Ideally, I would have set the type to Float?, but the property can't be
	designable if I did so... */
	@IBInspectable var progress: Float = 0 {
		didSet {
			if progress < 0 {
				assert(previewProgressObserver == nil)
				PreviewProgress.sharedPreviewProgress.nPreviewProgressObserver += 1
				previewProgressObserver = NSNotificationCenter.defaultCenter().addObserverForName(PreviewProgress.kPreviewProgressChangeNotificationName, object: nil, queue: nil, usingBlock: { [weak self] n in
					self?.setNeedsDisplayInRect(self!.bounds)
				})
			} else {
				removePreviewProgressObserverIfNeeded()
				self.setNeedsDisplayInRect(self.bounds)
			}
		}
	}
	private var previewProgressObserver: NSObjectProtocol?
	
	deinit {
		removePreviewProgressObserverIfNeeded()
	}
	
	private func removePreviewProgressObserverIfNeeded() {
		if let obs = previewProgressObserver {
			--PreviewProgress.sharedPreviewProgress.nPreviewProgressObserver
			NSNotificationCenter.defaultCenter().removeObserver(obs, name: PreviewProgress.kPreviewProgressChangeNotificationName, object: nil)
			previewProgressObserver = nil
		}
	}
	
	override func drawRect(dirtyRect: NSRect) {
		guard let sizedSkin = sizedSkin else {
			return
		}
		
		let myFrame = self.frame
		
		let drawnSize = sizedSkin.size
		let p = NSPoint(
			x: myFrame.origin.x +  myFrame.size.width  - drawnSize.width,
			y: myFrame.origin.y + (myFrame.size.height - drawnSize.height)/2.0
		)
		
		let drawRect = NSRect(origin: p, size: drawnSize)
		sizedSkin.imageForProgress(progress >= 0 ? progress : PreviewProgress.sharedPreviewProgress.currentProgress).drawInRect(
			drawRect,
			fromRect: NSRect(origin: CGPointZero, size: drawnSize),
			operation: .CompositeSourceOver,
			fraction: 1,
			respectFlipped: true,
			hints: nil
		)
	}
	
}
