//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 27/06/2022.
//

import Foundation
import UIKit

 class PhotoCell: UICollectionViewCell, Cell {
    // Outlets
     @IBOutlet weak var imageView: UIImageView!
     
     
    
    override func prepareForReuse() {
        super.prepareForReuse()

    }
}

protocol Cell: AnyObject {
    /// A default reuse identifier for the cell class
    static var defaultReuseIdentifier: String { get }
}

extension Cell {
    static var defaultReuseIdentifier: String {
        // Should return the class's name, without namespacing or mangling.
        // This works as of Swift 3.1.1, but might be fragile.
        return "\(self)"
    }
}
