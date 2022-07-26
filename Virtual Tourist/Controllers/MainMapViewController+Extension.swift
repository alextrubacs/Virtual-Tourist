//
//  MainMapViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 22/07/2022.
//

import Foundation
import UIKit
import MapKit
import CoreData
extension MainMapViewController {
    
    //MARK: Helper Methods
    // func called when gesture recognizer detects a long press
    @objc func mapLongPress(_ recognizer: UIGestureRecognizer) {
        
        let touchedAt = recognizer.location(in: self.mapView) // adds the location on the view it was pressed
        let touchedAtCoordinate : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView) // will get coordinates
        
        createPin(latitude: touchedAtCoordinate.latitude, longitude: touchedAtCoordinate.longitude)
        latitude = touchedAtCoordinate.latitude
        longitude = touchedAtCoordinate.longitude
        print("A long press has been detected. latitude:\(touchedAtCoordinate.latitude) and longitude\(touchedAtCoordinate.longitude)")
    }
    
    func addingTapToHold() {
        
        // add gesture recognizer
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MainMapViewController.mapLongPress(_:))) // colon needs to pass through info
        longPress.minimumPressDuration = 0.8 // in seconds
        //add gesture recognition
        mapView.addGestureRecognizer(longPress)
    }
    
    func createPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        //mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
        FlickrClient.photoRequest(latitude:latitude,longitude:longitude) { response, error in
            self.handlePhotoRequestResponse(response:response,error: error)
        }
    }
    
    func handlePhotoRequestResponse(response: FlickrResponse?, error: Error?) {
        if let response = response {
            let filteredPhotos = response.photos.photo
            flickrPhotos.append(contentsOf: filteredPhotos)
            addPinToCoreData()
        } else {
            print("PhotoCollection could not be created!\(error!.localizedDescription)")
        }
    }
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "presentPhotoAlbumView",
              let photoAlbumViewController = segue.destination as? PhotoAlbumViewController else {return}
        photoAlbumViewController.pin = self.pin
        photoAlbumViewController.dataController = self.dataController
    }
    
    // MARK: Editing
    
    // Adds a new `Pin` to the end of the `pin`'s array
    func addPinToCoreData() {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = self.latitude
        pin.longitude = self.longitude
        
        let coreUrls = flickrPhotos.map { flickrPhoto -> CoreURLs in
            let coreItem = CoreURLs(context: dataController.viewContext)
            coreItem.url = FlickrClient.Endpoints.photoURL(flickrPhoto.server, flickrPhoto.id, flickrPhoto.secret).url
            return coreItem
        }
        pin.addToCoreURLs(NSOrderedSet(array: coreUrls))
        
        try? dataController.viewContext.save()
        self.pin = pin
    }
    
}
