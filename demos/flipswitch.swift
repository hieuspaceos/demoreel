import Cocoa
// flipswitch demo — menubar click -> Control-Center tile panel ->
// flips Keep Awake, Dark Mode, Hide Dock with visible effects.

let W: CGFloat = 1920, H: CGFloat = 1080
let panelW: CGFloat = 300, panelH: CGFloat = 470
let panel = CGRect(x: W - panelW - 140, y: H - 24 - 12 - panelH,
                   width: panelW, height: panelH)

struct T { let icon: String; let name: String; let tint: CGColor }
let tiles: [T] = [
    T(icon: "desktopcomputer", name: "Desktop", tint: CGColor(red:0.55,green:0.45,blue:0.90,alpha:1)),
    T(icon: "eye", name: "Hidden Files", tint: CGColor(red:0.65,green:0.45,blue:0.95,alpha:1)),
    T(icon: "moon.fill", name: "Dark Mode", tint: CGColor(red:0.30,green:0.55,blue:1.00,alpha:1)),
    T(icon: "rectangle.3.group", name: "Stage Mgr", tint: CGColor(red:0.30,green:0.75,blue:0.60,alpha:1)),
    T(icon: "dock.rectangle", name: "Hide Dock", tint: CGColor(gray:0.55,alpha:1)),
    T(icon: "mic.slash.fill", name: "Mute Mic", tint: CGColor(red:0.95,green:0.60,blue:0.25,alpha:1)),
    T(icon: "speaker.slash.fill", name: "Mute Spk", tint: CGColor(red:0.90,green:0.30,blue:0.30,alpha:1)),
    T(icon: "wifi", name: "Wi-Fi", tint: CGColor(red:0.25,green:0.70,blue:0.70,alpha:1)),
    T(icon: "cup.and.saucer.fill", name: "Keep Awake", tint: CGColor(red:0.70,green:0.50,blue:0.35,alpha:1)),
    T(icon: "battery.25", name: "Low Power", tint: CGColor(red:0.35,green:0.75,blue:0.45,alpha:1)),
    T(icon: "doc.on.clipboard", name: "Clear Clip", tint: CGColor(gray:0.55,alpha:1)),
    T(icon: "trash", name: "Empty Trash", tint: CGColor(red:0.90,green:0.30,blue:0.30,alpha:1)),
    T(icon: "lock.fill", name: "Lock", tint: CGColor(gray:0.50,alpha:1)),
    T(icon: "powersleep", name: "Sleep", tint: CGColor(red:0.25,green:0.70,blue:0.70,alpha:1)),
]

// SFSymbol-ish glyphs drawn as text (DemoReel.drawText handles unicode poorly
// for private-use area; use names as the tile icon placeholder + dot).
func tileIcon(_ ctx: CGContext, at c: CGPoint, t: T, on: Bool, hovered: Bool) {
    let r = CGRect(x: c.x - 23, y: c.y - 23, width: 36, height: 36)
    ctx.saveGState()
    if hovered { ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: 1.05, y: 1.05); ctx.translateBy(x: -c.x, y: -c.y) }
    ctx.setFillColor(on ? t.tint : CGColor(gray: 1, alpha: 0.10))
    ctx.fillEllipse(in: r)
    // icon dot
    ctx.setFillColor(on ? CGColor(gray: 1, alpha: 1) : CGColor(gray: 0.7, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8))
    ctx.restoreGState()
}

