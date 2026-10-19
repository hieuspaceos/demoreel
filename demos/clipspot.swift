import Cocoa
// ClipSpot demo — ~24s sweep: hotkey -> palette -> filter -> quick-paste ->
// pin -> plain-text -> dismiss -> menubar -> settings.

let W: CGFloat = 1920, H: CGFloat = 1080
let palW: CGFloat = 720, palH: CGFloat = 460
let pal = CGRect(x: (W - palW)/2, y: (H - palH)/2 - 40, width: palW, height: palH)

struct Row { let title: String; let app: String; let badge: String; let tint: CGColor }
let rows: [Row] = [
    Row(title: "D355FEF6…png",            app: "Finder",  badge: "IMAGE", tint: CGColor(red:0.30,green:0.75,blue:0.40,alpha:1)),
    Row(title: "sameContent() compares",  app: "Xcode",   badge: "TEXT",  tint: CGColor(red:0.35,green:0.55,blue:1.00,alpha:1)),
    Row(title: "github.com/hieuspaceos/clipspot", app: "Safari", badge: "LINK", tint: CGColor(red:0.55,green:0.45,blue:1.00,alpha:1)),
    Row(title: "report.pdf",              app: "Finder",  badge: "FILE",  tint: CGColor(red:1.00,green:0.62,blue:0.25,alpha:1)),
    Row(title: "Quarterly plan draft…",   app: "Notes",   badge: "TEXT",  tint: CGColor(red:0.35,green:0.55,blue:1.00,alpha:1)),
    Row(title: "meme.jpg",                app: "Finder",  badge: "IMAGE", tint: CGColor(red:0.30,green:0.75,blue:0.40,alpha:1)),
]

func hotkeyHint(_ ctx: CGContext, _ keys: String, at p: CGPoint, t: CGFloat) {
    guard t > 0 else { return }
    let w = DemoReel.textWidth(keys, size: 20) + 28
    let r = CGRect(x: p.x - w/2, y: p.y - 22, width: w, height: 44)
    ctx.saveGState(); ctx.setAlpha(t)
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 16,
                  color: CGColor(gray: 0, alpha: 0.4))
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setFillColor(CGColor(gray: 0.10, alpha: 0.96)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.25)); ctx.setLineWidth(1); ctx.strokePath()
    DemoReel.drawText(ctx, keys, at: CGPoint(x: r.minX + 14, y: r.minY + 12),
                      size: 20, color: CGColor(gray: 1, alpha: 1))
    ctx.restoreGState()
}

