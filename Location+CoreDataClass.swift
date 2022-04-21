//
//  Location+CoreDataClass.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/18.
//
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var title: String? {
        if locationDescription.isEmpty {
            return "No Description"
        } else {
            return locationDescription
        }
    }
    
    public var subtitle: String? {
        return category
    }
    
}
