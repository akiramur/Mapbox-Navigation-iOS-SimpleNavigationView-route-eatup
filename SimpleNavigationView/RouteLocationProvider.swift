//
//  RouteLocationProvider.swift
//  Navigation-Examples
//
//  Created by Akira Murao on 2022/05/20.
//  Copyright © 2022 Mapbox. All rights reserved.
//

import Foundation
import CoreLocation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

public final class RouteLocationProvider: LocationProvider {
    var route: Route?
    
    public var locationProviderOptions = LocationOptions()
    
    public let authorizationStatus = CLAuthorizationStatus.authorizedAlways

    public let accuracyAuthorization = CLAccuracyAuthorization.fullAccuracy

    public var heading: CLHeading? = nil

    public var headingOrientation = CLDeviceOrientation.portrait

    private var updateTimer: Timer?
    private var count: Int = 0
    
    
    private weak var delegate: LocationProviderDelegate?

    init(route: Route) {
        self.route = route
    }
    
    deinit {
        updateTimer?.invalidate()
    }

    public func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
    }

    public func requestAlwaysAuthorization() {
        
    }

    public func requestWhenInUseAuthorization() {
        
    }

    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        
    }

    public func startUpdatingLocation() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
            self?.timerUpdate()
        })
    }

    public func stopUpdatingLocation() {
        updateTimer?.invalidate()
    }

    public func startUpdatingHeading() {
        
    }

    public func stopUpdatingHeading() {
        
    }

    public func dismissHeadingCalibrationDisplay() {
        
    }
    
    @objc func timerUpdate() {
        print("timerUpdate()")
        
        var coordinates: CLLocationCoordinate2D?
        if let lineString = route?.shape as? LineString {
            coordinates = lineString.coordinates[self.count]
            self.count += 1
            if count >= lineString.coordinates.count {
                self.count = 0
            }
        }
        
        if let coordinates = coordinates {
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            //let location = CLLocation(latitude: 38.9131752, longitude: -77.0324047)
            //let location = CLLocation(coordinate: coordinates, altitude: 0, horizontalAccuracy: .leastNormalMagnitude, verticalAccuracy: .leastNormalMagnitude, timestamp: Date())
            print("location: \(location)")
            self.delegate?.locationProvider(self, didUpdateLocations: [location])
        }
    }
}

