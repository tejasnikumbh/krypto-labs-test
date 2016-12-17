//
//  BusDetailsViewController.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 16/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import AlamofireObjectMapper

class BusDetailsViewController: UIViewController {

    var bus: BBus? = nil

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var direction: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var loaderImageViewContainer: UIView!
    @IBOutlet weak var loaderImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        guard let bus = bus else { return }
        downloadRouteFromServer(busId: bus.id!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupView() {
        guard let bus = bus else { return }
        name.text = bus.name
        destination.text = bus.destination
        number.text = bus.number
        direction.text = bus.direction
        mapView.delegate = self
        loaderImageViewContainer.alpha = 0.0
        loaderImageView.loadGif(name: "loader")
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loaderImageViewContainer.alpha = 1.0
        }
    }
    
    func downloadRouteFromServer(busId: Int) {
        if let route = cachedRoute(id: busId) {
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else { return }
                UIView.animate(withDuration: 0.4, animations: {
                    weakSelf.loaderImageViewContainer.alpha = 0.0
                    weakSelf.displayRoute(route: route)
                })
            }
            return
        }
        // Guard for Networking
        guard BReachability.sharedInstance.isConnectedToNetwork() else {
            UIView.animate(withDuration: 0.4, animations: {
                self.loaderImageViewContainer.alpha = 0.0
            })
            let dialog = BUtils.dialog(message: "Networking needed for app functionality")
            self.present(dialog, animated: true, completion: nil)
            return
        }
        let url = "http://54.255.135.90/busservice/api/v1/buses/\(busId)/route"
        Alamofire.request(url).responseObject {
            [weak self] (response: DataResponse<BRoute>) in
            guard let weakSelf = self else { return }
            guard let bRoute = response.result.value else { return }
            let processedRoute = weakSelf.processRoute(route: bRoute)
            weakSelf.cacheRoute(id: (weakSelf.bus?.id)!, route: processedRoute)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.4, animations: {
                    weakSelf.loaderImageViewContainer.alpha = 0.0
                    weakSelf.displayRoute(route: processedRoute)
                })
            }
        }
    }
    
    /* 
     * processRoute:route
     *
     * Discussion: Function that might help reduce size of route in future.
     */
    func processRoute(route: BRoute) -> [[Double]] {
        if (route.points?.count)! < 20 { return route.points! }
        let numPoints = (route.points?.count)!
        // Adjust the jump in cases of high number of co-ordinates
        // Jump of 1 is fine right now
        let jump = 1
        var newRoutePoints: [[Double]] = []
        var count = 0
        while count < numPoints {
            newRoutePoints.append((route.points?[count])!)
            count += jump
        }
        return newRoutePoints
    }
    
    /*
     * cacheRoute:route
     *
     * Discussion: Function to cache route into UserDefaults. 
     * Can put limit on caching using LRU policy. But simple cache for now
     */
    func cacheRoute(id: Int, route: [[Double]]) {
        UserDefaults.standard.setValue(route, forKey: "busRoute\(id)")
    }
    
    func cachedRoute(id: Int) -> [[Double]]? {
        guard let route = UserDefaults.standard.object(forKey: "busRoute\(id)") else {
            return nil
        }
        return route as? [[Double]]
    }
    
    /*
     * displayRoute:route
     *
     * Discussion: Function that displays a route on the map
     */
    func displayRoute(route: [[Double]]) {
        var locations: [CLLocation] = []
        for point in route {
            locations.append(CLLocation(latitude: point[1], longitude: point[0]))
        }
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        let polyline = MKPolyline(coordinates: &coordinates, count: locations.count)
        mapView.add(polyline)
        // Adding source and destination annotations
        addSourceAndDestination(route: route)
        centerMap(route: route)
    }
    
    func addSourceAndDestination(route: [[Double]]) {
        let pointCount = route.count
        let sourceCoordinate =  CLLocationCoordinate2D(latitude: route[0][1], longitude: route[0][0])
        let sourceAnnotation = BLocation(title: "Source", subtitle: "",  coordinate: sourceCoordinate)
        let destinationCoordinate =  CLLocationCoordinate2D(latitude: route[pointCount-1][1], longitude: route[pointCount-1][0])
        let destinationAnnotation = BLocation(title: "destination", subtitle: "",  coordinate: destinationCoordinate)
        mapView.addAnnotations([sourceAnnotation, destinationAnnotation])
    }
    
    func computeCentroid(route: [[Double]]) ->[Double] {
        var centroid = [0.0, 0.0]
        var sumX = 0.0
        var sumY = 0.0
        let numPoints = route.count
        for point in route {
            sumX += point[0]
            sumY += point[1]
        }
        centroid = [sumX/Double(numPoints), sumY/Double(numPoints)]
        return centroid
    }
    
    func computeDiameter(route: [[Double]], centroid: [Double]) -> CLLocationDistance {
        let centroidCoordinate = CLLocation(latitude: centroid[1], longitude: centroid[0])
        var maxDistance: CLLocationDistance = 0.0
        for point in route {
            let pointCoordinate = CLLocation(latitude: point[1], longitude: point[0])
            if pointCoordinate.distance(from: centroidCoordinate) > maxDistance {
                maxDistance = pointCoordinate.distance(from: centroidCoordinate)
            }
        }
        return maxDistance
    }
    
    func centerMap(route: [[Double]]) {
        let centroid = computeCentroid(route: route)
        let diameter = computeDiameter(route: route, centroid: centroid)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            CLLocationCoordinate2D(latitude: centroid[1], longitude: centroid[0]),
            diameter*2.0, diameter*2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BusDetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BLocation {
            let identifier = "bubble"
            var view: MKAnnotationView
            // For efficient re-use of views
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            view.contentMode = .scaleAspectFit
            view.image = UIImage(named: "pin")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = UIColor.red.withAlphaComponent(0.5);
            pr.lineWidth = 5;
            return pr;
        }
        return MKOverlayRenderer()
    }
}
