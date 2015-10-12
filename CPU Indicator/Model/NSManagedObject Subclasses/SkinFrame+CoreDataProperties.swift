//
//  SkinFrame+CoreDataProperties.swift
//  CPU Indicator
//
//  Created by François Lamboley on 10/12/15.
//  Copyright © 2015 Frost Land. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SkinFrame {

    @NSManaged var height: Int32
    @NSManaged var width: Int32
    @NSManaged var xPos: Int32
    @NSManaged var yPos: Int32
    @NSManaged var imageData: NSData!
    @NSManaged var skin: Skin!

}
