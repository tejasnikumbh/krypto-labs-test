//
//  ViewController.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 15/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    var locationManager: CLLocationManager!
    
    @IBOutlet weak var iconManipulatorCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var needsLocationLabel: UILabel!
    @IBOutlet weak var locationServiceButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLocationManager()
    }
    
    func setupView() {
        needsLocationLabel.alpha = 0.0
        locationServiceButton.alpha = 0.0
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    @IBAction func locationServicesTapped(_ sender: UIButton) {
        let url = NSURL(string: UIApplicationOpenSettingsURLString) as! URL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }

}

extension ViewController: CLLocationManagerDelegate {
    /* 
     * Delegate Method
     *
     * Discussion: Only two cases need to be handled here, one is for authorization granted,
     * in which case we redirect to the next view controller. And the second one is denied,
     * in which case we ask the user to authorize
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    //Segue to Map View Controller
                    let vc = storyboard?.instantiateViewController(withIdentifier: Identifiers.ViewControllers.Home) as! HomeViewController
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true, completion: nil)
                }
            }
        } else if status == .denied { // Manipulate the constraint and show enable location button
            iconManipulatorCenterConstraint.constant = -UIScreen.main.bounds.height * 0.05
            UIView.animate(withDuration: 0.6, animations: { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.view.layoutIfNeeded()
            }) { [weak self] (success) in
                if success {
                    UIView.animate(withDuration: 0.4) {
                        guard let weakSelf = self else { return }
                        weakSelf.needsLocationLabel.alpha = 1.0
                        weakSelf.locationServiceButton.alpha = 1.0
                    }
                }
            }
        }
    }
}

