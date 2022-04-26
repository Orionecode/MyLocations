//
//  LocationCell.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/19.
//

import UIKit

class LocationCell: UITableViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
        photoImageView.clipsToBounds = true
        self.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Helper Methods
    func configure(for location: Location) {
        if location.locationDescription.isEmpty {
            descriptionLabel.text = "No Description"
        } else {
            descriptionLabel.text = location.locationDescription
        }
        addressLabel.text = location.placemark
        addressLabel.numberOfLines = 3
        photoImageView.image = thumbnail(for: location)
    }
    
    func thumbnail(for location: Location) -> UIImage {
        if location.hasPhoto, let image = location.photoImage {
            return image
        }
        return UIImage(named: "No Photo")!
    }
}

