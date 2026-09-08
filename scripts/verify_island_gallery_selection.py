#!/usr/bin/env python3
"""Test the production Island Gallery models/selection helpers, without native writes."""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
source = (repo / "lara/views/new/IslandGalleryPresentation.swift").read_text()
assert "IslandGalleryScene" not in source
assert "presentationPicker" not in source
assert "collectionIntro" not in source
assert "Small Island" not in source
assert "A preview of the look" not in source
assert 'case .still: return "Static"' in source


def declaration(marker):
    start = source.index(marker)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


style = (repo / "lara/views/new/IslandGalleryView.swift").read_text().split("private final class IslandGalleryRemoteCallBox:")[0]
model = (repo / "lara/views/new/IslandLiveMedia.swift").read_text().split("/// An isolated,")[0]
types = source.split("struct IslandGalleryView: View")[0]
helpers = "\n".join(declaration(marker) for marker in [
    "private var artworks:", "private var favorites:", "private var visibleArtworks:",
    "private var selected:", "private var activeArtwork:", "private func isActive(",
    "private var selectionIndex:", "private func toggleFavorite(", "private func select(",
    "private func selectFilter(", "private func synchronizeSelection(",
    "private func restoreSelection(", "private func step(",
])
stub = r'''
enum LaraL10n { static func text(en: String, es: String) -> String { es } }
enum IslandLiveMedia {
    static let previewURL = URL(string: "https://example.test/singularity-live.gif")!
    static let posterURL = URL(string: "https://example.test/singularity-live.png")!
}
struct UISelectionFeedbackGenerator { func selectionChanged() {} }
final class Harness {
    var selectedRaw = IslandGalleryStyle.starlight.rawValue
    var selectedID = ""
    var favoritesJSON = "[]"
    var activeFlagsRaw = 0
    var activeIslandModeRaw = 0
    var activeLiveID = "singularity-live"
    var liveThemes: [IslandLiveTheme] = []
    var filter: IslandGalleryFilter = .all
    var search = ""
    var applying = false
    var rememberedSelections: [IslandGalleryFilter: String] = [:]
'''
tests = r'''
    static func verify() throws {
        let catalog = try JSONDecoder().decode(IslandLiveCatalog.self,
            from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        assert(catalog.isSupported)
        let h = Harness()
        assert(IslandGalleryFilter.still.title == "Static")
        assert(IslandGalleryFilter.favorites.title == "Saves")
        h.restoreSelection()
        assert(h.selectedID == "island-9")
        h.liveThemes = catalog.themes
        assert(h.artworks.count == 51 && Set(h.artworks.map(\.id)).count == 51)
        h.selectFilter(.live)
        assert(h.visibleArtworks.count == 42)
        var seen = Set<String>()
        for _ in 0..<42 { seen.insert(h.selected!.id); h.step(1) }
        assert(seen.count == 42 && h.selectionIndex == 0)
        h.step(-1)
        assert(h.selectionIndex == 41)
        let lastLive = h.selected!
        h.selectFilter(.still)
        assert(h.visibleArtworks.count == 9)
        h.step(3)
        let still = h.selected!
        h.selectFilter(.live)
        assert(h.selectedID == lastLive.id && h.selectedRaw == 36)
        h.selectFilter(.still)
        assert(h.selectedID == still.id && h.selectedRaw == still.style.rawValue)
        h.toggleFavorite(still)
        h.toggleFavorite(lastLive)
        h.selectFilter(.favorites)
        assert(h.visibleArtworks.count == 2)
        let saved = Harness()
        saved.liveThemes = catalog.themes
        saved.favoritesJSON = h.favoritesJSON
        saved.selectFilter(.favorites)
        assert(Set(saved.visibleArtworks.map(\.id)) == [still.id, lastLive.id])
        h.toggleFavorite(still)
        h.synchronizeSelection() // The view's onChange observer.
        assert(h.selected?.id == lastLive.id)
        h.toggleFavorite(lastLive)
        h.synchronizeSelection()
        assert(h.visibleArtworks.isEmpty && h.selected == nil)
        h.step(1)
        h.selectFilter(.all)
        h.search = "  BLUE-FLAME  "
        h.synchronizeSelection()
        assert(h.visibleArtworks.count == 1 && h.selected?.id == "blue-flame")
        h.search = "no-such-island-style"
        h.synchronizeSelection()
        assert(h.selected == nil)
        h.search = ""
        h.synchronizeSelection()
        assert(h.selected?.id == "blue-flame")
        h.activeFlagsRaw = 1
        h.activeIslandModeRaw = 36
        h.activeLiveID = "blue-flame"
        assert(h.artworks.filter(h.isActive).map(\.id) == ["blue-flame"])
        h.applying = true
        let selectedBefore = h.selectedID
        let favoritesBefore = h.favoritesJSON
        h.step(1)
        h.selectFilter(.still)
        h.toggleFavorite(lastLive)
        assert(h.selectedID == selectedBefore && h.filter == .all && h.favoritesJSON == favoritesBefore)
        h.applying = false
        h.favoritesJSON = "invalid"
        assert(h.favorites.isEmpty)
        let restored = Harness()
        restored.activeFlagsRaw = 1
        restored.activeIslandModeRaw = 36
        restored.activeLiveID = "blue-flame"
        restored.restoreSelection()
        assert(restored.selectedID == "blue-flame") // Before remote catalog arrives.
        restored.liveThemes = catalog.themes
        restored.synchronizeSelection()
        assert(restored.selected?.id == "blue-flame")
        restored.liveThemes = []
        restored.synchronizeSelection()
        assert(restored.selected != nil) // Built-in art remains usable offline.
        print("PASS: 51 unique styles; 42 Live; 9 static; carousel wraparound; category memory; saved/removable favorites; empty/search states; unique active Live identity; operation lock; cold-start restoration; offline fallback")
    }
}
try Harness.verify()
'''
with tempfile.TemporaryDirectory(prefix="eagle-island-selection-") as temporary:
    path = Path(temporary) / "Selection.swift"
    path.write_text((style + model + types + stub + helpers + tests).replace("import UIKit\n", ""))
    subprocess.run(["swift", str(path), str(repo.parent / "Eagle-Gallery/catalogs/island-gallery-v1.json")], check=True)
