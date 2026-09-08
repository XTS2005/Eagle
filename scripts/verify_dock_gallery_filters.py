#!/usr/bin/env python3
"""Exercise the actual Dock Gallery selection helpers in a small Swift harness."""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
source = (repo / "lara/views/new/DockGalleryView.swift").read_text()


def declaration(marker):
    start = source.index(marker)
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


helpers = "\n".join(declaration(marker) for marker in [
    "private enum MediaFilter:", "private var selectedRemoteTheme:",
    "private var visibleRemoteThemes:", "private var favoriteIDs:",
    "private func toggleFavorite(_ theme:", "private func selectMediaFilter(_ filter:",
    "private func beginGalleryVisit()", "private func synchronizeRemoteSelection()",
    "private func rememberViewedTheme()", "private func stepRemote(_ step:",
])
harness = r'''
import Foundation
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
struct RemoteDockGalleryTheme { let id: String; let frameCount: Int }
struct Store { var themes: [RemoteDockGalleryTheme] = []; var downloadingID: String? }
struct UISelectionFeedbackGenerator { func selectionChanged() {} }
struct UIImpactFeedbackGenerator {
    enum Style { case soft }
    init(style: Style) {}
    func impactOccurred() {}
}
final class Harness {
    var remoteGallery = Store()
    var selectedRemoteID = ""
    var activeRemoteID = ""
    var readyRemotePreviewID = ""
    var isApplying = false
    var favoriteIDsJSON = "[]"
    var lastViewedStaticID = ""
    var lastViewedLiveID = ""
    var shuffledRemoteIDs: [String] = []
    var visitStarted = false
    private var mediaFilter: MediaFilter = .still
    private var rememberedSelections: [MediaFilter: String] = [:]
''' + helpers
harness += r'''
static func verify() {
    assert(MediaFilter.favorites.title == "Saves")
    assert(MediaFilter.favorites.rawValue == "Favorites") // Preserve stored identities.
    let h = Harness()
    let s1 = RemoteDockGalleryTheme(id: "s1", frameCount: 1)
    let s2 = RemoteDockGalleryTheme(id: "s2", frameCount: 1)
    let l1 = RemoteDockGalleryTheme(id: "l1", frameCount: 17)
    let l2 = RemoteDockGalleryTheme(id: "l2", frameCount: 17)
    h.remoteGallery.themes = [s1, l1, s2, l2]
    h.activeRemoteID = "l2"
    h.lastViewedStaticID = "s1"
    h.lastViewedLiveID = "l2"
    h.beginGalleryVisit()
    assert(h.mediaFilter == .still && h.selectedRemoteID == "s2")
    assert(Set(h.visibleRemoteThemes.map(\.id)) == ["s1", "s2"])
    let order = h.shuffledRemoteIDs
    h.synchronizeRemoteSelection()
    assert(h.shuffledRemoteIDs == order)
    h.readyRemotePreviewID = "s2"
    h.stepRemote(-1)
    assert(h.selectedRemoteID == "s1" && h.readyRemotePreviewID.isEmpty)
    h.stepRemote(1)
    assert(h.selectedRemoteID == "s2")
    h.selectMediaFilter(.live)
    assert(h.selectedRemoteID == "l1")
    h.stepRemote(1)
    assert(h.selectedRemoteID == "l2")
    h.selectMediaFilter(.still)
    assert(h.selectedRemoteID == "s2")
    h.selectMediaFilter(.live)
    assert(h.selectedRemoteID == "l2")
    h.selectMediaFilter(.still)
    h.toggleFavorite(s2)
    h.toggleFavorite(l1)
    assert(h.favoriteIDs == ["s2", "l1"])
    assert(h.selectedRemoteID == "s2" && h.shuffledRemoteIDs == order)
    h.selectMediaFilter(.favorites)
    assert(Set(h.visibleRemoteThemes.map(\.id)) == ["s2", "l1"])
    let restored = Harness()
    restored.favoriteIDsJSON = h.favoriteIDsJSON
    restored.remoteGallery.themes = h.remoteGallery.themes
    restored.beginGalleryVisit()
    restored.selectMediaFilter(.favorites)
    assert(Set(restored.visibleRemoteThemes.map(\.id)) == ["s2", "l1"])
    h.toggleFavorite(h.selectedRemoteTheme!)
    assert(h.visibleRemoteThemes.count == 1)
    h.readyRemotePreviewID = h.selectedRemoteID
    h.stepRemote(1)
    assert(h.readyRemotePreviewID == h.selectedRemoteID)
    h.toggleFavorite(h.selectedRemoteTheme!)
    assert(h.selectedRemoteID.isEmpty && h.selectedRemoteTheme == nil)
    h.stepRemote(1)
    assert(h.selectedRemoteTheme == nil)
    h.selectMediaFilter(.still)
    assert(h.selectedRemoteID == "s2")
    h.isApplying = true
    h.stepRemote(1)
    assert(h.selectedRemoteID == "s2")
    h.selectMediaFilter(.live)
    assert(h.mediaFilter == .still)
    h.isApplying = false
    h.remoteGallery.downloadingID = "s2"
    h.stepRemote(1)
    assert(h.selectedRemoteID == "s2")
    h.remoteGallery.downloadingID = nil
    h.remoteGallery.themes = [s1, l1]
    h.synchronizeRemoteSelection()
    assert(h.selectedRemoteID == "s1")
    h.remoteGallery.themes = []
    h.synchronizeRemoteSelection()
    h.stepRemote(1)
    assert(h.selectedRemoteID.isEmpty && h.selectedRemoteTheme == nil)
    h.remoteGallery.themes = [s1]
    h.synchronizeRemoteSelection()
    assert(h.selectedRemoteID == "s1")
    h.selectMediaFilter(.live)
    assert(h.selectedRemoteID.isEmpty && h.selectedRemoteTheme == nil)
    h.toggleFavorite(s1)
    h.remoteGallery.themes = []
    h.synchronizeRemoteSelection()
    assert(h.favoriteIDs == ["s1"])
    h.remoteGallery.themes = [s1]
    h.synchronizeRemoteSelection()
    h.selectMediaFilter(.favorites)
    assert(h.selectedRemoteID == "s1")

    let large = Harness()
    large.remoteGallery.themes = (1...232).map { RemoteDockGalleryTheme(id: "s\($0)", frameCount: 1) }
        + (1...196).map { RemoteDockGalleryTheme(id: "l\($0)", frameCount: 17) }
    var visits = Set<[String]>()
    for _ in 0..<100 {
        let oldStatic = large.lastViewedStaticID
        let oldLive = large.lastViewedLiveID
        large.beginGalleryVisit()
        assert(large.visibleRemoteThemes.count == 232)
        assert(large.selectedRemoteID != oldStatic)
        assert(Set(large.shuffledRemoteIDs).count == 428)
        let sessionOrder = large.shuffledRemoteIDs
        visits.insert(sessionOrder)
        large.selectMediaFilter(.live)
        assert(large.visibleRemoteThemes.count == 196 && large.selectedRemoteID != oldLive)
        var seen = Set<String>()
        for _ in 0..<196 {
            seen.insert(large.selectedRemoteID)
            large.stepRemote(1)
        }
        assert(seen.count == 196)
        large.synchronizeRemoteSelection()
        assert(large.shuffledRemoteIDs == sessionOrder)
    }
    assert(visits.count == 100)
    let selected = large.selectedRemoteID
    let before = large.shuffledRemoteIDs
    large.remoteGallery.themes.append(RemoteDockGalleryTheme(id: "new", frameCount: 1))
    large.synchronizeRemoteSelection()
    assert(large.selectedRemoteID == selected)
    assert(Array(large.shuffledRemoteIDs.prefix(before.count)) == before)
    restored.favoriteIDsJSON = "broken JSON"
    assert(restored.favoriteIDs.isEmpty)
    print("PASS: 100 shuffled visits, no repeated opening theme, 428 unique styles, stable session order, category wraparound, saved favorites, removal and empty favorites, stale preview reset, operation lock, catalog updates")
}
}
Harness.verify()
'''
with tempfile.TemporaryDirectory(prefix="eagle-filter-test-") as temporary:
    path = Path(temporary) / "Filters.swift"
    path.write_text(harness)
    subprocess.run(["swift", str(path)], check=True)
