//
//  LocationDetailViewController.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/17.
//

import UIKit
import CoreLocation
import CoreData
import MapKit

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailViewController: UITableViewController, UITextFieldDelegate {
    // 数据库中没有 直接传递参数
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: String = ""
    var categoryName = "No Category"
    var date = Date()
    var descriptionText = ""
    var addressText = ""

    // 数据库中已有 进入Edit界面传参数据库对象
    var managedObjectContext: NSManagedObjectContext!

    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                placemark = location.placemark
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                date = location.date
            }
        }
    }

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!

    // MARK: - Actions
    @IBAction func done(_ sender: Any) {
        // 设计显示HUD
        var mainView: UIView
        if let view = navigationController?.parent?.view {
            mainView = view
        } else {
            return
        }
        let hudView = HudView.hud(inView: mainView, animated: true)
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            // 使用传递进来的被managedObjectContext管理的Location对象
            location = temp
        } else {
            hudView.text = "Tagged"
            // 声明一个新的被managedObjectContext管理的Location对象
            location = Location(context: managedObjectContext)
        }
        
        // 赋值
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.date = date
        location.placemark = addressTextView.text
        if let newLatitude = Double(latitudeTextField.text!) {
            location.latitude = newLatitude
        } else {
            location.latitude = coordinate.latitude
        }
        if let newLongitude = Double(longitudeTextField.text!) {
            location.longitude = newLongitude
        } else {
            location.longitude = coordinate.longitude
        }
        
        // 在数据库中保存
        do {
            try managedObjectContext.save()
            afterDelay(0.5) {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            fatalCoreDataError(error)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func categoryPickerDidPickCategory(
        _ segue: UIStoryboardSegue
    ) {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }

    // MARK: - viewLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        if locationToEdit != nil {
            title = "Edit Location"
        }
        // 将存储在数据库的内容解析到界面
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeTextField.text = String(format: "%.8f", coordinate.latitude)
        longitudeTextField.text = String(format: "%.8f", coordinate.longitude)
        addressTextView.text = placemark
        dateLabel.text = format(date: date)
        // 点按空白处隐藏键盘
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - UITextFieldDelegate Methods
    
    // Allow just decimal number
    // Connect delegate in interface builder!
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text != "" || string != "" {
            let res = (textField.text ?? "") + string
            return Double(res) != nil
        }
        return true
    }
    
    // MARK: - Helper Methods
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
}
