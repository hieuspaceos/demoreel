import Cocoa

// DemoReel — headless demo-video renderer for macOS apps.
// Vendor this file into an app target; the app defines a `Demo` (a list of
// Scenes over a frame timeline) and calls `DemoReel.run(demo:outdir:)`.
// Engine owns: frame loop, synthetic desktop scene, cursor layer, captions,
// easing. App owns: what its UI looks like (a draw closure per scene).
//
// ffmpeg -framerate 60 -i outdir/f%04d.png -c:v libx264 -pix_fmt yuv420p out.mp4

// MARK: - Timeline primitives

public enum Ease {
    public static func linear(_ t: CGFloat) -> CGFloat { t }
    public static func out(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 3) }
    public static func inOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    public static func spring(_ t: CGFloat) -> CGFloat {
        1 - cos(t * .pi * 2.5) * exp(-t * 4.5)
    }
}

public struct Demo {
    public var fps = 60
    public var size = CGSize(width: 1920, height: 1080)
    public var scenes: [Scene]
    /// Optional scene a wallpaper/desktop is drawn under everything.
    public var backdrop: Scene? = nil
    public init(scenes: [Scene]) { self.scenes = scenes }
}

/// One contiguous slice of the timeline with its own draw closure.
/// `t` passed to draw is 0..1 progress within this scene.
public struct Scene {
    public var range: ClosedRange<Int>
    public var caption: String? = nil
    public var draw: (CGContext, CGFloat, Int) -> Void   // ctx, t, absFrame
    public init(_ range: ClosedRange<Int>, caption: String? = nil,
                draw: @escaping (CGContext, CGFloat, Int) -> Void) {
        self.range = range; self.caption = caption; self.draw = draw
    }
}

// MARK: - Cursor

public struct CursorTrack {
    /// Keyframes: (frame, position, clicking)
    public var keys: [(Int, CGPoint, Bool)] = []
    public init() {}
    public mutating func move(_ f: Int, _ p: CGPoint, click: Bool = false) {
        keys.append((f, p, click))
    }
    /// Position and click state at absolute frame.
    public func sample(_ f: Int) -> (CGPoint, Bool)? {
        guard !keys.isEmpty, f >= keys[0].0 else { return nil }
        var a = keys[0], b = keys[0]
        for k in keys { if k.0 <= f { a = k } else { b = k; break } }
        if b.0 == a.0 { return (a.1, a.2) }
        let t = Ease.inOut(CGFloat(f - a.0) / CGFloat(b.0 - a.0))
        return (CGPoint(x: a.1.x + (b.1.x - a.1.x) * t,
                        y: a.1.y + (b.1.y - a.1.y) * t), b.2)
    }
}

// MARK: - Engine

public enum DemoReel {

    /// Renders `last+1` frames concurrently — draw closures are per-frame and
    /// deterministic by contract (same frame → same pixels), so parallelizing
    /// is safe. PNG writes happen inside each worker autoreleasepool.
    public static func run(demo: Demo, outdir: String) {
        try? FileManager.default.createDirectory(atPath: outdir,
                                                 withIntermediateDirectories: true)
        let last = demo.scenes.map(\.range.upperBound).max() ?? 0
        let base = desktopImage(size: demo.size)
        let t0 = CFAbsoluteTimeGetCurrent()
        let lock = NSLock()
        var written = 0
        DispatchQueue.concurrentPerform(iterations: last + 1) { f in
            autoreleasepool {
                render(demo: demo, frame: f, base: base, outdir: outdir)
            }
            lock.lock(); written += 1
            if written % 120 == 0 || written == last + 1 {
                FileHandle.standardOutput.write("frame \(written)/\(last + 1)\n".data(using: .utf8)!)
            }
            lock.unlock()
        }
        let dt = CFAbsoluteTimeGetCurrent() - t0
        print("done -> \(outdir)  (\(last + 1) frames @ \(demo.fps)fps = \(String(format: "%.1f", Double(last) / Double(demo.fps)))s video, rendered in \(String(format: "%.1f", dt))s)")
    }

