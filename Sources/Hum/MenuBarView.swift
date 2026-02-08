import SwiftUI

struct MenuBarView: View {
    @Bindable var recognizer: AudioRecognizer

    var body: some View {
        VStack(spacing: 12) {
            stateContent
                .frame(minHeight: 100)

            if !recognizer.recentSongs.isEmpty {
                Divider()
                recentSongsSection
            }

            Divider()
            footerSection
        }
        .padding()
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.2), value: recognizer.state)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch recognizer.state {
        case .idle:
            idleView
        case .listening:
            listeningView
        case .found(let title, let artist):
            foundView(title: title, artist: artist)
        case .notFound:
            notFoundView
        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        Button(action: { recognizer.startListening() }) {
            Label("Shazam", systemImage: "waveform")
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var listeningView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.regular)
            Text("Listening...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("Cancel") {
                recognizer.stopListening()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private func foundView(title: String, artist: String) -> some View {
        VStack(spacing: 8) {
            artworkImage(url: recognizer.lastSong?.artworkURL, size: 60)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(title) — \(artist)", forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if let song = recognizer.lastSong, let url = song.spotifyURL {
                    Link(destination: url) {
                        Label("Spotify", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }

            Button(action: { recognizer.startListening() }) {
                Label("Shazam Again", systemImage: "waveform")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var notFoundView: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.title)
                .foregroundStyle(.orange)

            Text("No match found")
                .font(.headline)

            Text("Make sure music is playing nearby")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: { recognizer.startListening() }) {
                Label("Try Again", systemImage: "waveform")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { recognizer.startListening() }) {
                Label("Try Again", systemImage: "waveform")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Recent Songs

    private var recentSongsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(recognizer.recentSongs.prefix(5)) { song in
                HStack(spacing: 8) {
                    artworkImage(url: song.artworkURL, size: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(song.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(timeAgo(song.recognizedAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Button("Open Log") {
                let logger = SongLogger()
                let url = logger.fileURL
                if !FileManager.default.fileExists(atPath: url.path) {
                    let header = "# Shazam Log\n\nSongs identified by Hum.\n\n---\n\n"
                    FileManager.default.createFile(atPath: url.path, contents: header.data(using: .utf8))
                }
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.borderless)
            .font(.caption)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .keyboardShortcut("q")
        }
    }

    // MARK: - Helpers

    private func artworkImage(url: URL?, size: CGFloat) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        artworkPlaceholder(size: size)
                    }
                }
            } else {
                artworkPlaceholder(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 30 ? 8 : 4))
    }

    private func artworkPlaceholder(size: CGFloat) -> some View {
        Image(systemName: "music.note")
            .font(size > 30 ? .title : .caption2)
            .foregroundStyle(.purple)
            .frame(width: size, height: size)
            .background(.purple.opacity(0.1))
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
