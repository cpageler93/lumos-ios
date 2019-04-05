//
//  CameraVC.swift
//  Lumos
//
//  Created by Christoph Pageler on 15.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit
import AVFoundation


class CameraVC: UIViewController {

    fileprivate let captureSession = AVCaptureSession()
    fileprivate var frontCamera: AVCaptureDevice?
    fileprivate var rearCamera: AVCaptureDevice?
    fileprivate var selectedCamera: AVCaptureDevice?
    fileprivate var capturePhotoOutput = AVCapturePhotoOutput()
    fileprivate var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate var isFlashEnabled: Bool = false
    fileprivate var deviceOrientation: UIDeviceOrientation?

    private var imagePicker: UIImagePickerController?
    @IBOutlet weak var stackViewCameraActions: UIStackView!
    @IBOutlet weak var buttonFlash: UIButton!

    @IBOutlet var viewPhotoPreview: UIView!
    @IBOutlet weak var imageViewPhotoPreview: UIImageView!
    @IBOutlet var barButtonItemUsePhoto: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        checkCapturePermissions()

        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = videoOrientation()

        view.layer.insertSublayer(videoPreviewLayer, at: 0)
        videoPreviewLayer.frame = view.frame

        updateFlashIcon()
        barButtonItemUsePhoto.title = "use_photo".localized()
        navigationItem.rightBarButtonItem = nil
    }

    private func checkCapturePermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            initializeCameraInput()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    self.checkCapturePermissions()
                }
            }
        case .restricted:
            fallthrough
        case .denied:
            let alert = UIAlertController(title: "camera_permissions_title".localized(),
                                          message: "camera_permissions_message".localized(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
        @unknown default:
            break
        }

    }

    private func initializeCameraInput() {
        // prepare cameras
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                               mediaType: .video,
                                                               position: .unspecified)
        for device in deviceDiscovery.devices {
            switch device.position {
            case .front:
                frontCamera = device
            case .back:
                rearCamera = device
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .continuousAutoFocus
                    device.unlockForConfiguration()
                } catch {

                }
            default:
                break
            }

        }
        let camera = rearCamera ?? frontCamera
        var preset = AVCaptureSession.Preset.hd4K3840x2160
        if camera == frontCamera {
            preset = .high
        }
        updateCameraInputFrom(camera: camera, preset: preset)

        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        capturePhotoOutput.setPreparedPhotoSettingsArray([
            AVCapturePhotoSettings(format: [
                AVVideoCodecKey: AVVideoCodecType.jpeg
                ])
            ], completionHandler: nil)
        if captureSession.canAddOutput(capturePhotoOutput) {
            captureSession.addOutput(capturePhotoOutput)
        }
        captureSession.startRunning()

        videoPreviewLayer.session = captureSession
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        videoPreviewLayer.frame = view.frame
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        videoPreviewLayer.connection?.videoOrientation = videoOrientation()
    }

    private func videoOrientation() -> AVCaptureVideoOrientation {
        self.deviceOrientation = UIDevice.current.orientation

        switch UIDevice.current.orientation {
        case .faceUp:
            return .portrait
        case .faceDown:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }

    private func updateCameraInputFrom(camera: AVCaptureDevice?, preset: AVCaptureSession.Preset) {
        selectedCamera = camera ?? selectedCamera
        guard let selectedCamera = selectedCamera else { return }

        // remove old inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        captureSession.sessionPreset = preset

        guard let input = try? AVCaptureDeviceInput(device: selectedCamera) else { return }
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            updateCameraInputFrom(camera: camera, preset: .high)
        }
    }

    private func switchCamera() {
        if selectedCamera == frontCamera {
            updateCameraInputFrom(camera: rearCamera, preset: .hd4K3840x2160)
        } else {
            updateCameraInputFrom(camera: frontCamera, preset: .high)
        }
    }

    private func updateFlashIcon() {
        let image = isFlashEnabled ? UIImage(named: "iconCameraFlashActive") : UIImage(named: "iconCameraFlash")
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
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashEnabled ? .on : .off
        settings.isAutoStillImageStabilizationEnabled = true


        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
    }

    @IBAction func actionFlash(_ sender: UIButton) {
        isFlashEnabled = !isFlashEnabled
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

extension CameraVC: AVCapturePhotoCaptureDelegate {

    fileprivate func getImageOrientation(forDevice device: AVCaptureDevice) -> UIImage.Orientation {
        guard let deviceOrientation = deviceOrientation else {
            return device == rearCamera ? .right : .leftMirrored
        }

        switch deviceOrientation {
        case .landscapeLeft:
            return device == rearCamera ? .up : .downMirrored
        case .landscapeRight:
            return device == rearCamera ? .down : .upMirrored
        case .portraitUpsideDown:
            return device == rearCamera ? .left : .rightMirrored
        default:
            return device == rearCamera ? .right : .leftMirrored
        }
    }

    fileprivate func processPhoto(_ imageData: Data) -> UIImage? {
        guard let dataProvider = CGDataProvider(data: imageData as CFData) else { return nil }
        guard let cgImageRef = CGImage(jpegDataProviderSource: dataProvider,
                                       decode: nil,
                                       shouldInterpolate: true,
                                       intent: CGColorRenderingIntent.defaultIntent) else { return nil }
        guard let camera = selectedCamera else { return nil }

        // Set proper orientation for photo
        // If camera is currently set to front camera, flip image
        let image = UIImage(cgImage: cgImageRef,
                            scale: 1.0,
                            orientation: getImageOrientation(forDevice: camera))

        return image
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else { return }
        guard let image = processPhoto(photoData) else { return }

        stackViewCameraActions.isUserInteractionEnabled = false

        viewPhotoPreview.alpha = 0
        viewPhotoPreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewPhotoPreview)
        viewPhotoPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        viewPhotoPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        viewPhotoPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        viewPhotoPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        imageViewPhotoPreview.image = image

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
