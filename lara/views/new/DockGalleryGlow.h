#ifndef EAGLE_DOCK_GALLERY_GLOW_H
#define EAGLE_DOCK_GALLERY_GLOW_H
#include <math.h>

// Shared by the preview image and the installed Dock image. Geometry is in
// points; only the transparent halo canvas extends beyond the existing Dock.
#define EAGLE_DOCK_GLOW_PADDING 56.0
#define EAGLE_DOCK_GLOW_CORNER 40.0
#define EAGLE_DOCK_GLOW_HEIGHT 102.333333

static inline double eagle_dock_glow_alpha(double x, double y, double width, double height) {
    const double radius = fmin(EAGLE_DOCK_GLOW_CORNER, height / 2.0);
    const double qx = fabs(x) - (width / 2.0 - radius);
    const double qy = fabs(y) - (height / 2.0 - radius);
    const double distance = fmax(0.0, hypot(fmax(qx, 0.0), fmax(qy, 0.0))
        + fmin(fmax(qx, qy), 0.0) - radius);
    if (distance >= EAGLE_DOCK_GLOW_PADDING) return 0.0;
    // A visible near glow and a softer outer glow, with a zero-alpha edge.
    const double near = 0.72 * exp(-(distance * distance) / (2.0 * 7.0 * 7.0));
    const double far = 0.58 * exp(-(distance * distance) / (2.0 * 21.0 * 21.0));
    const double fade = fmin(1.0, (EAGLE_DOCK_GLOW_PADDING - distance) / 14.0);
    return fmin(1.0, near + far) * fade * fade * (3.0 - 2.0 * fade);
}
#endif
