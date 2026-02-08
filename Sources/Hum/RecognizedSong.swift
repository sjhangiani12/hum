import Foundation

struct RecognizedSong: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String?
    let artworkURL: URL?
    let appleMusicURL: URL?
    let shazamID: String?
    let genres: [String]
    let isrc: String?
    let recognizedAt: Date

    var spotifyURL: URL? {
        let query: String
        if let isrc = isrc {
            query = "isrc:\(isrc)"
        } else {
            query = "\(title) \(artist)"
        }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://open.spotify.com/search/\(encoded)")
    }

    var markdownEntry: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: recognizedAt)

        var lines: [String] = []
        lines.append("## \(title) — \(artist)")
        lines.append("- **Recognized**: \(timestamp)")
        if let album = album { lines.append("- **Album**: \(album)") }
        if !genres.isEmpty { lines.append("- **Genres**: \(genres.joined(separator: ", "))") }
        if let url = spotifyURL { lines.append("- **Spotify**: [Open in Spotify](\(url))") }
        if let isrc = isrc { lines.append("- **ISRC**: \(isrc)") }
        lines.append("")
        return lines.joined(separator: "\n")
    }
}
