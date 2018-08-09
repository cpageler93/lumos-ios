//
//  InitialVC.swift
//  Lumos
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit


class InitialVC: UIViewController {

    var launchVC: UIViewController?
    var newCenterYConstraint: NSLayoutConstraint?
    var titleLabel: UILabel?
    var lcTitleLabelBottom: NSLayoutConstraint?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var labelUserInfo: UILabel!

    @IBOutlet weak var buttonFindServer: LargeButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonFindServer.alpha = 0
        labelUserInfo.text = ""
        buttonFindServer.setTitle("find_server".localized(), for: .normal)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.animateLaunchScreen()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embeddedLaunchScreen" {
            self.launchVC = segue.destination
        }
    }

    private func animateLaunchScreen() {
        guard let viewController = launchVC else { return }
        guard let imageViewLogo = viewController.view.viewWithTag(1) else {
            return
        }

        let titleLabel = UILabel()
        titleLabel.text = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.insertSubview(titleLabel, belowSubview: imageViewLogo)
        titleLabel.centerXAnchor.constraint(equalTo: imageViewLogo.centerXAnchor).isActive = true
        self.lcTitleLabelBottom = titleLabel.bottomAnchor.constraint(equalTo: imageViewLogo.bottomAnchor, constant: 0)
        self.lcTitleLabelBottom?.isActive = true
        viewController.view.layoutIfNeeded()

        self.newCenterYConstraint = imageViewLogo.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor,
                                                                           constant: -20)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0.3,
                       options: .curveEaseInOut,
                       animations:
        {
            self.newCenterYConstraint?.isActive = true
            self.lcTitleLabelBottom?.constant = 25
            viewController.view.layoutIfNeeded()
        }, completion: { _ in
            self.handleEntryPoint()
        })
    }

    @IBAction func actionFindServer(_ sender: UIButton) {
        performSegue(withIdentifier: "setup", sender: self)
    }

    private func handleEntryPoint() {
        activityIndicatorView.startAnimating()
        let serverName = UserDefaults.standard.string(forKey: "serverName")
        if let serverName = serverName {
            labelUserInfo.text = String(format: "searching_for_server".localized(), serverName)
        }

        HTTPService.shared.hasValidServerConfiguration { success in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                if success {
                    self.performSegue(withIdentifier: "overview", sender: self)
                } else {
                    if let serverName = serverName {
                        self.labelUserInfo.text = String(format: "server_not_found".localized(), serverName)
                    }
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                        self.buttonFindServer.alpha = 1
                    }, completion: nil)
                }
            }
        }
    }

}
