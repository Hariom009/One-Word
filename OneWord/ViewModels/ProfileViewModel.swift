//
//  ProfileViewModel.swift
//  OneWord
//
//  The Profile pane's seam: how many words you've bookmarked and read. Trivial now, but
//  it keeps the view off the persistence layer and stays testable without
//  SwiftUI. MainActor-isolated by default isolation.
//

import Foundation
import Observation
import ImageIO                  // the photo thumbnail — no AppKit needed
import UniformTypeIdentifiers   // UTType.jpeg

@Observable
final class ProfileViewModel {
    /// Bookmarks you keep by hand.
    private(set) var bookmarks = 0
    /// Every word you've read, across every shelf — a word met in two books counts twice.
    private(set) var learned = 0
    /// The German shelf alone: the only count the fluency goal is measured against.
    private(set) var learnedGerman = 0

    /// Cheap: both stores are already in memory. Safe to call on every change.
    func refresh() {
        bookmarks = SavedWords.all.count
        learned = LearnedWords.total
        learnedGerman = LearnedWords.count(in: Wordbook.german.id)
    }

    /// The picture you picked, shrunk to avatar size and re-encoded as JPEG — small
    /// enough to sit in UserDefaults beside `profileAvatar`, so the sidebar chip
    /// picks it up through @AppStorage the same way. Nil when ImageIO can't read it.
    ///
    /// ponytail: decoded on the main thread. A thumbnail read is quick even for a
    /// large photo; move it off-main if a huge RAW file ever hitches the picker.
    static func photo(from url: URL) -> Data? {
        // The file importer hands back a security-scoped URL in the sandbox.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  // Always from the full image: an embedded EXIF thumbnail can be tiny.
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,   // honour EXIF rotation
                  kCGImageSourceThumbnailMaxPixelSize: 512,   // 76pt header at 2x, with room for a wide crop
              ] as CFDictionary)
        else { return nil }

        let data = NSMutableData()
        guard let out = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(out, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(out) ? data as Data : nil
    }
}
