//
//  CameraVC.swift
//  23Angle
//
//  Created by Christoph Pageler on 15.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit
import SwiftyCam


class CameraVC: SwiftyCamViewController {

    private var imagePicker: UIImagePickerController?

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraDelegate = self
    }

    func chooseImageFromGallery(on viewController: UIViewController) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.imagePicker = imagePicker
        viewController.present(imagePicker, animated: true, completion: nil)
    }

}


extension CameraVC: SwiftyCamViewControllerDelegate {

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        print("did take photo: \(photo)")
    }

}

extension CameraVC: UINavigationControllerDelegate { }

extension CameraVC: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        HTTPService.shared.uploadImage(image) { success in
            print("success: \(success)")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}
