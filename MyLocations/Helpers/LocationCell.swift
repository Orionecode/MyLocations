//
//  LocationCell.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/19.
//

import UIKit

class LocationCell: UITableViewCell {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
        addressLabel.numberOfLines = 2
    }
}

