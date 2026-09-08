#!/usr/bin/env python3
"""Execute the production model-scoped offset without modifying a device."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "lara/kexploit/pe/rc.m").read_text()
start = source.index("static CGRect eagle_issue10_aura_frame(")
end = source.index("\n}\n", start) + 3
function = source[start:end]
assert source.count("eagle_issue10_aura_frame(") == 2
call = source.index("auraFrame = eagle_issue10_aura_frame(auraFrame, systemInfo.machine);")
assert source.index("CGRect auraFrame = eagle_island_fallback_frame") < source.index("CGFloat photoY = MAX(") < call
assert call < source.index("if (!eagle_prepare_island_fallback_view(")
test = r'''
#include <assert.h>
#include <string.h>
#include <stdio.h>
typedef struct { double x, y; } Point;
typedef struct { double width, height; } Size;
typedef struct { Point origin; Size size; } CGRect;
'''
test += function
test += r'''
int main(void) {
    const char *models[] = {"iPhone16,2", "iPhone17,3", "iPhone17,1",
        "iPhone17,2", "iPhone17,4", "iPhone16,1", "iPhone15,2",
        "iPhone15,3", "iPhone15,4", "iPhone15,5", "unknown", NULL};
    for (int device = 0; device < 12; device++) {
        for (int gallery = 0; gallery < 2; gallery++) {
            for (int width = 320; width <= 600; width += 10) {
                CGRect before = {{(width-134.0)/2.0, device == 1 ? 10.0 : 13.0}, {134,39}};
                if (gallery) { before.origin.y = -8.0; before.size.width = 176; before.size.height = 69; }
                CGRect after = eagle_issue10_aura_frame(before, models[device]);
                double shift = device < 2 ? 0.5 : 0;
                assert(after.origin.y == before.origin.y - shift);
                assert(after.origin.x == before.origin.x);
                assert(after.size.width == before.size.width && after.size.height == before.size.height);
            }
        }
    }
    puts("PASS: exactly -0.5pt on iPhone 15 Pro Max / iPhone 16 Aura and Gallery; other models, width, height and horizontal centering unchanged");
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-issue10-") as directory:
    directory = Path(directory)
    code = directory / "test.c"
    code.write_text(test)
    binary = directory / "test"
    subprocess.run(["xcrun", "clang", "-Wall", "-Wextra", "-Werror", str(code), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
