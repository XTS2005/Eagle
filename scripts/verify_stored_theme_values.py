#!/usr/bin/env python3
"""Compile production saved-setting validation; no device or preference writes."""
from pathlib import Path
import argparse
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', type=Path)
args = parser.parse_args()
if args.baseline:
    aura = (args.baseline / 'AuraStudioView.swift').read_text()
    dock = (args.baseline / 'DockGalleryView.swift').read_text()
    preview = (args.baseline / 'DockCustomizerView.swift').read_text()
    flag = re.search(r'UInt32\(max\(activeFlagsRaw, 0\)\)', aura).group()
    intensity = re.search(r'eagle_set_dock_gallery_intensity\((Int32\(.*)\)', dock).group(1)
    capacity = re.search(r'ForEach\((0\.\.<selectedCapacity)', preview).group(1)
    cases = {
        'flags overflow': 'let activeFlagsRaw = Int.max\nprint(' + flag + ')',
        'NaN intensity': 'let intensity = Double.nan\nprint(' + intensity + ')',
        'negative preview capacity': 'let selectedCapacity = -1\nprint(Array(' + capacity + '))',
    }
    with tempfile.TemporaryDirectory(prefix='eagle-settings-before-') as temp:
        for name, source in cases.items():
            path = Path(temp) / 'main.swift'
            path.write_text('import Foundation\n' + source)
            binary = Path(temp) / 'test'
            subprocess.run(['swiftc', str(path), '-o', str(binary)], check=True)
            result = subprocess.run([str(binary)], capture_output=True, text=True)
            assert result.returncode != 0 and 'Fatal error:' in result.stderr, result.stderr
            print('REPRODUCED before fix: ' + name)
    raise SystemExit(0)

helper = (root / 'lara/classes/EagleStoredThemeValues.swift').read_text()
for file in ['lara/views/new/IslandGalleryView.swift', 'lara/views/new/DockGalleryView.swift',
             'lara/views/new/AuraStudioView.swift', 'lara/classes/EagleSceneAuraExecutor.swift']:
    source = (root / file).read_text()
    assert 'UInt32(max(' not in source, file
    assert 'EagleStoredThemeValues.flags(' in source, file
dock = (root / 'lara/views/new/DockGalleryView.swift').read_text()
assert 'let appliedIntensity = EagleStoredThemeValues.intensity(intensity)' in dock
assert 'eagle_set_dock_gallery_intensity(Int32((appliedIntensity * 100).rounded()))' in dock
assert 'UserDefaults.standard.set(appliedIntensity, forKey: "eagle.dockGallery.appliedGlowIntensity")' in dock
preview = (root / 'lara/views/new/DockCustomizerView.swift').read_text()
assert 'let previewCapacity = EagleStoredThemeValues.dockPreviewCapacity(selectedCapacity)' in preview
assert 'ForEach(0..<previewCapacity' in preview
assert 'ForEach(0..<selectedCapacity' not in preview
tests = r'''
for raw in [Int.min, -1, Int(UInt32.max) + 1, Int.max] {
    precondition(EagleStoredThemeValues.flags(raw) == 0)
}
for raw in [0, 1, 31, 32, 63, 255, Int(UInt32.max)] {
    precondition(EagleStoredThemeValues.flags(raw) == UInt32(raw))
}
for mask in 0..<256 {
    let flags = EagleStoredThemeValues.flags(mask)
    // Independent Island/Dock bits survive reading and clearing the other module.
    precondition(flags & ~UInt32(1) == UInt32(mask) & ~UInt32(1))
    precondition(flags & ~UInt32(32) == UInt32(mask) & ~UInt32(32))
}
for raw in [Double.nan, Double.infinity, -Double.infinity] {
    precondition(EagleStoredThemeValues.intensity(raw) == 0.72)
    precondition(Int32((EagleStoredThemeValues.intensity(raw) * 100).rounded()) == 72)
}
for raw in [-Double.greatestFiniteMagnitude, -1, 0, 0.001, 0.25, 0.72, 1, 2, Double.greatestFiniteMagnitude] {
    let value = EagleStoredThemeValues.intensity(raw)
    precondition(value.isFinite && (0...1).contains(value))
    precondition(value == min(max(raw, 0), 1))
    let native = Int32((value * 100).rounded())
    precondition((0...100).contains(native))
}
for raw in [Int.min, -1, 0, 3, 4, 5, 6, 7, Int.max] {
    let capacity = EagleStoredThemeValues.dockPreviewCapacity(raw)
    precondition((4...6).contains(capacity))
    precondition(Array(0..<capacity).count <= 6)
    precondition(capacity == ([4, 5, 6].contains(raw) ? raw : 5))
}
print("PASS: invalid flags, 256 preserved flag combinations, nonfinite/finite intensity and bounded capacity; production consumers checked")
'''
with tempfile.TemporaryDirectory(prefix='eagle-stored-settings-') as temp:
    path = Path(temp) / 'main.swift'
    path.write_text(helper + '\n' + tests)
    binary = Path(temp) / 'test'
    subprocess.run(['swiftc', '-swift-version', '5', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