/// sel: row index, -1 none. pins: set of pinned row indices (shown with pin mark).
/// query: search text. t: pop-in progress.
func palette(_ ctx: CGContext, sel: Int, query: String, t: CGFloat,
             pins: Set<Int> = [], visibleRows: [Int]? = nil) {
    guard t > 0 else { return }
    ctx.saveGState()
    let s = 0.96 + 0.04 * Ease.out(t)
    ctx.translateBy(x: pal.midX, y: pal.midY); ctx.scaleBy(x: s, y: s)
    ctx.translateBy(x: -pal.midX, y: -pal.midY)
    ctx.setAlpha(t)
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 50,
                  color: CGColor(gray: 0, alpha: 0.55))
    DemoReel.roundRectPath(ctx, pal, 16)
    ctx.setFillColor(CGColor(gray: 0.11, alpha: 0.97)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, pal, 16); ctx.clip()

    // search bar
    DemoReel.roundRectPath(ctx, CGRect(x: pal.minX + 14, y: pal.maxY - 52,
                                       width: pal.width - 28, height: 38), 9)
    ctx.setFillColor(CGColor(gray: 0.17, alpha: 1)); ctx.fillPath()
    let ph = query.isEmpty ? "Search clipboard…" : query
    DemoReel.drawText(ctx, ph, at: CGPoint(x: pal.minX + 26, y: pal.maxY - 39),
                      size: 15,
                      color: query.isEmpty ? CGColor(gray: 0.5, alpha: 1)
                                           : CGColor(gray: 1, alpha: 1))
    if !query.isEmpty {
        let tw = DemoReel.textWidth(query, size: 15)
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.8))
        ctx.fill(CGRect(x: pal.minX + 26 + tw + 2, y: pal.maxY - 42, width: 2, height: 20))
    }

    let listW: CGFloat = 330
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.06))
    ctx.fill(CGRect(x: pal.minX + listW, y: pal.minY, width: 1, height: pal.height - 70))

    let vis = visibleRows ?? Array(rows.indices)
    let rowH: CGFloat = 54
    for (ri, idx) in vis.enumerated() {
        let r = rows[idx]
        let ry = pal.maxY - 58 - CGFloat(ri + 1) * rowH
        if ry < pal.minY + 30 { break }
        if idx == sel {
            DemoReel.roundRectPath(ctx, CGRect(x: pal.minX + 8, y: ry + 4,
                                               width: listW - 16, height: rowH - 8), 8)
            ctx.setFillColor(CGColor(red: 0.25, green: 0.5, blue: 1, alpha: 0.30))
            ctx.fillPath()
        }
        ctx.setFillColor(r.tint)
        ctx.fillEllipse(in: CGRect(x: pal.minX + 20, y: ry + rowH/2 - 8, width: 16, height: 16))
        DemoReel.drawText(ctx, r.title,
                          at: CGPoint(x: pal.minX + 46, y: ry + rowH/2 + 3),
                          size: 13, color: CGColor(gray: 0.95, alpha: 1))
        DemoReel.drawText(ctx, r.app,
                          at: CGPoint(x: pal.minX + 46, y: ry + rowH/2 - 15),
                          size: 10, color: CGColor(gray: 0.55, alpha: 1))
        if pins.contains(idx) {
            DemoReel.drawText(ctx, "📌", at: CGPoint(x: pal.minX + listW - 88,
                                                    y: ry + rowH/2 - 6),
                              size: 11, color: CGColor(gray: 0.7, alpha: 1))
        }
        let bw = DemoReel.textWidth(r.badge, size: 9) + 10
        DemoReel.roundRectPath(ctx, CGRect(x: pal.minX + listW - 20 - bw,
                                           y: ry + rowH/2 - 9, width: bw, height: 18), 4)
        ctx.setFillColor(r.tint.copy(alpha: 0.25)!); ctx.fillPath()
        DemoReel.drawText(ctx, r.badge,
                          at: CGPoint(x: pal.minX + listW - 15 - bw, y: ry + rowH/2 - 5),
                          size: 9, color: r.tint)
    }

    // preview pane for selected row
    if sel >= 0, sel < rows.count {
        let px = pal.minX + listW + 24
        DemoReel.drawText(ctx, rows[sel].badge,
                          at: CGPoint(x: px, y: pal.maxY - 92),
                          size: 11, color: rows[sel].tint)
        if rows[sel].badge == "IMAGE" {
            let imgR = CGRect(x: px, y: pal.minY + 60,
                              width: pal.width - listW - 48, height: pal.height - 190)
            ctx.saveGState()
            DemoReel.roundRectPath(ctx, imgR, 8); ctx.clip()
            ctx.setFillColor(CGColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1))
            ctx.fill(imgR)
            ctx.setFillColor(CGColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: px + 60, y: pal.minY + 200, width: 50, height: 50))
            ctx.setFillColor(CGColor(red: 0.3, green: 0.65, blue: 0.4, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: px - 40, y: pal.minY + 40, width: 300, height: 140))
            ctx.restoreGState()
        } else {
            DemoReel.drawText(ctx, String(rows[sel].title.prefix(40)),
                              at: CGPoint(x: px, y: pal.maxY - 140),
                              size: 14, color: CGColor(gray: 0.9, alpha: 1))
        }
        DemoReel.drawText(ctx, "from " + rows[sel].app,
                          at: CGPoint(x: px, y: pal.minY + 40),
                          size: 11, color: CGColor(gray: 0.5, alpha: 1))
    }

    let hints = ["⏎ paste", "⌘1-9 quick", "📌 pin", "⌫ delete", "esc close"]
    var hx = pal.minX + 18
    for h in hints {
        DemoReel.drawText(ctx, h, at: CGPoint(x: hx, y: pal.minY + 12),
                          size: 10, color: CGColor(gray: 0.45, alpha: 1))
        hx += DemoReel.textWidth(h, size: 10) + 20
    }
    ctx.restoreGState()
}