/// draw the popover panel; `on` = set of lit indices, `hover` = hovered index
func panelView(_ ctx: CGContext, on: Set<Int>, hover: Int, t: CGFloat) {
    guard t > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(t)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 30,
                  color: CGColor(gray: 0, alpha: 0.4))
    DemoReel.roundRectPath(ctx, panel, 14)
    ctx.setFillColor(CGColor(gray: 0.12, alpha: 0.96)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, panel, 14); ctx.clip()
    // header
    DemoReel.drawText(ctx, "flipswitch", at: CGPoint(x: panel.minX + 16, y: panel.maxY - 34),
                      size: 14, color: CGColor(gray: 0.95, alpha: 1))
    DemoReel.roundRectPath(ctx, CGRect(x: panel.maxX - 128, y: panel.maxY - 42,
                                       width: 112, height: 26), 7)
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.08)); ctx.fillPath()
    DemoReel.drawText(ctx, "Search", at: CGPoint(x: panel.maxX - 118, y: panel.maxY - 36),
                      size: 11, color: CGColor(gray: 0.5, alpha: 1))
    // tiles: 2 cols x 7 rows
    let cellW: CGFloat = 130, cellH: CGFloat = 58
    for (i, tile) in tiles.enumerated() {
        let col = i % 2, row = i / 2
        let cx = panel.minX + 14 + CGFloat(col) * (cellW + 10) + cellW/2
        let cy = panel.maxY - 56 - CGFloat(row) * cellH - cellH/2
        let isOn = on.contains(i), hov = i == hover
        let rr = CGRect(x: cx - cellW/2, y: cy - cellH/2 + 4, width: cellW, height: cellH - 8)
        if isOn || hov {
            DemoReel.roundRectPath(ctx, rr, 10)
            ctx.setFillColor(isOn ? tile.tint.copy(alpha: 0.18)! : CGColor(gray: 1, alpha: 0.06))
            ctx.fillPath()
        }
        tileIcon(ctx, at: CGPoint(x: cx - 30, y: cy), t: tile, on: isOn, hovered: hov)
        DemoReel.drawText(ctx, tile.name, at: CGPoint(x: cx - 12, y: cy - 6),
                          size: 11, color: isOn ? CGColor(gray: 0.95, alpha: 1)
                                                : CGColor(gray: 0.6, alpha: 1))
    }
    // footer
    DemoReel.drawText(ctx, "15 switches", at: CGPoint(x: panel.minX + 16, y: panel.minY + 12),
                      size: 10, color: CGColor(gray: 0.45, alpha: 1))
    DemoReel.drawText(ctx, "Quit", at: CGPoint(x: panel.maxX - 44, y: panel.minY + 12),
                      size: 10, color: CGColor(gray: 0.6, alpha: 1))
    ctx.restoreGState()
}

func docWindow(_ ctx: CGContext, dark: Bool) {
    let r = CGRect(x: 420, y: 200, width: 820, height: 560)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 36,
                  color: CGColor(gray: 0, alpha: 0.45))
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setFillColor(dark ? CGColor(gray: 0.12, alpha: 1) : CGColor(gray: 0.95, alpha: 1))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, r, 10); ctx.clip()
    ctx.setFillColor(dark ? CGColor(gray: 0.18, alpha: 1) : CGColor(gray: 0.88, alpha: 1))
    ctx.fill(CGRect(x: r.minX, y: r.maxY - 38, width: r.width, height: 38))
    for (i,c) in [CGColor(red:1,green:0.37,blue:0.34,alpha:1),
                  CGColor(red:1,green:0.74,blue:0.18,alpha:1),
                  CGColor(red:0.16,green:0.78,blue:0.25,alpha:1)].enumerated() {
        ctx.setFillColor(c)
        ctx.fillEllipse(in: CGRect(x: r.minX + 12 + CGFloat(i)*20, y: r.maxY - 25, width: 12, height: 12))
    }
    let fg = dark ? CGColor(gray: 0.85, alpha: 1) : CGColor(gray: 0.15, alpha: 1)
    var y = r.maxY - 90
    for line in ["Quarterly plan draft", "", "• Ship the toggle suite", "• Launch on Product Hunt"] {
        DemoReel.drawText(ctx, line, at: CGPoint(x: r.minX + 30, y: y), size: 16, color: fg)
        y -= 30
    }
    ctx.restoreGState()
}

func fakeDock(_ ctx: CGContext, hidden: Bool, t: CGFloat) {
    if hidden {
        ctx.saveGState(); ctx.setAlpha(1 - t)
        ctx.translateBy(x: 0, y: -80 * t)
    }
    let w: CGFloat = 640, h: CGFloat = 64
    let r = CGRect(x: (W - w)/2, y: 12, width: w, height: h)
    DemoReel.roundRectPath(ctx, r, 18)
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.22)); ctx.fillPath()
    for i in 0..<9 {
        let x = r.minX + 20 + CGFloat(i) * 66
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.35))
        DemoReel.roundRectPath(ctx, CGRect(x: x, y: r.minY + 10, width: 44, height: 44), 10)
        ctx.fillPath()
    }
    if hidden { ctx.restoreGState() }
}

