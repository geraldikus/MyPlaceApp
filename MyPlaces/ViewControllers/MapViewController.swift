//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Anton on 27.04.23.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {

    
    let mapManager = MapManager()
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var destinationDistanceLabel: UILabel!
    @IBOutlet weak var destinationTimeLabel: UILabel!
    
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let manager = CLLocationManager()
    let regionInMeters = 1000.0
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?
    var previousLocation: CLLocation? {
        didSet {
           startTrackingUserLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupMapView()
        adressLabel.text = ""
        mapView.delegate = self
        mapView.showsUserLocation = true
    }

    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(adressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func goButtonPressed() {
        
        mapManager.getDirections(for: mapView) { location in
            self.previousLocation = location
        }
    }
    
    private func setupMapView() {
        
        mapManager.mapViewController = self
        goButton.isHidden = true
        destinationDistanceLabel.isHidden = true
        destinationTimeLabel.isHidden =  true
        destinationDistanceLabel.text = ""
        destinationTimeLabel.text = ""
        
        mapManager.locationManagerDidChangeAuthorization(manager, mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            adressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
            destinationDistanceLabel.isHidden = false
            destinationTimeLabel.isHidden =  false
        }
    }

    private func setupLocationManager() {
        mapManager.locationManager.delegate = self
        mapManager.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        
        mapManager.locationManager.requestWhenInUseAuthorization()
        mapManager.locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    private func startTrackingUserLocation() {
        guard let previousLocation = previousLocation else { return }
        let center = mapManager.getCenterLocation(for: mapView)
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.mapManager.showUserLocation(mapView: self.mapView)
        }
    }  
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation,
                                                    reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil { // когда пользователь меняет фокус карты, то через 10 секунд карта центрируется на местоположении пользователя
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil, buildNumber != nil {
                    self.adressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.adressLabel.text = "\(streetName!)"
                } else {
                    self.adressLabel.text = ""
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue

        return renderer
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        mapManager.checkLocationAuthorization(mapView: mapView, incomeSegueIdentifier: incomeSegueIdentifier)
    }
}
