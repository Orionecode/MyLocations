//
//  MapViewController.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/20.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    var locations = [Location]()

    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NotificationCenter.default.addObserver(
                forName: Notification.Name.NSManagedObjectContextObjectsDidChange,
                object: managedObjectContext,
                queue: OperationQueue.main
            ) { _ in
                if self.isViewLoaded {
                    self.updateLocations()
                }
            }
        }
    }

    @IBOutlet weak var mapView: MKMapView!

    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate,
            latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

    @IBAction func showLocation() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        if !locations.isEmpty {
            showLocation()
        }
    }

    // MARK: - Helper methods
    func updateLocations() {
        mapView.removeAnnotations(locations)
        let entity = Location.entity()
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        locations = try! managedObjectContext.fetch(fetchRequest)
        mapView.addAnnotations(locations)
    }


    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion

        switch annotations.count {
            // 没有标记显示用户位置
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            // 只有一个标记将其置于屏幕中央
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            // 默认情况下（> 1）计算几个标记边界确定显示范围
        default:
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
            }

            let center = CLLocationCoordinate2D(
                latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)

            let extraSpace = 1.3
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)

            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailViewController
            controller.managedObjectContext = managedObjectContext
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
}

// MARK: - Extension
//If the pins don't change, then make sure you connected the view controller as the delegate of the map view in the storyboard
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 确保传递的是Location 如果不是返回 is语法和if let类似，但是省略了饭回结果
        guard annotation is Location else {
            return nil
        }

        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView (withIdentifier: identifier)

        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            //
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = true
            //
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
            pinView.rightCalloutAccessoryView = rightButton
            annotationView = pinView
        }

        // 设定点击的button具体信息
        if let annotationView = annotationView {
            annotationView.annotation = annotation
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location) {
                button.tag = index
            }
        }

        return annotationView
    }

    @objc func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
}

