import SwiftUI
import AVFoundation

struct CustomCameraView: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel

    /// A view whose backing layer is the camera preview, so the preview always matches the
    /// view's size. SwiftUI decides the size (TakePhotoView gives it the strip's window shape).
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let coordinator = context.coordinator
        viewModel.captureAction = coordinator.takePicture
        let view = PreviewView()
        view.backgroundColor = .black
        coordinator.setupCameraSession(for: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var viewModel: CameraViewModel
        let captureSession = AVCaptureSession()
        let photoOutput = AVCapturePhotoOutput()

        init(viewModel: CameraViewModel) {
            self.viewModel = viewModel
            super.init()
//            setupCameraSession()
        }

        private let sessionQueue = DispatchQueue(label: "camera.session")

        func stopSession() {
            sessionQueue.async { [captureSession] in
                captureSession.stopRunning()
            }
        }

        func setupCameraSession(for view: PreviewView) {
            captureSession.sessionPreset = .photo

            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  captureSession.canAddInput(videoInput) else {
                      return
                  }

            captureSession.addInput(videoInput)

            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            // Fill the window and crop the overflow, the same center crop StripRenderer applies to the photo.
            view.previewLayer.session = captureSession
            view.previewLayer.videoGravity = .resizeAspectFill

            // startRunning() blocks, so keep it off the main thread.
            sessionQueue.async { [captureSession] in
                captureSession.startRunning()
            }
        }

        /// Returns false if the camera isn't ready, so the view model can retry the shot.
        func takePicture() -> Bool {
            guard let connection = photoOutput.connection(with: .video),
                  connection.isEnabled,
                  connection.isActive else {
                print("Camera is not ready. No active video connection.")
                return false
            }

            let settings = AVCapturePhotoSettings()
            // The app plays its own shutter sound (SoundEffect.shutter), so mute the system one
            // where iOS allows it (iOS 18+, and not in regions that require the shutter sound).
            if #available(iOS 18.0, *), photoOutput.isShutterSoundSuppressionSupported {
                settings.isShutterSoundSuppressionEnabled = true
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
            return true
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            // 캡처된 사진의 데이터를 UIImage로 변환합니다.
            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }

            // 좌우 반전 후 뷰모델에 전달 (4장이 모이면 뷰모델이 결과를 발행)
            let mirrored = image.withHorizontallyFlippedOrientation() ?? image
            DispatchQueue.main.async {
                self.viewModel.didCapture(mirrored)
            }
        }

    }
}
extension UIImage {
    // UIImage를 좌우 반전시키는 함수
    func withHorizontallyFlippedOrientation() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: .leftMirrored)
    }
}