    private static func render(demo: Demo, frame f: Int, base: CGImage?, outdir: String) {
        let W = Int(demo.size.width), H = Int(demo.size.height)
        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let base else { return }
        ctx.draw(base, in: CGRect(x: 0, y: 0, width: demo.size.width, height: demo.size.height))
        menubar(ctx, size: demo.size)

        for s in demo.scenes where s.range.contains(f) {
            let t = CGFloat(f - s.range.lowerBound) / CGFloat(s.range.upperBound - s.range.lowerBound)
            s.draw(ctx, t, f)
            if let cap = s.caption { caption(ctx, cap, size: demo.size, t: captionT(t)) }
        }
        if let img = ctx.makeImage() {
            let png = NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])
            try? png?.write(to: URL(fileURLWithPath: String(format: "%@/f%04d.png", outdir, f)))
        }
    }

    /// Captions fade in over first 8% of a scene, out over last 8%.
    private static func captionT(_ t: CGFloat) -> CGFloat {
        let i = min(1, t / 0.08), o = min(1, (1 - t) / 0.08)
        return min(i, o)
    }

    // MARK: built-in layers apps can call inside their draw closures

    /// Real desktop image (wallpaper + Finder-window furniture), rendered once
    /// at the requested pixel size and reused as the base layer.
    public static func desktopImage(size: CGSize) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        // wallpaper cover-fit
        var drew = false
        if let url = NSWorkspace.shared.desktopImageURL(for: NSScreen.main ?? NSScreen()),
           let wp = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let z = max(size.width / CGFloat(wp.width), size.height / CGFloat(wp.height))
            ctx.draw(wp, in: CGRect(x: (size.width - CGFloat(wp.width) * z) / 2,
                                    y: (size.height - CGFloat(wp.height) * z) / 2,
                                    width: CGFloat(wp.width) * z, height: CGFloat(wp.height) * z))
            drew = true
        }
        if !drew {
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [CGColor(red: 0.10, green: 0.18, blue: 0.42, alpha: 1),
                         CGColor(red: 0.42, green: 0.24, blue: 0.55, alpha: 1),
                         CGColor(red: 0.75, green: 0.33, blue: 0.49, alpha: 1)] as CFArray,
                locations: [0, 0.55, 1])!
            ctx.drawLinearGradient(g, start: .zero,
                                   end: CGPoint(x: size.width, y: size.height), options: [])
        }
        return ctx.makeImage()
    }

    /// NSArrow cursor + optional click ring, drawn on top at `p` (y-up coords).
    public static func cursor(_ ctx: CGContext, at p: CGPoint, clicking: Bool) {
        ctx.saveGState()
        ctx.translateBy(x: p.x, y: p.y)
        // classic arrow cursor outline (tip at origin, pointing up-left; CG y-up)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 17))
        path.addLine(to: CGPoint(x: 4.6, y: 12.4))
        path.addLine(to: CGPoint(x: 7.4, y: 18.2))
        path.addLine(to: CGPoint(x: 10.4, y: 16.6))
        path.addLine(to: CGPoint(x: 7.7, y: 11))
        path.addLine(to: CGPoint(x: 12.4, y: 11))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.fillPath()
        ctx.addPath(path)
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
        ctx.setLineWidth(1.4)
        ctx.strokePath()
        ctx.restoreGState()
        if clicking {
            ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.7))
            ctx.setLineWidth(2.5)
            ctx.strokeEllipse(in: CGRect(x: p.x - 18, y: p.y - 18, width: 36, height: 36))
        }
    }

    public static func caption(_ ctx: CGContext, _ s: String, size: CGSize, t: CGFloat) {
        guard t > 0 else { return }
        ctx.saveGState()
        ctx.setAlpha(t)
        let w = textWidth(s, size: 26) + 44
        let h = CGFloat(46)
        let r = CGRect(x: (size.width - w) / 2, y: 34, width: w, height: h)
        roundRectPath(ctx, r, 12)
        ctx.setFillColor(CGColor(gray: 0.06, alpha: 0.85))
        ctx.fillPath()
        drawText(ctx, s, at: CGPoint(x: r.minX + 22, y: r.minY + 13),
                 size: 26, color: CGColor(gray: 1, alpha: 1))
        ctx.restoreGState()
    }

    public static func menubar(_ ctx: CGContext, size: CGSize) {
        ctx.setFillColor(CGColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 0.85))
        ctx.fill(CGRect(x: 0, y: size.height - 26, width: size.width, height: 26))
        drawText(ctx, "  Finder   File   Edit   View   Go   Window   Help",
                 at: CGPoint(x: 14, y: size.height - 19), size: 13,
                 color: CGColor(gray: 0.1, alpha: 1))
        drawText(ctx, "Mon 19 Oct 15:00",
                 at: CGPoint(x: size.width - 165, y: size.height - 19), size: 12,
                 color: CGColor(gray: 0.1, alpha: 1))
    }

    // MARK: helpers usable by app draw closures

    public static func roundRectPath(_ ctx: CGContext, _ r: CGRect, _ rad: CGFloat) {
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil))
    }

    public static func drawText(_ ctx: CGContext, _ s: String, at p: CGPoint,
                                size: CGFloat, color: CGColor) {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [
            .font: NSFont.systemFont(ofSize: size),
            .foregroundColor: NSColor(cgColor: color) ?? .white]))
        ctx.saveGState(); ctx.textPosition = p; CTLineDraw(line, ctx); ctx.restoreGState()
    }

    public static func textWidth(_ s: String, size: CGFloat) -> CGFloat {
        NSAttributedString(string: s,
            attributes: [.font: NSFont.systemFont(ofSize: size)]).size().width
    }
}

