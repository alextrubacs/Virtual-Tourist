//
//  PhotoAlbumViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 04/07/2022.
//

import UIKit
import MapKit
import CoreData

extension PhotoAlbumViewController {   
    // MARK: Editing

    // Adds a new `Pin` to the end of the `pin`'s array
    func addPin(photos: [Data]) {
        let pin = Pin(context: dataController.viewContext)
     
        pin.latitude = latitude
        pin.longitude = longitude
        pin.photos = NSSet(array: photos)
        try? dataController.viewContext.save()
    }
    
}
