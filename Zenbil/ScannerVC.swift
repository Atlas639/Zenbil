//
//  ScannerVC.swift
//  Zenbil
//
//  Created by Berhan Witte on 11.05.24.
//

import UIKit
import AVFoundation


class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    var qrIconImageView: UIImageView!
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onScanCompleted: (String) -> Void = { _ in }
    var audioPlayer: AVAudioPlayer?
    var photoOutput: AVCapturePhotoOutput!
    var viewModel: ScannerViewModel?
    var allowDismissal = false
    
    var cancelButton: UIButton!
    var nextButton: UIButton!
    var backButton: UIButton!
    var saveButton: UIButton!
    var thumbnailBarView: ThumbnailBarView!
    var shutterButton: UIButton!
    var isQRMode: Bool = true {
        didSet {
            if oldValue != isQRMode {
                DispatchQueue.main.async {
                    if self.isQRMode {
                        self.configureSessionForQR()
                    } else {
                        self.configureSessionForCamera()
                    }
                    self.updateUIForCurrentMode()
                }
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ScannerViewModel()
        if captureSession == nil {
            setupScanningSession()
        }
        setupUI()
        setupAudioPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if allowDismissal {
            super.dismiss(animated: flag, completion: completion)
        } else {
            // Prevent dismissal
            print("Dismissal prevented")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !allowDismissal {
            // Prevent the view from disappearing
            print("View disappearing prevented")
            self.presentingViewController?.present(self, animated: false, completion: nil)
        }
    }
    
    private func setupUI() {
        setupQRIcon()
        setupPreviewLayer()
        setupShadedTopArea()
        setupThumbnailBar()
        setupShutterButton()
        setupModeButtons()
        updateUIForCurrentMode()
    }
    
    private func setupPreviewLayer() {
        guard captureSession != nil else { return }

        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
    }
    
    private func setupScanningSession() {
        captureSession = AVCaptureSession()
        configureSessionForQR()
    }

    private func setupQRIcon() {
        qrIconImageView = UIImageView(image: UIImage(systemName: "qrcode.viewfinder"))
        qrIconImageView.translatesAutoresizingMaskIntoConstraints = false
        qrIconImageView.tintColor = .white
        view.addSubview(qrIconImageView)
        
        NSLayoutConstraint.activate([
            qrIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrIconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            qrIconImageView.widthAnchor.constraint(equalToConstant: 50),
            qrIconImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupAudioPlayer() {
        if let soundURL = Bundle.main.url(forResource: "beep", withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: soundURL) {
            audioPlayer = player
            audioPlayer?.prepareToPlay()
        }
    }
    
    private func setupShadedTopArea() {
        let shadedView = UIView()
        shadedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        shadedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shadedView)
        
        NSLayoutConstraint.activate([
            shadedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadedView.topAnchor.constraint(equalTo: view.topAnchor),
            shadedView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])
    }
    
    private func setupModeButtons() {
            cancelButton = createButton(title: "Cancel", action: #selector(cancelTapped))
            nextButton = createButton(title: "Next", action: #selector(nextButtonTapped))
            backButton = createButton(title: "Back", action: #selector(backButtonTapped))
            saveButton = createButton(title: "Save", action: #selector(saveButtonTapped))
            
            NSLayoutConstraint.activate([
                cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
                cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
                nextButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
                saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ])
        }
        
        private func createButton(title: String, action: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            return button
        }
    
    private func setupShutterButton() {
        shutterButton = UIButton(type: .system)
        shutterButton.setTitle("Shutter", for: .normal)
        shutterButton.backgroundColor = .red
        shutterButton.setTitleColor(.white, for: .normal)
        shutterButton.layer.cornerRadius = 25
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shutterButton)
        
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: thumbnailBarView.topAnchor, constant: -10),
            shutterButton.widthAnchor.constraint(equalToConstant: 50),
            shutterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupThumbnailBar() {
        thumbnailBarView = ThumbnailBarView()
        thumbnailBarView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailBarView.onThumbnailTap = { [weak self] index in
            self?.viewModel?.selectedIndex = index
        }
        thumbnailBarView.onAddButtonTap = { [weak self] in
            guard let self = self else { return }
            self.viewModel?.addNewArticle(qrCode: "")
            self.viewModel?.selectedIndex = (self.viewModel?.articles.count ?? 1) - 1
            self.isQRMode = true
        }
        
        view.addSubview(thumbnailBarView)
        
        NSLayoutConstraint.activate([
            thumbnailBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbnailBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            thumbnailBarView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func configureSessionForQR() {
        captureSession.beginConfiguration()
        removeExistingInputsAndOutputs()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        captureSession.commitConfiguration()
        qrIconImageView?.isHidden = false

        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func configureSessionForCamera() {
        captureSession.beginConfiguration()
        removeExistingInputsAndOutputs()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
        
    private func updateUIForCurrentMode() {
            let isHidden = !isQRMode
            qrIconImageView?.isHidden = isHidden
            shutterButton?.isHidden = !isHidden
            thumbnailBarView?.isHidden = !isHidden
            cancelButton?.isHidden = isHidden
            nextButton?.isHidden = isHidden
            backButton?.isHidden = !isHidden
            saveButton?.isHidden = !isHidden
        }
    
    private func removeExistingInputsAndOutputs() {
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
    }
    
    @objc private func cancelTapped() {
        if captureSession.isRunning { captureSession.stopRunning() }
        viewModel?.resetData()
        dismiss(animated: false)
    }

    @objc private func nextButtonTapped() {
        isQRMode = false
    }

    @objc private func backButtonTapped() {
        isQRMode = true
    }

    @objc private func saveButtonTapped() {}

    @objc private func shutterButtonTapped() {
        takePhoto()
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData),
              let viewModel = viewModel,
              let selectedIndex = viewModel.selectedIndex,
              selectedIndex < viewModel.articles.count else {
            return
        }

        viewModel.thumbnails.append(image)
        viewModel.addPhotoToCurrentArticle(photo: image)
        thumbnailBarView.thumbnails = viewModel.articles[selectedIndex].photos
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue,
              let viewModel = viewModel else {
            return
        }

        onScanCompleted(stringValue)
        audioPlayer?.play()
        
        if let selectedIndex = viewModel.selectedIndex, selectedIndex < viewModel.articles.count {
            viewModel.replaceQRCodeForCurrentArticle(newQRCode: stringValue)
        } else {
            viewModel.addNewArticle(qrCode: stringValue)
        }

        isQRMode = false
            }
        }
