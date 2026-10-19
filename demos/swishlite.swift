import Cocoa
// SwishLite demo — a window slides to "Left Half" with bezel, via cursor
// mimicking a two-finger title-bar swipe. Zoom lens magnifies the gesture.

let W: CGFloat = 1920, H: CGFloat = 1080
let win0 = CGRect(x: 620, y: 340, width: 700, height: 460)    // floating window
let winL = CGRect(x: 60,  y: 120, width: 880, height: 860)    // snapped left half
let bezel = CGRect(x: W/2 - 130, y: H/2 - 60, width: 260, height: 120)

func drawWindow(_ ctx: CGContext, _ r: CGRect, title: String) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 36,
                  color: CGColor(gray: 0, alpha: 0.5))
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setFillColor(CGColor(gray: 0.13, alpha: 1))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, r, 10); ctx.clip()
    // titlebar
    ctx.setFillColor(CGColor(gray: 0.19, alpha: 1))
    ctx.fill(CGRect(x: r.minX, y: r.maxY - 38, width: r.width, height: 38))
    for (i,c) in [CGColor(red:1,green:0.37,blue:0.34,alpha:1),
                  CGColor(red:1,green:0.74,blue:0.18,alpha:1),
                  CGColor(red:0.16,green:0.78,blue:0.25,alpha:1)].enumerated() {
        ctx.setFillColor(c)
        ctx.fillEllipse(in: CGRect(x: r.minX + 12 + CGFloat(i)*20, y: r.maxY - 25,
                                   width: 12, height: 12))
    }
    DemoReel.drawText(ctx, title, at: CGPoint(x: r.midX - DemoReel.textWidth(title, size: 13)/2,
                                              y: r.maxY - 24),
                      size: 13, color: CGColor(gray: 0.65, alpha: 1))
    // fake content
    ctx.setFillColor(CGColor(gray: 0.11, alpha: 1))
    ctx.fill(CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - 38))
    ctx.setFillColor(CGColor(gray: 0.22, alpha: 1))
    for i in 0..<5 {
        DemoReel.roundRectPath(ctx, CGRect(x: r.minX + 24,
                                           y: r.maxY - 90 - CGFloat(i) * 56,
                                           width: r.width - 48, height: 34), 6)
        ctx.fillPath()
    }
    ctx.restoreGState()
}

func bezelUI(_ ctx: CGContext, t: CGFloat, label: String) {
    guard t > 0 else { return }
    ctx.saveGState()
    ctx.setAlpha(min(1, t * 1.4))
    DemoReel.roundRectPath(ctx, bezel, 18)
    ctx.setFillColor(CGColor(gray: 0.12, alpha: 0.92))
    ctx.fillPath()
    // chevron-left icon
    let cx = bezel.midX, cy = bezel.midY + 14
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 1)); ctx.setLineWidth(8); ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: cx + 14, y: cy + 18))
    ctx.addLine(to: CGPoint(x: cx - 14, y: cy))
    ctx.addLine(to: CGPoint(x: cx + 14, y: cy - 18))
    ctx.strokePath()
    DemoReel.drawText(ctx, label,
        at: CGPoint(x: bezel.midX - DemoReel.textWidth(label, size: 17)/2,
                    y: bezel.minY + 16),
        size: 17, color: CGColor(gray: 0.9, alpha: 1))
    ctx.restoreGState()
}

// scene content reusable for zoom lens
func sceneContent(_ ctx: CGContext, f: Int) {
    // swipe progress 0-1 over frames 130-200
    let sp = Ease.inOut(min(1, max(0, CGFloat(f - 130) / 70)))
    let r = CGRect(x: win0.minX + (winL.minX - win0.minX) * sp,
                   y: win0.minY + (winL.minY - win0.minY) * sp,
                   width: win0.width + (winL.width - win0.width) * sp,
                   height: win0.height + (winL.height - win0.height) * sp)
    drawWindow(ctx, r, title: "Notes — meeting.md")
    // two-finger hint dots on the titlebar while swiping
    if f < 200 {
        let tx = r.minX + r.width/2 - CGFloat(f - 120) * 0.6
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.9))
        ctx.fillEllipse(in: CGRect(x: tx - 14, y: r.maxY - 26, width: 10, height: 10))
        ctx.fillEllipse(in: CGRect(x: tx + 6,  y: r.maxY - 26, width: 10, height: 10))
    }
}

let demo = Demo(scenes: [
    Scene(0...110, caption: "SwishLite — snap windows with trackpad swipes") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.15 * t))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        drawWindow(ctx, win0, title: "Notes — meeting.md")
    },
    Scene(111...240, caption: "Two-finger swipe on the title bar") { ctx, t, f in
        sceneContent(ctx, f: f)
        // zoom lens on the title bar while fingers shown
        if f >= 140 && f < 215 {
            let zt = min(1, CGFloat(f - 140) / 20) * min(1, CGFloat(215 - f) / 15)
            let title = CGPoint(x: win0.midX - 40, y: win0.maxY - 19)
            DemoReel.zoomed(ctx,
                lens: CGRect(x: 420, y: 620, width: 560, height: 300),
                center: title, factor: 1.9, t: zt) { zctx in
                    zctx.draw(DemoReel.desktopImage(size: CGSize(width: W, height: H))!,
                              in: CGRect(x: 0, y: 0, width: W, height: H))
                    sceneContent(zctx, f: f)
                }
        }
        // bezel pops once snap lands
        if f >= 195 { bezelUI(ctx, t: min(1, CGFloat(f - 195) / 15), label: "Left Half") }
    },
    Scene(241...360, caption: "Snapped. Haptic + bezel feedback.") { ctx, t, f in
        sceneContent(ctx, f: 200)   // frozen snapped state
        bezelUI(ctx, t: 1 - min(1, CGFloat(f - 300) / 20), label: "Left Half")
    },
    Scene(361...480, caption: "Thirds, quarters, maximize, minimize — all gestures") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.45 * min(1, t * 2)))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        // zone chips appearing
        let chips = ["◧ Left","◨ Right","◱ Thirds","◰ Quarters","⛶ Maximize","⤓ Minimize"]
        for (i, c) in chips.enumerated() {
            let tt = min(1, max(0, t * 2.2 - CGFloat(i) * 0.18))
            let ch = chips.count, gap: CGFloat = 26
            let w: CGFloat = 230, h: CGFloat = 70
            let total = CGFloat(ch) * (w + gap) - gap
            let x = (W - total) / 2 + CGFloat(i) * (w + gap)
            let y = H/2 - h/2 - (1 - tt) * 30
            ctx.saveGState(); ctx.setAlpha(tt)
            DemoReel.roundRectPath(ctx, CGRect(x: x, y: y, width: w, height: h), 14)
            ctx.setFillColor(CGColor(gray: 0.13, alpha: 0.95)); ctx.fillPath()
            DemoReel.drawText(ctx, c, at: CGPoint(x: x + w/2 - DemoReel.textWidth(c, size: 20)/2,
                                                  y: y + h/2 - 9), size: 20,
                              color: CGColor(gray: 1, alpha: 1))
            ctx.restoreGState()
        }
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/sl-frames")