let docR = CGRect(x: 560, y: 250, width: 800, height: 560)
func docWindow(_ ctx: CGContext, text: String) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 36,
                  color: CGColor(gray: 0, alpha: 0.45))
    DemoReel.roundRectPath(ctx, docR, 10)
    ctx.setFillColor(CGColor(gray: 0.95, alpha: 1)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, docR, 10); ctx.clip()
    ctx.setFillColor(CGColor(gray: 0.88, alpha: 1))
    ctx.fill(CGRect(x: docR.minX, y: docR.maxY - 38, width: docR.width, height: 38))
    for (i,c) in [CGColor(red:1,green:0.37,blue:0.34,alpha:1),
                  CGColor(red:1,green:0.74,blue:0.18,alpha:1),
                  CGColor(red:0.16,green:0.78,blue:0.25,alpha:1)].enumerated() {
        ctx.setFillColor(c)
        ctx.fillEllipse(in: CGRect(x: docR.minX + 12 + CGFloat(i)*20,
                                   y: docR.maxY - 25, width: 12, height: 12))
    }
    DemoReel.drawText(ctx, "meeting-notes.txt",
                      at: CGPoint(x: docR.midX - 60, y: docR.maxY - 24),
                      size: 13, color: CGColor(gray: 0.3, alpha: 1))
    var y = docR.maxY - 80
    for line in ["Standup @ 9:30", "", text] {
        DemoReel.drawText(ctx, line, at: CGPoint(x: docR.minX + 30, y: y),
                          size: 16, color: CGColor(gray: 0.15, alpha: 1))
        y -= 30
    }
    ctx.restoreGState()
}

// menubar dropdown panel (for the menubar scene)
func menubarMenu(_ ctx: CGContext, t: CGFloat) {
    guard t > 0 else { return }
    let w: CGFloat = 260, itemH: CGFloat = 30
    let items = ["Show ClipSpot        ⌘⇧V", "—", "Clear History (keep pinned)", "—",
                 "Settings…              ⌘,", "—", "Donate ♥", "—", "Quit ClipSpot      ⌘Q"]
    let h = CGFloat(items.count) * itemH + 12
    let r = CGRect(x: W - w - 60, y: H - 30 - h, width: w, height: h)
    ctx.saveGState(); ctx.setAlpha(t)
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 24,
                  color: CGColor(gray: 0, alpha: 0.4))
    DemoReel.roundRectPath(ctx, r, 8)
    ctx.setFillColor(CGColor(gray: 0.16, alpha: 0.97)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    var iy = r.maxY - itemH - 4
    for it in items {
        if it == "—" {
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.1))
            ctx.fill(CGRect(x: r.minX + 10, y: iy + itemH/2, width: w - 20, height: 1))
        } else {
            DemoReel.drawText(ctx, it, at: CGPoint(x: r.minX + 16, y: iy + 8),
                              size: 13, color: CGColor(gray: 0.92, alpha: 1))
        }
        iy -= itemH
    }
    ctx.restoreGState()
}

