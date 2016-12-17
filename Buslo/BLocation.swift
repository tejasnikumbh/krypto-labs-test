//
//  BLocation.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 17/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import Foundation

import UIKit
import MapKit

class BLocation: NSObject, MKAnnotation {
    
    let title: String?
    var subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String,
         coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
    
}