// MARK: - Composite pieces (Finder window, window card)

public extension DemoReel {

    /// Dark Finder-style window: sidebar + icon grid.
    static func finderWindow(_ ctx: CGContext, rect: CGRect,
                             title: String, items: [String], folders: Bool) {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 40,
                      color: CGColor(gray: 0, alpha: 0.45))
        roundRectPath(ctx, rect, 10)
        ctx.setFillColor(CGColor(gray: 0.12, alpha: 1))
        ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.saveGState()
        roundRectPath(ctx, rect, 10)
        ctx.clip()
        ctx.setFillColor(CGColor(gray: 0.15, alpha: 1))
        ctx.fill(CGRect(x: rect.minX, y: rect.minY, width: 190, height: rect.height))
        let side = ["Recents","Shared","","FAVORITES","Applications","Desktop","Documents",
                    "Downloads","","LOCATIONS","iCloud Drive","Macintosh HD","Network","Trash"]
        var sy = rect.maxY - 60
        for s in side {
            let head = s == "FAVORITES" || s == "LOCATIONS"
            drawText(ctx, s.isEmpty ? " " : s, at: CGPoint(x: rect.minX + 14, y: sy),
                     size: head ? 10 : 12,
                     color: head ? CGColor(gray: 0.45, alpha: 1) : CGColor(gray: 0.75, alpha: 1))
            sy -= s.isEmpty ? 14 : 20
        }
        ctx.setFillColor(CGColor(gray: 0.17, alpha: 1))
        ctx.fill(CGRect(x: rect.minX + 190, y: rect.maxY - 40, width: rect.width - 190, height: 40))
        for (i, c) in [CGColor(red:1,green:0.37,blue:0.34,alpha:1),
                       CGColor(red:1,green:0.74,blue:0.18,alpha:1),
                       CGColor(red:0.16,green:0.78,blue:0.25,alpha:1)].enumerated() {
            ctx.setFillColor(c)
            ctx.fillEllipse(in: CGRect(x: rect.minX + 12 + CGFloat(i) * 20,
                                       y: rect.maxY - 26, width: 12, height: 12))
        }
        drawText(ctx, title, at: CGPoint(x: rect.minX + 210, y: rect.maxY - 27),
                 size: 13, color: CGColor(gray: 0.6, alpha: 1))
        for (i, name) in items.enumerated() {
            let col = i % 4, row = i / 4
            let ix = rect.minX + 214 + CGFloat(col) * 130
            let iy = rect.maxY - 140 - CGFloat(row) * 120
            let ir = CGRect(x: ix, y: iy, width: 60, height: 46)
            roundRectPath(ctx, ir, 8)
            ctx.setFillColor(folders ? CGColor(red:0.49,green:0.78,blue:0.95,alpha:1)
                                     : CGColor(red:0.55,green:0.57,blue:0.62,alpha:1))
            ctx.fillPath()
            if folders { ctx.fill(CGRect(x: ir.minX, y: ir.maxY - 4, width: 22, height: 8)) }
            drawText(ctx, name,
                     at: CGPoint(x: ix - max(0, textWidth(name, size: 11) - 60) / 2, y: iy - 14),
                     size: 11, color: CGColor(gray: 0.85, alpha: 1))
        }
        ctx.restoreGState(); ctx.restoreGState()
    }

    /// Letterboxed "screen content" card on dark blurred backdrop — like
    /// Screen Studio's presentation of a capture.
    static func card(_ ctx: CGContext, image: CGImage, in bounds: CGSize,
                     t: CGFloat = 1) -> CGRect {
        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
        ctx.fill(CGRect(origin: .zero, size: bounds))
        let sw = CGFloat(image.width), sh = CGFloat(image.height)
        let z = min(bounds.width / sw, bounds.height / sh) * 0.92
        let r = CGRect(x: (bounds.width - sw * z) / 2,
                       y: (bounds.height - sh * z) / 2 + (1 - t) * 40,
                       width: sw * z, height: sh * z)
        ctx.setAlpha(t)
        ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 60,
                      color: CGColor(gray: 0, alpha: 0.55))
        roundRectPath(ctx, r, 12)
        ctx.setFillColor(CGColor(gray: 0.1, alpha: 1))
        ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.saveGState()
        roundRectPath(ctx, r, 12)
        ctx.clip()
        ctx.draw(image, in: r)
        ctx.restoreGState()
        ctx.restoreGState()
        return r
    }
}

