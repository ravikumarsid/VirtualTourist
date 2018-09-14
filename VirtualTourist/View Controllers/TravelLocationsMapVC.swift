//
//  TravelLocationsMapVC.swift
//  VirtualTourist
//
//  Created by Ravi Kumar Venuturupalli on 7/29/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var deletePinstext: UITextView!
    
    private let reuseIdentifier = "MyIdentifier"
    
    var pinsLocations: [Pin] = []
    var coordinates = [MKMapPoint]()
    var annotations = [MKPointAnnotation]()
    var nextVCPin: Pin?
    
    var selectedLatitude: String?
    var selectedLongitude: String?
    var currentMapRegion: MKCoordinateRegion?
    
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        
        hideDoneButton()
        deletePinstext.isHidden = true
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pinsLocations = result
        }
        
        getAnnotationsFromPinArray()
        
        let uiLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        uiLongPress.minimumPressDuration = 0.5
        uiLongPress.delaysTouchesBegan = true
        uiLongPress.delegate = self as? UIGestureRecognizerDelegate
        
        self.mapView.addGestureRecognizer(uiLongPress)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        for selectedAnnotation in self.mapView.selectedAnnotations {
            self.mapView.deselectAnnotation(selectedAnnotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if (deletePinstext.isHidden == false) {
            let coordinate = view.annotation?.coordinate
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate?.latitude.description
            pin.longitude = coordinate?.longitude.description
            
            pinsLocations = pinsLocations.filter { $0.latitude != pin.latitude && $0.longitude != pin.longitude}
            
            print(pinsLocations)
            
            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                for p in result {
                    if (p.latitude == pin.latitude) && (p.longitude == pin.longitude){
                        
                        dataController.viewContext.delete(p)
                    }
                }
            }
            
            try? dataController.viewContext.save()
            self.mapView.removeAnnotation(view.annotation!)
        
        } else {
            let coordinate = view.annotation?.coordinate
            selectedLatitude = coordinate?.latitude.description
            selectedLongitude = coordinate?.longitude.description
            
            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                for p in result {
                    if (p.latitude == selectedLatitude) && (p.longitude == selectedLongitude){
                        
                        nextVCPin = p
                    }
                }
            }
            performSegue(withIdentifier: "photoVCSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "photoVCSegue") {
            let nextVC = segue.destination as! PhotosViewController
            nextVC.latitude = selectedLatitude as NSString?
            nextVC.longitude = selectedLongitude as NSString?
            nextVC.dataController = self.dataController
            nextVC.pin = nextVCPin
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {return nil}
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
            annotationView?.animatesDrop = true
            
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    
    
    @objc func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.began { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let locationCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
  
        mapView.addAnnotation(annotation)
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = locationCoordinate.latitude.description
        pin.longitude = locationCoordinate.longitude.description
        
        try? dataController.viewContext.save()
        
        annotations.append(annotation)
    }
    
    func addLocation(latitude: String, longitude: String) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
    
        try? dataController.viewContext.save()
    }
    
    func getAnnotationsFromPinArray(){
        for pin in pinsLocations {
            let latNSString = NSString (string: pin.latitude!)
            let longNSString = NSString (string: pin.longitude!)
            let coordinate = CLLocationCoordinate2D(latitude: latNSString.doubleValue, longitude: longNSString.doubleValue)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            DispatchQueue.main.async {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func editTapped(_ sender: Any) {
        hideEditButton()
        deletePinstext.isHidden = false
        doneButton.title = "Done"
        doneButton.isEnabled = true
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        editButton.title = "Edit"
        editButton.isEnabled = true
        hideDoneButton()
        deletePinstext.isHidden = true
    }
    
    func hideDoneButton() {
        doneButton.title = ""
        doneButton.isEnabled = false
    }
    
    func hideEditButton(){
        editButton.title = ""
        editButton.isEnabled = false
    }
    
}
