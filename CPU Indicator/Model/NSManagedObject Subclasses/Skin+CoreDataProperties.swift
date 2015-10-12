//
//  Skin+CoreDataProperties.swift
//  CPU Indicator
//
//  Created by François Lamboley on 10/11/15.
//  Copyright © 2015 Frost Land. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Skin {

    @NSManaged var height: Int32
    @NSManaged var mixedImageState: Int16
    @NSManaged var name: String!
    @NSManaged var sortPosition: Int32
    @NSManaged var source: String?
    @NSManaged var uid: String!
    @NSManaged var width: Int32
    @NSManaged var frames: NSOrderedSet!

}
