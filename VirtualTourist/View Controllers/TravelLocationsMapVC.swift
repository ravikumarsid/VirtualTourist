//
//  TravelLocationsMapVC.swift
//  VirtualToursit
//
//  Created by Ravi Kumar Venuturupalli on 7/29/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var uiLongPress = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationAction(gestureRecognizer:)))
        uiLongPress.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(uiLongPress)
    }
    
    @objc func addAnnotationAction(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
    }
    
    @IBAction func editTapped(_ sender: Any) {
    }
    


}
