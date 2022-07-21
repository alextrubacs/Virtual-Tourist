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
    var pin: Pin!
    
    var dataController: DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
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
    var flickrPhotos: [Photo] = []
    let locationManager =  CLLocationManager()
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addingTapToHold()
        //loadSavedPins()
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
    
    func loadSavedPins() {
        let pins = fetchedResultsController.fetchedObjects!
        // Annotations
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        // When the array is complete, we add the annotations to the map.
        print("adding annotations \(annotations)")
        self.mapView.addAnnotations(annotations)
        
    }
    
    // Delegate method to perform a segue when tapped on a pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        for pin in fetchedResultsController.fetchedObjects! {
            if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                print("Pin found and assigned: \(pin)")
                self.pin = pin
            }
        }
        performSegue(withIdentifier: "presentPhotoAlbumView", sender: self)
    }
    
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
        
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
        FlickrClient.photoRequest(latitude:latitude,longitude:longitude) { response, error in
            self.handlePhotoRequestResponse(response:response,error: error)
        }
    }
    
    fileprivate func handlePhotoRequestResponse(response: FlickrResponse?, error: Error?) {
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
        photoAlbumViewController.flickrPhotos = self.flickrPhotos
        photoAlbumViewController.dataController = self.dataController
    }
    
    // MARK: Editing
    
    // Adds a new `Pin` to the end of the `pin`'s array
    func addPinToCoreData() {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = self.latitude
        pin.longitude = self.longitude
        for item in flickrPhotos {
            let coreItem = CoreURLs()
            coreItem.url = FlickrClient.Endpoints.photoURL(item.server, item.id, item.secret).url
            pin.addToCoreURLs(coreItem)
        }
        try? dataController.viewContext.save()
        self.pin = pin
    }
}
