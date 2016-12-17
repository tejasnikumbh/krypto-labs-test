//
//  BusStopViewController.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 16/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import SwiftGifOrigin

class BusStopViewController: UIViewController {

    var busStopId: Int? = nil
    var buses: [BBus] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loaderImageView: UIImageView!
    @IBOutlet weak var loaderImageViewContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let id = busStopId else { return }
        downloadBusDetailsFromServer(busStopId: id)
    }
    
    func setupView() {
        loaderImageViewContainer.alpha = 0.0
        loaderImageView.loadGif(name: "loader")
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loaderImageViewContainer.alpha = 1.0
        }
    }

    func downloadBusDetailsFromServer(busStopId: Int, completion: BNetworkCompletion? = nil) {
        // Guard for Networking
        guard BReachability.sharedInstance.isConnectedToNetwork() else {
            UIView.animate(withDuration: 0.4, animations: {
                self.loaderImageViewContainer.alpha = 0.0
            })
            let dialog = BUtils.dialog(message: "Networking needed for app functionality")
            self.present(dialog, animated: true, completion: nil)
            return
        }
        let url = "http://54.255.135.90/busservice/api/v1/bus-stops/\(busStopId)/buses"
        Alamofire.request(url).responseArray { [weak self] (response: DataResponse<[BBus]>) in
            let busArray = response.result.value
            var bBuses: [BBus] = []
            if let busArray = busArray {
                for bus in busArray {
                   bBuses.append(bus)
                }
            }
            guard let weakSelf = self else { return }
            weakSelf.buses = bBuses
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.4, animations: { 
                    weakSelf.loaderImageViewContainer.alpha = 0.0
                })
                weakSelf.tableView.reloadData()
            }
            guard let completion = completion else { return }
            completion(true)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BusStopViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Identifiers.TableViewCells.busCell) as! BusTableViewCell
        let cellModel = buses[indexPath.row]
        cell.name.text = cellModel.name
        cell.destination.text = cellModel.destination
        cell.number.text = cellModel.number
        cell.direction.text = cellModel.direction
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = storyboard?.instantiateViewController(withIdentifier: Identifiers.ViewControllers.busDetails) as! BusDetailsViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.bus = buses[indexPath.row]
        self.present(vc, animated: true, completion: nil)
        return
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buses.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "  Buses Available"
    }
}


