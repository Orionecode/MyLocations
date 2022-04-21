//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/18.
//
//

import Foundation
import CoreData

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var date: Date
    @NSManaged public var locationDescription: String
    @NSManaged public var category: String
    @NSManaged public var placemark: String
    @NSManaged public var longitude: Double

}

extension Location : Identifiable {

}
