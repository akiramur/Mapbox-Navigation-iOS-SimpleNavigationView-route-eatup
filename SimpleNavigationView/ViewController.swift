//
//  ViewController.swift
//  SimpleNavigationView
//
//  Created by Akira Murao on 2022/05/20.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import MapboxNavigation
import CoreLocation

class ViewController: UIViewController {
    
    let mapbox = CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047)
    let whiteHouse = CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365)
    
    internal var mapView: MapView!
    
    private var routeButton: UIButton!
    private var navigationButton: UIButton!
    
    private var routeResponse: RouteResponse?
    private var routeOptions: RouteOptions?
    
    
    var polyLineAnnnotationManager: PolylineAnnotationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let styleURI = StyleURI(rawValue: "mapbox://styles/mapbox/streets-v11")
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        //addRouteButton()
        addNavigationButton()
        
        mapView.mapboxMap.onNext(.mapLoaded) { _ in
            // Set the center coordinate and zoom level.
            let camera = CameraOptions(center: self.mapbox, zoom: 12.0)
            self.mapView.mapboxMap.setCamera(to: camera)
            
            self.addPointAnnotations(coordinates: [self.mapbox, self.whiteHouse])
            self.calculateRoute()
        }
        
    }
    
    // MARK: calculate route with waypoints
    
    private func addRouteButton() {
        routeButton = UIButton(frame: CGRect(x: 20, y: 100, width: 160, height: 50))
        routeButton.setTitle("Route", for: .normal)
        routeButton.backgroundColor = .blue
        routeButton.addTarget(self, action: #selector(routeButtonTapped(sender:)), for: .touchUpInside)
        view.addSubview(routeButton)
    }
    
    @objc func routeButtonTapped(sender: UIButton) {
        self.calculateRoute()
    }
    
    private func calculateRoute() {
        
        // Define two waypoints to travel between
        let origin = Waypoint(coordinate: mapbox, name: "Mapbox")
        let destination = Waypoint(coordinate: whiteHouse, name: "White House")
        
        // Set options
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
        
        // Request a route using MapboxDirections.swift
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self = self else { return }
                
                self.fitBounds(coordinates: [self.mapbox, self.whiteHouse])
                self.addLineAnnotation(for: response.routes?.first)
                
                self.routeResponse = response
                self.routeOptions = routeOptions
            }
        }
    }
    
    private func addNavigationButton() {
        navigationButton = UIButton(frame: CGRect(x: 20, y: 200, width: 160, height: 50))
        navigationButton.setTitle("Navigate", for: .normal)
        navigationButton.backgroundColor = .blue
        navigationButton.addTarget(self, action: #selector(navigationButtonTapped(sender:)), for: .touchUpInside)
        view.addSubview(navigationButton)
    }
    
    @objc func navigationButtonTapped(sender: UIButton) {
        self.startNavigation()
    }
    
    
    private func startNavigation() {
        guard let routeResponse = routeResponse, let routeOptions = routeOptions else {
            return
        }
        
        let navigationService = MapboxNavigationService(
            routeResponse: routeResponse,
            routeIndex: 0,
            routeOptions: routeOptions,
            simulating: .always)
        
        let viewController = NavigationViewController(navigationService: navigationService)
        
        viewController.delegate = self
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true, completion: nil)
    }
    
    // MARK: other private methods
    
    private func fitBounds(coordinates: [CLLocationCoordinate2D]?) {
        
        guard let coordinates = coordinates, coordinates.count > 0 else {
            return
        }
        
        let cameraOptions = mapView.mapboxMap.camera(for: coordinates,
                                                     padding: .zero,
                                              bearing: nil,
                                              pitch: nil)
        mapView.camera.fly(to: cameraOptions)
    }
    
    private func addLineAnnotation(for route: Route?) {
        guard let coordinates = route?.shape?.coordinates else {
            return
        }
        
        var lineAnnotation = PolylineAnnotation(lineCoordinates: coordinates)
        
        lineAnnotation.lineColor = StyleColor(.purple)
        lineAnnotation.lineOpacity = 0.8
        lineAnnotation.lineWidth = 10.0
        
        let lineAnnnotationManager = mapView.annotations.makePolylineAnnotationManager()

        // Sync the annotation to the manager.
        lineAnnnotationManager.annotations = [lineAnnotation]
    }
    
    private func addPointAnnotations(coordinates: [CLLocationCoordinate2D]) {
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        
        var annotations: [PointAnnotation] = []
        for coordinate in coordinates {
            var annotation = PointAnnotation(coordinate: coordinate)
            annotation.image = .init(image: UIImage(named: "red_pin")!, name: "red_pin")
            
            annotations.append(annotation)
        }
        
        pointAnnotationManager.annotations = annotations
    }
}

extension ViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        guard let coordinates = self.routeResponse?.routes?.first?.shape?.coordinates else {
            return
        }
        
        let path = Turf.LineString(coordinates)
        
        guard let pathDistance = path.distance() else {
            return
        }
        
        print("distanceTraveled: \(progress.distanceTraveled)")
        let alongPath = path.trimmed(from: progress.distanceTraveled, to: pathDistance)
        
        addProgressLineAnnotation(for: alongPath, navigationViewController: navigationViewController)
        
    }
    
    private func addProgressLineAnnotation(for shape: LineString?, navigationViewController: NavigationViewController) {
        guard let coordinates = shape?.coordinates else {
            return
        }
        
        var lineAnnotation = PolylineAnnotation(lineCoordinates: coordinates)
        
        lineAnnotation.lineColor = StyleColor(.purple)
        lineAnnotation.lineOpacity = 0.8
        lineAnnotation.lineWidth = 10.0
        
        if polyLineAnnnotationManager == nil {
            polyLineAnnnotationManager = navigationViewController.navigationMapView?.mapView.annotations.makePolylineAnnotationManager()

        }

        // Sync the annotation to the manager.
        polyLineAnnnotationManager?.annotations = [lineAnnotation]
    }
}
