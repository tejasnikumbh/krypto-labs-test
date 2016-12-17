//
//  HomeViewController.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 15/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

typealias BNetworkCompletion = (_ success: Bool) -> ()

class HomeViewController: UIViewController {
    
    var monitoringSignificantChanges = false
    
    let initialRegionRadius: CLLocationDistance = 500
    var userLocation: CLLocation!
    let abuDhabiLocation = CLLocation(latitude: 24.44072, longitude: 54.44392)
    
    let locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var titleStrip: UIView!
    @IBOutlet weak var titleStripLabel: UILabel!
    @IBOutlet weak var titleStripMask: UIView!
    @IBOutlet weak var titleStripWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loaderImageView: UIImageView!
    @IBOutlet weak var loaderImageViewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateStrip()
    }
    
    func setupView() {
        loaderImageViewContainer.alpha = 0.0
        loaderImageView.loadGif(name: "loader")
        UIView.animate(withDuration: 0.65) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loaderImageViewContainer.alpha = 1.0
        }
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = false
        
        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.startUpdatingLocation()
        }
    }
    
    func downloadBusStopsFromServer(location: CLLocation, radius: CLLocationDistance,
                                    completion: BNetworkCompletion? = nil) {
        // Guard for Networking
        guard BReachability.sharedInstance.isConnectedToNetwork() else {
            UIView.animate(withDuration: 0.4, animations: { 
                self.loaderImageViewContainer.alpha = 0.0
            })
            let dialog = BUtils.dialog(message: "Networking needed for app functionality")
            self.present(dialog, animated: true, completion: nil)
            return
        }
        
        let url = "http://54.255.135.90/busservice/api/v1/bus-stops/radius"
        let params = ["lat": location.coordinate.latitude,
                      "lon": location.coordinate.longitude, "radius": radius]
        Alamofire.request(url, parameters: params).responseJSON{ [weak self] (response) in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.4, animations: {
                    weakSelf.loaderImageViewContainer.alpha = 0.0
                })
            }
            guard let bStopsArray = response.result.value as? [AnyObject] else {
                guard let completion = completion else { return }
                completion(false)
                return
            }
            // Creating Bus Stop Instances from JSON Data
            var bBusStops : [BBusStop] = []
            for stop in bStopsArray {
                guard let busStopId = stop["id"] as? Int,
                    let name = stop["name"] as? String,
                    let location = stop["location"] as? [String: AnyObject] else {
                    return
                }
                guard let coordinates = location["coordinates"] as? [AnyObject] else { return }
                guard let lon = coordinates[0] as? Double,
                    let lat = coordinates[1] as? Double else { return }
                let locationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let bBusStop = BBusStop(title: "Bus Stop", subtitle: name,
                                        coordinate: locationCoordinate, busStopId: busStopId)
                print(bBusStop.coordinate)
                bBusStops.append(bBusStop)
            }
            print(bBusStops)
            DispatchQueue.main.async {
                weakSelf.mapView.addAnnotations(bBusStops)
            }
        }
    }
    
    func animateStrip() {
        titleStripMask.isHidden = true
        titleStripWidthConstraint.constant = UIScreen.main.bounds.width * 0.5
        UIView.animate(withDuration: 1) { [weak self]() in
            guard let weakSelf = self else { return }
            weakSelf.view.layoutIfNeeded()
        }
    }
    
    func centerMap(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            location.coordinate, initialRegionRadius * 2.0, initialRegionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func getRadiusOfVisibleRegion(mapView: MKMapView) -> CLLocationDistance {
        let centerCoordinate = mapView.centerCoordinate
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = mapView.convert(CGPoint(x: mapView.bounds.width / 2.0,y: 0), toCoordinateFrom: mapView)
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        let radius = centerLocation.distance(from: topCenterLocation)
        return radius
    }
    
    @IBAction func centerOnUserLocationTapped(_ sender: UIButton) {
        centerMap(location: userLocation)
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    // Getting user location and centering map at that location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        userLocation = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        // Make sure you put userLocation here in prod.
        centerMap(location: userLocation)
        downloadBusStopsFromServer(location: userLocation, radius: initialRegionRadius,
                                   completion: nil)
        // Makes sure this method [didUpdateLocation] is called only 
        // when there are significant changes
        if !monitoringSignificantChanges {
            locationManager.stopUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            monitoringSignificantChanges = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied { // Manipulate the constraint and show enable location button
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BBusStop {
            let identifier = "bubble"
            var view: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            view.contentMode = .scaleAspectFit
            view.image = UIImage(named: "pin")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let newCenter = mapView.centerCoordinate
        let newCenterLocation = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
        let newRadius = getRadiusOfVisibleRegion(mapView: mapView)
        downloadBusStopsFromServer(location: newCenterLocation, radius: newRadius)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation as! BBusStop
        let vc = storyboard?.instantiateViewController(
            withIdentifier: Identifiers.ViewControllers.BusStop)
            as! BusStopViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.busStopId = annotation.busStopId
        self.present(vc, animated: true, completion: nil)
    }
}
