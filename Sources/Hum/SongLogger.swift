import Foundation

final class SongLogger: Sendable {
    let fileURL: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = home
            .appendingPathComponent("Documents")
            .appendingPathComponent("ShazamLog.md")
    }

    func log(song: RecognizedSong) {
        let entry = song.markdownEntry

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "# Shazam Log\n\nSongs identified by Hum.\n\n---\n\n"
            let data = (header + entry).data(using: .utf8)!
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
        } else {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(("---\n\n" + entry).data(using: .utf8)!)
                handle.closeFile()
            }
        }
    }
}
