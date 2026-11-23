import SwiftUI
import AVFoundation

class CameraViewModel: ObservableObject {
    static let countdownSeconds = 6
    static let photosPerSession = 4

    /// Photos captured so far in this session (already mirrored).
    @Published var capturedImages: [UIImage] = []
    /// Seconds left before the next shot. 0 means a shot is being taken right now.
    @Published var remainingTime = 0
    /// Set once all photos are captured. The view moves to the result screen when this changes.
    @Published var finalPhotos: [UIImage]? = nil

    /// Takes a picture. Returns false if the camera was not ready, so the shot is retried.
    var captureAction: (() -> Bool)?
    private var timer: Timer?
    private var shotsTaken = 0

    func startCapturing() {
        timer?.invalidate()
        shotsTaken = 0
        capturedImages.removeAll()
        finalPhotos = nil
        remainingTime = Self.countdownSeconds
        playTick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Runs once per second: 6, 5, 4, 3, 2, 1, 📸 (shot), then the next countdown.
    private func tick() {
        if remainingTime > 1 {
            remainingTime -= 1
            playTick()
            return
        }

        if remainingTime == 1 {
            remainingTime = 0
            if captureAction?() == true {
                SoundEffect.shutter.play()
                shotsTaken += 1
                if shotsTaken >= Self.photosPerSession {
                    stopTimer()
                }
            }
            // If the camera wasn't ready, remainingTime stays 0 and the next tick restarts the countdown.
            return
        }

        // remainingTime == 0: the shot just happened, start the next countdown.
        remainingTime = Self.countdownSeconds
        playTick()
    }

    /// Beep for the number now on screen; higher for the last three seconds.
    private func playTick() {
        (remainingTime <= 3 ? SoundEffect.tickFinal : SoundEffect.tick).play()
    }

    /// Called by the camera on the main thread with each finished photo.
    func didCapture(_ image: UIImage) {
        guard capturedImages.count < Self.photosPerSession else { return }
        capturedImages.append(image)
        if capturedImages.count == Self.photosPerSession {
            stopTimer()
            finalPhotos = capturedImages
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
