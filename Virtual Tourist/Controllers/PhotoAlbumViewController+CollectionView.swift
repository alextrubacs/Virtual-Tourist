//
//  PhotoAlbumViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 04/07/2022.
//

import UIKit
import MapKit
import CoreData

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.corePhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        let coreImage = fetchedResultsController.object(at: indexPath)
        checkForSavedPhotos(coreImage, cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
        collectionView.deleteItems(at: [indexPath])
    }
    
    //MARK: Helper Methods
    fileprivate func checkForSavedPhotos(_ coreImage: CorePhoto, _ cell: PhotoCell) {
        if let data = coreImage.corePhoto {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            //Configure cell
            cell.imageView.image = UIImage(data: data)
        } else if let url = coreImage.coreURL {
            FlickrClient.downloadingPhotosFromCore(url: url) { data, error in
                if let data = data {
                    let image = UIImage(data: data)
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.isHidden = true
                    coreImage.corePhoto = data
                    self.saveContext()
                    self.collectionView.reloadData()
                }
            }
        }
    }
}
// MARK: Data Controller Methods
extension PhotoAlbumViewController {
    
    func saveContext() {
        try? dataController.viewContext.save()
    }
    
    func deletingObjectsFromCoreData() {
        let objects = fetchedResultsController.fetchedObjects!
        let context = dataController.viewContext
        
        for object in objects {
            context.delete(object)
        }
        saveContext()
    }
    
}