let demo = Demo(scenes: [
    // 0-110: desktop + dock visible, menubar icon flashes on hover
    Scene(0...110, caption: "flipswitch — system toggles in the menubar") { ctx, t, f in
        docWindow(ctx, dark: true)
        fakeDock(ctx, hidden: false, t: 0)
    },
    // 111-260: panel opens, cursor hovers Keep Awake, flips it ON
    Scene(111...260, caption: "One click — every switch") { ctx, t, f in
        docWindow(ctx, dark: true)
        fakeDock(ctx, hidden: false, t: 0)
        let pop = Ease.out(min(1, CGFloat(f - 118) / 16))
        var on: Set<Int> = []
        if f >= 200 { on.insert(8) }           // Keep Awake ON
        let hov = f >= 160 && f < 210 ? 8 : -1
        panelView(ctx, on: on, hover: hov, t: pop)
        // cursor: menubar -> tile
        if f < 160 {
            DemoReel.cursor(ctx, at: CGPoint(x: W - 150 - CGFloat(f - 110) * 3,
                                             y: H - 40 - CGFloat(f - 110) * 6), clicking: false)
        } else if f < 210 {
            DemoReel.cursor(ctx, at: CGPoint(x: panel.midX - 70, y: panel.maxY - 330),
                            clicking: f >= 195 && f < 205)
        }
    },
    // 261-400: Dark Mode tile -> doc turns light; Dock tile -> dock slides away
    Scene(261...400, caption: "Dark Mode, Hide Dock — real system effects") { ctx, t, f in
        let darkOn = f < 330
        let dockHide = min(1, max(0, CGFloat(f - 345) / 20))
        docWindow(ctx, dark: darkOn)
        fakeDock(ctx, hidden: f >= 330, t: dockHide)
        var on: Set<Int> = [8]
        if f >= 330 { on.insert(4) }           // Hide Dock ON
        panelView(ctx, on: on, hover: f >= 300 && f < 330 ? 2 : (f >= 330 ? 4 : -1), t: 1)
        if f < 330 {
            DemoReel.cursor(ctx, at: CGPoint(x: panel.minX + 70, y: panel.maxY - 220),
                            clicking: f >= 315 && f < 325)
        } else {
            DemoReel.cursor(ctx, at: CGPoint(x: panel.midX + 60, y: panel.maxY - 330),
                            clicking: f >= 340 && f < 352)
        }
    },
    // 401-560: cleanup actions — clear clipboard + empty trash flash
    Scene(401...560, caption: "Cleanup actions too") { ctx, t, f in
        docWindow(ctx, dark: false)
        fakeDock(ctx, hidden: true, t: 1)
        var on: Set<Int> = [8, 4]
        if f >= 470 && f < 500 { on.insert(10) } // Clear Clipboard flash
        if f >= 510 && f < 545 { on.insert(11) } // Empty Trash flash
        panelView(ctx, on: on,
                  hover: f >= 460 && f < 500 ? 10 : (f >= 505 && f < 545 ? 11 : -1), t: 1)
        DemoReel.cursor(ctx, at: CGPoint(x: panel.minX + 70,
                                         y: f < 500 ? panel.maxY - 470 : panel.maxY - 526),
                        clicking: (f >= 465 && f < 475) || (f >= 505 && f < 515))
    },
    // 561-700: outro
    Scene(561...700, caption: "flipswitch — free, native, 15 toggles") { ctx, t, f in
        docWindow(ctx, dark: false)
        fakeDock(ctx, hidden: true, t: 1)
        let fade = min(1, max(0, CGFloat(f - 570) / 20))
        panelView(ctx, on: [8, 4], hover: -1, t: 1 - fade)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.4 * min(1, t * 1.2)))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let tt = min(1, max(0, t * 1.4))
        DemoReel.drawText(ctx, "flipswitch",
                          at: CGPoint(x: W/2 - DemoReel.textWidth("flipswitch", size: 64)/2,
                                      y: H/2 + 10),
                          size: 64, color: CGColor(gray: 1, alpha: tt))
        DemoReel.drawText(ctx, "free · native · no subscription",
                          at: CGPoint(x: W/2 - DemoReel.textWidth("free · native · no subscription", size: 24)/2,
                                      y: H/2 - 60),
                          size: 24, color: CGColor(gray: 1, alpha: 0.7 * tt))
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/fs-frames")
