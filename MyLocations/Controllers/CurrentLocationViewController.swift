//
//  ViewController.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/16.
//

import UIKit
import CoreLocation
import CloudKit
import CoreData
import MapKit

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    // locationManager
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    // geocoder
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    // timer
    var timer: Timer?
    // core data 管理器
    var managedObjectContext: NSManagedObjectContext!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    @IBAction func getLocation() {
        let authStaus = locationManager.authorizationStatus
        if authStaus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }

        if authStaus == .denied || authStaus == .restricted {
            showLocationServiceDeniedError()
            return
        }

        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }

        updateLabels()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 这个设定是全局设定，设定后会隐藏后续界面的NavigationBar
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 更改回显示NavigationBar
        navigationController?.isNavigationBarHidden = false
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")

        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!;
        print("didUpdateLocations \(String(describing: newLocation))")
        // timestamp结果太久，直接忽略
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        // horizontalAccuracy精度<0，忽略
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        // 声明一个最大的浮点数值
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        // 确保每次调用的结果都比上一次的更加精确
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            // 调用updateLabels之前先清除错误日志
            lastLocationError = nil
            location = newLocation
            // 如果达到了10m的目标精度，停止定位
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're Done ***")
                stopLocationManager()
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            // Geocoding
            if !performingReverseGeocoding {
                print("*** Going to geocode ***")
                performingReverseGeocoding = true

                geocoder.reverseGeocodeLocation(newLocation) { placemarks, error in
                    // 在Swift中，所有的闭包内属性都必须用self显式调用
                    self.lastLocationError = error
                    if error == nil, let places = placemarks, !places.isEmpty {
                        self.placemark = places.last!
                    } else {
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                }
            }
            updateLabels()
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
                print("*** Force done!")
                stopLocationManager()
                updateLabels()
            }
        }
    }

    // MARK: - Helper Methods
    func showLocationServiceDeniedError() {
        let alert = UIAlertController(title: "Location Service Disabled", message: "TMD你打开一下设置里的定位谢谢", preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)

        present(alert, animated: true, completion: nil)
    }

    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = "";

            if let placemark = placemark {
                addressLabel.text = stringPlacemark(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            let stausMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    stausMessage = "Location Service Disabled"
                } else {
                    stausMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                stausMessage = "Location Service Disabled"
            } else if updatingLocation {
                stausMessage = "Searching..."
            } else {
                stausMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = stausMessage
        }
        configureGetButton()
    }

    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }

    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
        
        // 开始计时
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }

    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
        
        if let timer = timer {
            // 重置计时器
            timer.invalidate()
        }
    }
    
    // 利用Objective C的Runtime机制
    @objc func didTimeOut() {
        print("*** Time Out ***")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationErrorDomain", code: 1, userInfo: nil)
            updateLabels()
        }
    }

    func stringPlacemark(from placemark: CLPlacemark) -> String {
        // 地点名称
        var line1 = ""
        if let tmp = placemark.name {
            line1 += tmp + " "
        }
        // 地点行政区规划
        var line2 = ""
        // 区
        if let tmp = placemark.subLocality {
            line2 += tmp + " "
        }
        // 市
        if let tmp = placemark.locality {
            line2 += tmp + " "
        }
        // 省
        if let tmp = placemark.administrativeArea {
            line2 += tmp + " "
        }
        // 国家
        if let tmp = placemark.country {
            line2 += tmp
        }
        // 5
        return line1 + "\n" + line2
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            // navigation controll
            let controller = segue.destination as! LocationDetailViewController
            controller.coordinate = location!.coordinate
            controller.placemark = addressLabel.text!
            // coredata pass
            controller.managedObjectContext = managedObjectContext
        }
    }
}

