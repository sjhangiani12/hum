import AVFoundation
import Foundation
import Observation
import ShazamKit

// Handles mic capture on the audio thread — completely nonisolated
private final class MicCapture: @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private let session: SHSession

    init(session: SHSession) {
        self.session = session
    }

    func start() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        let session = self.session
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { buffer, time in
            session.matchStreamingBuffer(buffer, at: time)
        }

        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

@Observable
@MainActor
final class AudioRecognizer: NSObject, SHSessionDelegate {
    enum State: Equatable {
        case idle
        case listening
        case found(title: String, artist: String)
        case notFound
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var lastSong: RecognizedSong?
    private(set) var recentSongs: [RecognizedSong] = []

    private let session = SHSession()
    @ObservationIgnored private var capture: MicCapture?
    private let logger = SongLogger()

    override init() {
        super.init()
        session.delegate = self
    }

    func startListening() {
        state = .listening

        let mic = MicCapture(session: session)
        self.capture = mic

        do {
            try mic.start()
        } catch {
            state = .error("Mic error: \(error.localizedDescription)")
        }
    }

    func stopListening() {
        capture?.stop()
        capture = nil
        if case .listening = state {
            state = .idle
        }
    }

    func reset() {
        state = .idle
    }

    // MARK: - SHSessionDelegate

    nonisolated func session(_ session: SHSession, didFind match: SHMatch) {
        Task { @MainActor in
            self.capture?.stop()
            self.capture = nil

            guard let item = match.mediaItems.first else {
                self.state = .notFound
                return
            }

            let song = RecognizedSong(
                title: item.title ?? "Unknown",
                artist: item.artist ?? "Unknown",
                album: item.subtitle,
                artworkURL: item.artworkURL,
                appleMusicURL: item.appleMusicURL,
                shazamID: item.shazamID,
                genres: item.genres,
                isrc: item.isrc,
                recognizedAt: Date()
            )
            self.lastSong = song
            self.recentSongs.insert(song, at: 0)
            if self.recentSongs.count > 20 {
                self.recentSongs.removeLast()
            }
            self.state = .found(title: song.title, artist: song.artist)
            self.logger.log(song: song)
        }
    }

    nonisolated func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: (any Error)?) {
        Task { @MainActor in
            self.capture?.stop()
            self.capture = nil

            if let error = error {
                let nsError = error as NSError
                let fullMessage = "[\(nsError.domain) \(nsError.code)] \(nsError.localizedDescription)"
                print("ShazamKit error: \(fullMessage)")
                print("  userInfo: \(nsError.userInfo)")
                self.state = .error(fullMessage)
            } else {
                self.state = .notFound
            }
        }
    }
}