let demo = Demo(scenes: [
    // 0-110  user typing in doc; hotkey badge teases
    Scene(0...110, caption: "ClipSpot — your clipboard, one hotkey away") { ctx, t, f in
        docWindow(ctx, text: "")
        hotkeyHint(ctx, "⌘⇧V", at: CGPoint(x: W/2, y: H - 130),
                   t: min(1, max(0, (CGFloat(f) - 25) / 20)))
    },
    // 111-240  palette pops, selection moves down through rows
    Scene(111...240, caption: "⌘⇧V — the palette appears") { ctx, t, f in
        docWindow(ctx, text: "")
        let pop = Ease.out(min(1, CGFloat(f - 118) / 18))
        var sel = 0
        if f >= 170 { sel = 1 }; if f >= 195 { sel = 2 }; if f >= 220 { sel = 3 }
        palette(ctx, sel: sel, query: "", t: pop)
    },
    // 241-360  typing "repo" filters to one row
    Scene(241...360, caption: "Type to filter") { ctx, t, f in
        docWindow(ctx, text: "")
        var q = ""
        if f >= 265 { q = String("repo".prefix(min(4, (f - 265) / 7))) }
        let vis: [Int]? = q.count >= 2 ? [3] : nil
        palette(ctx, sel: q.count >= 2 ? 3 : 0, query: q, t: 1, visibleRows: vis)
    },
    // 361-470  Enter pastes file into the doc
    Scene(361...470, caption: "⏎ — pasted where you were") { ctx, t, f in
        let fade = min(1, max(0, CGFloat(f - 378) / 14))
        docWindow(ctx, text: fade >= 1 ? "report.pdf" : "")
        palette(ctx, sel: 3, query: "repo", t: 1 - fade, visibleRows: [3])
    },
    // 471-600  palette again — pin an item (pin glyph appears)
    Scene(471...600, caption: "Pin what you reuse") { ctx, t, f in
        docWindow(ctx, text: "report.pdf")
        let pop = Ease.out(min(1, CGFloat(f - 478) / 16))
        let pinned: Set<Int> = f >= 540 ? [1] : []
        palette(ctx, sel: 1, query: "", t: pop, pins: pinned)
        hotkeyHint(ctx, "📌", at: CGPoint(x: pal.minX + 300, y: pal.maxY - 190),
                   t: f >= 530 && f < 545 ? 1 : 0)
    },
    // 601-720  plain-text paste variant
    Scene(601...720, caption: "Or paste as plain text") { ctx, t, f in
        docWindow(ctx, text: "report.pdf")
        let pop = Ease.out(min(1, CGFloat(f - 608) / 16))
        palette(ctx, sel: 2, query: "", t: pop)
        hotkeyHint(ctx, "⌥⏎ plain", at: CGPoint(x: pal.maxX - 120, y: pal.minY + 80),
                   t: f >= 650 ? 1 : 0)
    },
    // 721-840  menubar menu — Clear / Settings / Donate / Quit
    Scene(721...840, caption: "Menubar: settings, clear, donate") { ctx, t, f in
        docWindow(ctx, text: "report.pdf")
        menubarMenu(ctx, t: min(1, max(0, CGFloat(f - 728) / 16)))
        DemoReel.cursor(ctx, at: CGPoint(x: W - 80, y: H - 28), clicking: f > 730 && f < 745)
    },
    // 841-960  outro — palette fades, doc stays
    Scene(841...960, caption: "ClipSpot — free, native, yours") { ctx, t, f in
        docWindow(ctx, text: "report.pdf")
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.35 * min(1, t)))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let tt = min(1, max(0, t * 1.4))
        DemoReel.drawText(ctx, "ClipSpot",
                          at: CGPoint(x: W/2 - DemoReel.textWidth("ClipSpot", size: 64)/2,
                                      y: H/2 + 10),
                          size: 64, color: CGColor(gray: 1, alpha: tt))
        DemoReel.drawText(ctx, "free · open source · native",
                          at: CGPoint(x: W/2 - DemoReel.textWidth("free · open source · native", size: 24)/2,
                                      y: H/2 - 60),
                          size: 24, color: CGColor(gray: 1, alpha: 0.7 * tt))
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/cs-frames")
