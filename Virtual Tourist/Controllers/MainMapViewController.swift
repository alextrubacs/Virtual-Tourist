//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 15/06/2022.
//

import UIKit
import MapKit
import CoreData

class MainMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: Core Data Set Up
    var dataController: DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: Properties
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    let locationManager =  CLLocationManager()
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupFetchedResultsController()
        addingTapToHold()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: MKMapview Delegate Methods
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .red
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView?.animatesDrop = true
        }
        else {
            pinView?.annotation = annotation
        }
        return pinView
    }

    // Delegate method to perform a segue when tapped on a pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "presentPhotoAlbumView", sender: self)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        debugPrint("did finish loading map")
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        debugPrint("mapViewDidFinishRenderingMap")
        //createPin(latitude: latitude, longitude: longitude)
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        debugPrint("failed to load map")
    }
    
    //MARK: Helper Methods
    // func called when gesture recognizer detects a long press
    @objc func mapLongPress(_ recognizer: UIGestureRecognizer) {

        print("A long press has been detected.")

        let touchedAt = recognizer.location(in: self.mapView) // adds the location on the view it was pressed
        let touchedAtCoordinate : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView) // will get coordinates

        createPin(latitude: touchedAtCoordinate.latitude, longitude: touchedAtCoordinate.longitude)
        latitude = touchedAtCoordinate.latitude
        longitude = touchedAtCoordinate.longitude
    }
    
    fileprivate func addingTapToHold() {
        
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
        
       // annotation.title = "Boomba"
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "presentPhotoAlbumView",
              let photoAlbumViewController = segue.destination as? PhotoAlbumViewController else {return}
        
        
        photoAlbumViewController.longitude = longitude
        photoAlbumViewController.latitude = latitude
        
    }
}

