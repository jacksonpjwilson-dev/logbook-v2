import AVFoundation
import SwiftUI
import UIKit

struct FoodBarcodeCamera: UIViewControllerRepresentable {
    var onCode: (String) -> Void

    func makeUIViewController(context: Context) -> FoodBarcodeViewController {
        let controller = FoodBarcodeViewController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ controller: FoodBarcodeViewController, context: Context) {
        controller.onCode = onCode
    }
}

final class FoodBarcodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let capture = AVCaptureSession()
    private let queue = DispatchQueue(label: "logbook.barcode.capture")
    private var preview: AVCaptureVideoPreviewLayer?
    private var configured = false
    private var deliveredCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if allowed { self.configureAndStart() }
                    else { self.showCameraUnavailable("Camera access is off. Enter the barcode below instead.") }
                }
            }
        default: showCameraUnavailable("Camera access is off. Enter the barcode below instead.")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue.async { if self.capture.isRunning { self.capture.stopRunning() } }
    }

    private func configureAndStart() {
        guard !configured else { return }
        configured = true
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              capture.canAddInput(input) else {
            showCameraUnavailable("This device cannot scan a barcode. Enter it below instead.")
            return
        }
        capture.addInput(input)
        let metadata = AVCaptureMetadataOutput()
        guard capture.canAddOutput(metadata) else {
            showCameraUnavailable("This device cannot scan a barcode. Enter it below instead.")
            return
        }
        capture.addOutput(metadata)
        metadata.setMetadataObjectsDelegate(self, queue: .main)
        metadata.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        let layer = AVCaptureVideoPreviewLayer(session: capture)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
        queue.async { self.capture.startRunning() }
    }

    private func showCameraUnavailable(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !deliveredCode,
              let code = metadataObjects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first else { return }
        deliveredCode = true
        capture.stopRunning()
        onCode?(code)
    }
}