// MARK: - Zoom lens

public extension DemoReel {
    /// Magnifies the area around `center` by `factor`, clipped to a rounded
    /// rect `lens`. `t` animates the lens in (0=hidden, 1=full).
    /// `drawInner` is called with the context already translated/scaled —
    /// draw the scene content inside it a second time.
    static func zoomed(_ ctx: CGContext, lens: CGRect, center: CGPoint,
                       factor: CGFloat, t: CGFloat,
                       drawInner: (CGContext) -> Void) {
        guard t > 0 else { return }
        ctx.saveGState()
        // lens pop-in
        let lt = Ease.spring(t)
        let l = CGRect(x: lens.midX - lens.width * lt / 2,
                       y: lens.midY - lens.height * lt / 2,
                       width: lens.width * lt, height: lens.height * lt)
        ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 30,
                      color: CGColor(gray: 0, alpha: 0.5))
        roundRectPath(ctx, l, 14)
        ctx.setFillColor(CGColor(gray: 0.1, alpha: 1))
        ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        roundRectPath(ctx, l, 14)
        ctx.clip()
        // redraw scene zoomed: keep `center` of source pinned to lens center
        let fx = factor * lt
        ctx.translateBy(x: l.midX, y: l.midY)
        ctx.scaleBy(x: fx, y: fx)
        ctx.translateBy(x: -center.x, y: -center.y)
        drawInner(ctx)
        ctx.restoreGState()
        // border
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.5 * lt))
        ctx.setLineWidth(1.5)
        roundRectPath(ctx, l, 14)
        ctx.strokePath()
        ctx.restoreGState()
    }
}

// MARK: - Fake Dock

public extension DemoReel {
    /// Translucent macOS Dock centered at the bottom, `icons` app dots.
    /// Returns the center point of icon `highlight` (for zoom/gesture targets).
    @discardableResult
    static func dock(_ ctx: CGContext, size: CGSize, icons: Int = 8,
                     highlight: Int? = nil) -> CGPoint {
        let iconS: CGFloat = 56, gap: CGFloat = 10, pad: CGFloat = 14
        let dockW = CGFloat(icons) * (iconS + gap) - gap + pad * 2
        let dockH = iconS + pad * 2 - 6
        let dr = CGRect(x: (size.width - dockW) / 2, y: 10, width: dockW, height: dockH)
        ctx.saveGState()
        roundRectPath(ctx, dr, 22)
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.22)); ctx.fillPath()
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.3)); ctx.setLineWidth(0.5)
        roundRectPath(ctx, dr, 22); ctx.strokePath()
        var target = CGPoint.zero
        for i in 0..<icons {
            let x = dr.minX + pad + CGFloat(i) * (iconS + gap)
            let r = CGRect(x: x, y: dr.minY + 8, width: iconS, height: iconS)
            let hue = CGFloat(i) * 0.09 + 0.55
            ctx.setFillColor(CGColor(red: CGFloat((sin(hue*6)+1)/2*0.5+0.3),
                                     green: CGFloat((sin(hue*6+2)+1)/2*0.5+0.3),
                                     blue: CGFloat((sin(hue*6+4)+1)/2*0.5+0.35), alpha: 1))
            roundRectPath(ctx, r, 13); ctx.fillPath()
            if i == highlight {
                ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.9)); ctx.setLineWidth(2)
                roundRectPath(ctx, r.insetBy(dx: -5, dy: -5), 17); ctx.strokePath()
                // running dot
                ctx.setFillColor(CGColor(gray: 1, alpha: 1))
                ctx.fillEllipse(in: CGRect(x: r.midX - 2.5, y: dr.minY - 6, width: 5, height: 5))
                target = CGPoint(x: r.midX, y: r.midY)
            }
        }
        ctx.restoreGState()
        return target
    }
}
