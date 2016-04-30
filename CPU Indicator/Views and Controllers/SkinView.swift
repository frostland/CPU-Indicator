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
			exposeBinding("sizedSkin")
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
	
	private func commonInit() {
		wantsLayer = true /* Don't know why this does not work in Storyboard directly... */
		layer?.contentsGravity = kCAGravityResizeAspect
		layerContentsRedrawPolicy = .BeforeViewResize
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	deinit {
		removePreviewProgressObserverIfNeeded()
	}
	
	var sizedSkin: SizedSkin? {
		didSet {
			assert(sizedSkin?.skin.managedObjectContext?.concurrencyType == nil || sizedSkin?.skin.managedObjectContext?.concurrencyType == .MainQueueConcurrencyType)
			updateResolvedMixedImageState(forceImageUpdate: true)
		}
	}
	
	var defaultMixedImageState: MixedImageState = .UseSkinDefault {
		didSet {
			guard oldValue != defaultMixedImageState else {return}
			updateResolvedMixedImageState(forceImageUpdate: false)
		}
	}
	
	private(set) var resolvedMixedImageState: MixedImageState?
	
	/**
   If lower than 0, the shared "preview" progress will be used, else the actual
	given value will be used.
	
	Ideally, I would have set the type to Float?, but the property can't be
	designable if I did so... */
	@IBInspectable var progress: Float = 0 {
		didSet {
			assert(NSThread.isMainThread())
			if progress < 0 {
				assert(previewProgressObserver == nil)
				PreviewProgress.sharedPreviewProgress.nPreviewProgressObserver += 1
				previewProgressObserver = NSNotificationCenter.defaultCenter().addObserverForName(PreviewProgress.previewProgressChangeNotificationName, object: nil, queue: nil, usingBlock: { [weak self] n in
					self?.updateImageFromCurrentProgress(allowAnimation: false)
				})
			} else {
				removePreviewProgressObserverIfNeeded()
				updateImageFromCurrentProgress(allowAnimation: true)
			}
		}
	}
	private var previewProgressObserver: NSObjectProtocol?
	
	private func removePreviewProgressObserverIfNeeded() {
		if let obs = previewProgressObserver {
			PreviewProgress.sharedPreviewProgress.nPreviewProgressObserver -= 1
			NSNotificationCenter.defaultCenter().removeObserver(obs, name: PreviewProgress.previewProgressChangeNotificationName, object: nil)
			previewProgressObserver = nil
		}
	}
	
	private func updateResolvedMixedImageState(forceImageUpdate forceImageUpdate: Bool) {
		assert(NSThread.isMainThread()) /* Must be on main thread because we're accessing the skin, which is on a main queue managed object context */
		let currentResolvedMixedImageState = resolvedMixedImageState
		if defaultMixedImageState == .UseSkinDefault {resolvedMixedImageState = sizedSkin?.skin.mixedImageState ?? .Disallow}
		else                                         {resolvedMixedImageState = defaultMixedImageState}
		if forceImageUpdate || resolvedMixedImageState != currentResolvedMixedImageState {
			displayedProgress = nil
			updateImageFromCurrentProgress(allowAnimation: !forceImageUpdate)
		}
	}
	
	private func updateImageFromCurrentProgress(allowAnimation allowAnimation: Bool) {
		allowedToAnimatedDisplayedProgressChange = allowAnimation
		if progress < 0 {displayedProgress = PreviewProgress.sharedPreviewProgress.currentProgress}
		else {
			if resolvedMixedImageState == .Allow {displayedProgress = progress}
			else {
				/* We must stick to the reference frames. */
				let n = sizedSkin?.skin.frames?.count ?? 1
				guard n > 1 else {displayedProgress = 0; return}
				
				let imageIdx = Int(progress * Float(n-1))
				displayedProgress = (Float(imageIdx) / Float(n-1));
			}
		}
	}
	
	/* Always set to true after a change of displayedProgress */
	private var allowedToAnimatedDisplayedProgressChange = true
	/* If set to nil, nothing is done. */
	private var displayedProgress: Float? {
		willSet {
			guard let newValue = newValue else {return}
			
			assert(newValue >= 0 && newValue <= 1)
			guard abs(newValue - (displayedProgress ?? -1)) > 0.01 else {return}
			
			setNeedsDisplayInRect(bounds)
		}
	}
	
	override var wantsUpdateLayer: Bool {
		return true
	}
	
	override func updateLayer() {
		super.updateLayer()
		
		defer {allowedToAnimatedDisplayedProgressChange = false}
		guard let layer = layer else {return}
		
		guard let sizedSkin = sizedSkin, progress = displayedProgress else {
			layer.contents = nil
			return
		}
		sizedSkin.setLayerContents(layer, forProgress: progress, mixedImageState: resolvedMixedImageState ?? .Disallow, allowAnimation: allowedToAnimatedDisplayedProgressChange)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private class PreviewProgress {
		private static let sharedPreviewProgress = PreviewProgress()
		private static let previewProgressChangeNotificationName = "SkinView Preview Progress Change Notification"
		
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
			NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.previewProgressChangeNotificationName, object: self)
		}
	}
	
}
