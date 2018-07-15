//
//  SettingsVC.swift
//  23Angle
//
//  Created by Christoph Pageler on 15.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit


class SettingsVC: UIViewController {

    @IBOutlet weak var textFieldUsername: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldUsername.text = HTTPService.shared.nameForPhotos

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gestureViewTap))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func gestureViewTap(_ tapGesture: UITapGestureRecognizer) {
        if textFieldUsername.isFirstResponder {
            HTTPService.shared.nameForPhotos = textFieldUsername.text
        }
        view.endEditing(true)
    }

}


extension SettingsVC: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldUsername {
            HTTPService.shared.nameForPhotos = textField.text
        }

        textField.resignFirstResponder()
        return true
    }

}
