//
//  MapManager.swift
//  MyPlaces
//
//  Created by Anton on 05.05.23.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private var placeCoordinate: CLLocationCoordinate2D?
    private let regionInMeters = 1000.0
    private var directionsArray: [MKDirections] = []
    
    
    var mapViewController: MapViewController? = nil // каст для оутлетов лейблов destinationDistanceLabel и тайм лейбл
    
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
        guard let location = place.location else { return }
                
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(location) { (placemarksArray, error) in // изменение имени переменной
                    
                if let error = error {
                    print(error)
                    return
                }
                    
                guard let placemarks = placemarksArray else { return }
                    
                let placemark = placemarks.first // изменение имени константы
                
                let annotation = MKPointAnnotation()
                annotation.title = place.name
                annotation.subtitle = place.type
                
                guard let placemarkLocation = placemark?.location else { return }
                
                annotation.coordinate = placemarkLocation.coordinate
                self.placeCoordinate = placemarkLocation.coordinate
                
                mapView.showAnnotations([annotation], animated: true)
                mapView.selectAnnotation(annotation, animated: true)
                
            }
    }
    
    // Првоерка доступности сервисов геолокации
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager, mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            //setupLocationManager()
            checkLocationAuthorization(mapView: mapView, incomeSegueIdentifier: segueIdentifier)
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            closure()
        case .denied:
            alert(title: "Location Access Denied", message: "Please enable location services in settings.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            alert(title: "Location Access Restricted", message: "Your location cannot be accessed at this time.")
        case .authorizedAlways:
            break
        @unknown default:
            fatalError()
        }
    }
    
    // проверка авторизации приложения для использования сервисов геолокации
    
    let manager = CLLocationManager()
    
    func checkLocationAuthorization(mapView: MKMapView, incomeSegueIdentifier: String) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAdress" { showUserLocation(mapView: mapView) }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.alert(title: "Your location is not available", message: "Go to Setting -> MyPlace -> Location")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.alert(title: "Your location is not available", message: "Go to Setting -> MyPlace -> Location")
            }
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is availabel")
        }
    }
    
    // Фокусировка карты на местоположении пользователя
    
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Строим маршрут от пользователя до заведения
    
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        guard let location = locationManager.location?.coordinate else {
            alert(title: "Error", message: "Curent location not found")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {
            alert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.alert(title: "Error", message: "Route unavailable")
                }
                return
            }
            
            guard let response = response else {
                self.alert(title: "Error", message: "Destination is not available")
                return
            }
            
            func formatTime(seconds: TimeInterval) -> String {
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .abbreviated
                formatter.allowedUnits = [.hour, .minute]
                
                if let formattedString = formatter.string(from: seconds) {
                    return formattedString
                } else {
                    return ""
                }
            }
            
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime // время определяется в секундах
                
                let formattedTime = formatTime(seconds: timeInterval)
                
                guard let mapViewController = self.mapViewController else { return }
                
                mapViewController.destinationDistanceLabel.text = "Расстояние до места \(distance) км."
                mapViewController.destinationTimeLabel.text = "Время в пути \(formattedTime)"
            }
        }
    }
    
    // Настройка запроса для рассчета маршрута
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        
        return request
    }
    
    // Определяем центр отображаемой области карты
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    }
    
}
