/*
 * FLDefaultPaths.swift
 * CPU Indicator
 *
 * Created by François Lamboley on 3/3/15.
 * Copyright (c) 2015 Frost Land. All rights reserved.
 */

import Foundation



extension NSFileManager {
	func getNonExistantFileNameFrom(base: String, withExtension e: String?, showOneForFirst showFirst: Bool) -> String {
		var result = (showFirst ? base.stringByAppendingString(" 1") : base)
		if let ext = e {result = result.stringByAppendingPathExtension(ext)!}
		
		for var i = 2; self.fileExistsAtPath(result); ++i {
			result = base.stringByAppendingFormat(" %d", i)
			if let ext = e {result = result.stringByAppendingPathExtension(ext)!}
		}
		
		return result
	}
	
	func createDirectoryAtPathIfNecessary(path: String, withAttributes attributes: [NSObject: AnyObject]?, inout error: NSError?) -> Bool {
		var dir: ObjCBool = false
		if !self.fileExistsAtPath(path, isDirectory: &dir) {
			return self.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: attributes, error: &error)
		}
		
		if !dir {
			error = NSError(domain: "fr.frostland.cpu-indicator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Path exists but is a file."])
		}
		
		return false
	}
	
	private func getPathDirectoryForSearch(search: NSSearchPathDirectory, permToCreate: Int?) -> String? {
		let libraries = NSSearchPathForDirectoriesInDomains(search, NSSearchPathDomainMask.UserDomainMask, true)
		if libraries.count == 0 {return nil}
		
		var err: NSError?
		let path = libraries[0] as! String
		/* Note: This made Swift crash (Xcode 6D532l)
		 * let attrs = (permToCreate != nil ? [NSFilePosixPermissions: permToCreate!] as [NSObject: AnyObject]? : nil) */
		let attrs: [NSObject: AnyObject]? = (permToCreate != nil ? [NSFilePosixPermissions: permToCreate!] : nil)
		if !self.createDirectoryAtPathIfNecessary(path, withAttributes: attrs, error: &err) {
			println("*** Warning: Can't create dir at path \(path): \(err)")
			return nil
		}
		
		return nil
	}
	
	func userLibraryPath() -> String? {
		return getPathDirectoryForSearch(NSSearchPathDirectory.LibraryDirectory, permToCreate: 0700)
	}
	
	func userAppSupportPath() -> String? {
		return getPathDirectoryForSearch(NSSearchPathDirectory.ApplicationSupportDirectory, permToCreate: nil)
	}
	
	func userCPUIndicatorSupportFolder() -> String? {
		if let supportPath = self.userAppSupportPath() {
			var err: NSError?
			let ret = supportPath.stringByAppendingPathComponent("CPU Indicator")
			if !self.createDirectoryAtPathIfNecessary(ret, withAttributes: nil, error: &err) {
				println("*** Warning: Can't create dir at path \(ret): \(err)")
				return nil
			}
			return ret
		}
		return nil
	}
	
	func pathForListSkinsDescr(existsPtr: UnsafeMutablePointer<ObjCBool>) -> String? {
		if let path = self.userCPUIndicatorSupportFolder() {
			let skinsPath = path.stringByAppendingPathComponent("Skins.sld")
			let exists = ObjCBool(self.fileExistsAtPath(skinsPath))
			existsPtr[0] = exists
			return skinsPath
		}
		return nil
	}
	
	func fullSkinPathFrom(skinFileName: String) -> String? {
		if (skinFileName as NSString).absolutePath {return self.fullSkinPathFrom(skinFileName.lastPathComponent)}
		return self.userCPUIndicatorSupportFolder()?.stringByAppendingPathComponent(skinFileName)
	}
	
	func pathForNewSkin() -> String? {
		if let base = self.userCPUIndicatorSupportFolder() {
			return self.getNonExistantFileNameFrom(base.stringByAppendingPathComponent("skin"), withExtension: "cpuIndicatorSkin", showOneForFirst: true)
		}
		
		return nil
	}
}
