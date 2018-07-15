//
//  SetupVC.swift
//  23Angle
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit
import NetworkService
import SVProgressHUD


class SetupVC: UIViewController {

    @IBOutlet weak var tableViewServer: UITableView!
    var services: [(NetService, String?)] = []

    let networkService = NetworkService()
    var timerSearchTimeout: Timer?

    @IBOutlet var barButtonItemReload: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        networkService.isAutoResolveEnabled = true
        networkService.delegate = self

        performSearch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func performSearch() {
        services.removeAll()
        navigationItem.leftBarButtonItem = nil
        SVProgressHUD.show()
        networkService.startBrowse(type: .tcp(name: "angle23"))

        timerSearchTimeout = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { timer in
            self.triggerSearchTimeout()
        })
    }

    private func stopSearch() {
        if networkService.isBrowsing() {
            networkService.stopBrowse()
        }
    }

    func updateService(_ service: NetService, address: String?) {
        if let index = services.index(where: { (s, a) -> Bool in
            return s == service
        }) {
            services[index] = (service, address)
        } else {
            services.append((service, address))
        }

        tableViewServer.reloadData()
    }

    private func triggerSearchTimeout() {
        timerSearchTimeout?.invalidate()
        timerSearchTimeout = nil
        stopSearch()

        guard services.count == 0 else { return }

        SVProgressHUD.showError(withStatus: "No Server found")
        navigationItem.leftBarButtonItem = barButtonItemReload
    }

    @IBAction func actionReload(_ sender: UIBarButtonItem) {
        performSearch()
    }

}


extension SetupVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return services.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let service = services[indexPath.row]
        cell.textLabel?.text = service.0.name
        cell.detailTextLabel?.text = service.1

        return cell
    }

}


extension SetupVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = services[indexPath.row]
        guard let address = service.1 else { return }

        SVProgressHUD.show()
        barButtonItemReload.isEnabled = false
        view.isUserInteractionEnabled = false
        HTTPService.shared.prepareForServer(at: address, port: service.0.port) { success in
            DispatchQueue.main.async {
                if success {
                    SVProgressHUD.dismiss()
                    self.performSegue(withIdentifier: "overview", sender: self)
                } else {
                    SVProgressHUD.showError(withStatus: "Failure")
                }
                tableView.deselectRow(at: indexPath, animated: true)
                self.barButtonItemReload.isEnabled = true
                self.view.isUserInteractionEnabled = true
            }
        }
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        let service = services[indexPath.row]
        return service.1 != nil
    }

}


extension SetupVC: NetworkServiceDelegate {

    func networkService(_ networkService: NetworkService,
                        didFind service: NetService,
                        moreComing: Bool,
                        didStartResolve: Bool) {
        updateService(service, address: nil)

        if !moreComing {
            SVProgressHUD.dismiss()
            timerSearchTimeout?.invalidate()
            timerSearchTimeout = nil

            navigationItem.leftBarButtonItem = barButtonItemReload
        }
    }

    func networkService(_ networkService: NetworkService,
                        didResolve service: NetService,
                        address: String) {
        updateService(service, address: address)
    }

}
