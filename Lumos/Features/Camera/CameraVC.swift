//
//  CameraVC.swift
//  Lumos
//
//  Created by Christoph Pageler on 15.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit
import SwiftyCam


class CameraVC: SwiftyCamViewController {

    private var imagePicker: UIImagePickerController?
    @IBOutlet weak var stackViewCameraActions: UIStackView!
    @IBOutlet weak var buttonFlash: UIButton!

    @IBOutlet var viewPhotoPreview: UIView!
    @IBOutlet weak var imageViewPhotoPreview: UIImageView!
    @IBOutlet var barButtonItemUsePhoto: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraDelegate = self
        doubleTapCameraSwitch = false
        updateFlashIcon()
        navigationItem.rightBarButtonItem = nil
        videoQuality = .high
        shouldUseDeviceOrientation = true
    }

    private func updateFlashIcon() {
        let image = flashEnabled ? UIImage(named: "iconCameraFlashActive") : UIImage(named: "iconCameraFlash")
        buttonFlash.setImage(image, for: .normal)
    }

    func chooseImageFromGallery(on viewController: UIViewController) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.imagePicker = imagePicker
        viewController.present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func actionTakePicture(_ sender: UIButton) {
        takePhoto()
    }

    @IBAction func actionFlash(_ sender: UIButton) {
        flashEnabled = !flashEnabled
        updateFlashIcon()
    }

    @IBAction func actionSwitchCamera(_ sender: UIButton) {
        switchCamera()
    }

    @IBAction func actionCancel(_ sender: UIBarButtonItem) {
        if imageViewPhotoPreview.image != nil {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.viewPhotoPreview.alpha = 0
            }, completion: { _ in
                self.navigationItem.rightBarButtonItem = nil
                self.stackViewCameraActions.isUserInteractionEnabled = true
                self.imageViewPhotoPreview.image = nil
                self.viewPhotoPreview.removeFromSuperview()
            })
        } else {
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func actionUsePhoto(_ sender: UIBarButtonItem) {
        guard let image = imageViewPhotoPreview.image else { return }
        HTTPService.shared.uploadImage(image) { success in
            print("success: \(success)")
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
}


extension CameraVC: SwiftyCamViewControllerDelegate {

    func swiftyCam(_ swiftyCam: SwiftyCamViewController,
                   didTake photo: UIImage) {
        stackViewCameraActions.isUserInteractionEnabled = false

        viewPhotoPreview.alpha = 0
        viewPhotoPreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewPhotoPreview)
        viewPhotoPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        viewPhotoPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        viewPhotoPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        viewPhotoPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        imageViewPhotoPreview.image = photo

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.viewPhotoPreview.alpha = 1
            self.navigationItem.rightBarButtonItem = self.barButtonItemUsePhoto
        }, completion: nil)
    }

}

extension CameraVC: UINavigationControllerDelegate { }

extension CameraVC: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else { return }
        HTTPService.shared.uploadImage(image) { success in
            print("success: \(success)")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}
