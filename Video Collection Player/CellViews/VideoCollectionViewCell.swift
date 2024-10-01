//
//  VideoCollectionViewCell.swift
//  Video Collection Player
//
//  Created by Dikan Chen on 9/30/24.
//

import UIKit

class VideoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var thumLoadingIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        thumLoadingIndicator.isHidden = true
    }

}
