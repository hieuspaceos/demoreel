# DemoReel

A tiny, vendorable **headless demo-video renderer** for macOS apps — one
Swift file you drop into any AppKit/Swift project to render scripted,
screen-studio-style demo videos without real screen recording.

Think of it as *"Remotion, but your scenes are drawn with the app's real
AppKit views"* — pixel-faithful, deterministic, and fast enough to render
a 30 s 1080p60 video in ~2 minutes on Apple Silicon.

## Why

Recording real screen demos is flaky: windows move, notifications pop,
the cursor jitters, permissions get in the way. DemoReel renders every
frame yourself inside a `CGContext` — the desktop wallpaper is real,
the window chrome is real, and the app's own views can be drawn directly.

## What the engine gives you

| Piece | What it does |
|---|---|
| `Demo` / `Scene` | Frame-range timeline; each scene draws a `CGContext` |
| `Ease` | `in`, `out`, `inOut`, `spring` — cubic + spring easings |
| `desktopImage` | Renders the user's real wallpaper + menubar + Dock strip |
| `dock` | Fake translucent Dock with icons, one can be `highlight`ed |
| `cursor` | Shape-drawn macOS arrow + click ring (no image deps) |
| `cursorTrack` | Scripted waypoint cursor paths |
| `caption` | Bottom pill caption per scene |
| `zoomed` | Rounded zoom lens — magnifies any region, animated pop-in |
| `roundRectPath`, `drawText`, `textWidth` | Small drawing utils |

## Using it in an app

1. Copy `Sources/DemoReel.swift` into your app target.
2. Write a demo script — a `Demo` with `Scene`s:

```swift
import Cocoa

let demo = Demo(scenes: [
    Scene(0...120, caption: "Meet my app") { ctx, t, f in
        // draw your window — t eases 0→1 across the scene
        drawMyWindow(ctx, alpha: t)
    },
    Scene(121...240, caption: "Click a thing") { ctx, t, f in
        drawMyWindow(ctx, alpha: 1)
        DemoReel.cursor(ctx, at: CGPoint(x: 640, y: 400),
                        clicking: f > 180)
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/frames")
```

3. Compile it once per script:

```sh
swiftc -O -o demo-render Sources/DemoReel.swift MyDemo.swift
./demo-render                          # writes PNG frames
ffmpeg -framerate 60 -i /tmp/frames/f%04d.png \
       -c:v libx264 -pix_fmt yuv420p demo.mp4
```

Inside a host app you can call `DemoReel.run` from a hidden CLI flag —
e.g. SwiftShot renders its demo with `--record-demo` — so the real views
(`EditorCanvasView`, etc.) are used verbatim.

## Included demo scripts

- `demos/swishlite.swift` — 35 s SwishLite feature walkthrough
- `demos/main.swift` — 25 s SwiftShot flow (region select → annotate →
  copy → floating preview → save dialog)

## Conventions

- Output is `1920×1080 @ 60fps` PNG frames (`f%04d.png`).
- All coordinates are **CG y-up** in points; helpers draw in that space.
- Scenes are deterministic — same frame → same pixels.

## Requirements

macOS 14+, Swift toolchain (Xcode CLT). No third-party deps.
Wallpaper lookup uses `NSWorkspace.desktopImageURL` — falls back to a
gradient when running headless without a wallpaper.
