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
    var image: UIImage?

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
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopPadding: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomPadding: NSLayoutConstraint!
    
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
            location.photoID = nil
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
        
        // 保存图片
        if let image = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            if let data = image.jpegData(compressionQuality: 0.5) {
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
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

        if let location = locationToEdit {
            title = "Edit Location"
            if location.hasPhoto {
                if let theImage = location.photoImage {
                    show(image: theImage)
                }
            }
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

    // MARK: - Table View Delegates
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickePhoto()
        }
    }

// MARK: - Helper Methods
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        imageHeight.constant = 300
        imageViewTopPadding.constant = 18
        imageViewBottomPadding.constant = 18
        tableView.reloadData()
    }
    

// MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
}

// MARK: - Extension
extension LocationDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Image Picker methods
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    // Image Picker delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if let theImage = image {
            show(image: theImage)
        }
    
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    // pickePhoto ActionSheet
    func pickePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let photoAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.takePhotoWithCamera()
        }
        let libraryAction = UIAlertAction(title: "Choose From Library", style: .default) { _ in
            self.choosePhotoFromLibrary()
        }
        alert.addAction(cancelAction)
        alert.addAction(photoAction)
        alert.addAction(libraryAction)
        
        present(alert, animated: true)
    }
}
