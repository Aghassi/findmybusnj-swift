//
//  FindNearByStopsController.swift
//  findmybusnj
//
//  Created by David Aghassi on 9/29/15.
//  Copyright © 2015 David Aghassi. All rights reserved.
//

import Foundation
import UIKit
import MapKit

// Dependencies
import SwiftyJSON
import Alamofire

class FindNearByStopsController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    // How much to show outside of the center
    private let regionRadius: CLLocationDistance = 1000
    private let kgPlaceKey = "AIzaSyB5pvxDYulLut0SLlHUep33ufjJ7OxUQ5M"
    // MARK: - location manager to authorize user location for Maps app
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        #if RELEASE
        centerMapOnLocation()
        #endif
        queryPlaces("bus_station")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }

    
    private func centerMapOnLocation() {
        let userlocation = locationManager
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(userlocation.location!.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    private func queryPlaces(googleType: String) {
        #if RELEASE
        let coordinate = locationManager.location!.coordinate
        #endif
        
        let queryRegion = regionRadius * 3
        
        // Test data (home)
        #if DEBUG
        let latitude = 40.9171205
        let longitude = -74.0441104
        #else
        // Prod code (variable based on GPS)
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        #endif
            
        
        /**
        * Pass data to server using headers, not through string
        **/
        
//        let url = String("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(queryRegion)&types=\(googleType)&key=\(kgPlaceKey)")
        let url = String("https://findmybusnj.com/rest/getPlaces")
        let parameters = [
            "latitude" : String(latitude),
            "longitude" : String(longitude),
            "radius" : String(queryRegion),
            "types" : googleType
        ]
        print(parameters)
        
        Alamofire.request(.POST, url, parameters: parameters).responseJSON {
            (req, res, json) in
            if (json.isFailure) {
                NSLog("Error: \(json.error)")
            }
            else {
                let json = JSON(json.value!)
                print(json)
                let results = json["results"]
                var locName: String         // location name
                var latitude: Double
                var longitude: Double
                
                for (var i = 0; i < 15; i++) {
                    locName = String(results[i]["name"])
                    latitude = results[i]["geometry"]["location"]["lat"].double!
                    longitude = results[i]["geometry"]["location"]["lng"].double!

                    print(i, "bus is:",  locName, "with latitude", latitude, "and longitude", longitude)
                    let busStopAnnotation = PlacesAnnotation(title: locName,
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    self.mapView.addAnnotation(busStopAnnotation)
                }
            }
        }
    }
    
    private func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}