/*
 * WindowPrefsViewController.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 1/9/16.
 * Copyright © 2016 Frost Land. All rights reserved.
 */

import Cocoa



class WindowPrefsViewController: NSViewController {
	
	@IBAction func moveWindowToTopLeft(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToTopLeft(sender)
	}
	
	@IBAction func moveWindowToPseudoTopLeft(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToPseudoTopLeft(sender)
	}
	
	@IBAction func moveWindowToTopRight(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToTopRight(sender)
	}
	
	@IBAction func moveWindowToPseudoTopRight(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToPseudoTopRight(sender)
	}
	
	@IBAction func moveWindowToBottomLeft(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToBottomLeft(sender)
	}
	
	@IBAction func moveWindowToPseudoBottomLeft(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToPseudoBottomLeft(sender)
	}
	
	@IBAction func moveWindowToBottomRight(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToBottomRight(sender)
	}
	
	@IBAction func moveWindowToPseudoBottomRight(sender: AnyObject!) {
		AppDelegate.sharedAppDelegate.mainWindowController.moveWindowToPseudoBottomRight(sender)
	}
	
}
