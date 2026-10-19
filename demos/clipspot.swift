import Cocoa
// ClipSpot demo — Spotlight-style clipboard palette:
// hotkey pops it, typing filters the list, Enter pastes back to the app.

let W: CGFloat = 1920, H: CGFloat = 1080
let palW: CGFloat = 720, palH: CGFloat = 460
let pal = CGRect(x: (W - palW)/2, y: (H - palH)/2 - 40, width: palW, height: palH)

// rows shown in the list (icon dot, title, badge)
struct Row { let title: String; let app: String; let badge: String; let tint: CGColor }
let rows: [Row] = [
    Row(title: "D355FEF6…png",            app: "Finder",  badge: "IMAGE", tint: CGColor(red:0.30,green:0.75,blue:0.40,alpha:1)),
    Row(title: "sameContent() compares",  app: "Xcode",   badge: "TEXT",  tint: CGColor(red:0.35,green:0.55,blue:1.00,alpha:1)),
    Row(title: "https://github.com/hieuspaceos/clipspot", app: "Safari", badge: "LINK", tint: CGColor(red:0.55,green:0.45,blue:1.00,alpha:1)),
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

// palette: dark rounded panel; sel = selected row index (-1 none);
// query drives the search field text
func palette(_ ctx: CGContext, sel: Int, query: String, t: CGFloat,
             previewImage: Bool) {
    guard t > 0 else { return }
    ctx.saveGState()
    // scale-in from 0.96 like the real app
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
    // caret blink in the field
    if query.count > 0, (CFAbsoluteTimeGetCurrent() * 3).truncatingRemainder(dividingBy: 2) < 1 || true {
        let tw = DemoReel.textWidth(query, size: 15)
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.8))
        ctx.fill(CGRect(x: pal.minX + 26 + tw + 2, y: pal.maxY - 42, width: 2, height: 20))
    }

    // list (left) + preview (right) divider
    let listW: CGFloat = 330
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.06))
    ctx.fill(CGRect(x: pal.minX + listW, y: pal.minY, width: 1, height: pal.height - 70))

    let rowH: CGFloat = 54
    for (i, r) in rows.enumerated() {
        let ry = pal.maxY - 58 - CGFloat(i + 1) * rowH
        if ry < pal.minY + 30 { break }
        if i == sel {
            DemoReel.roundRectPath(ctx, CGRect(x: pal.minX + 8, y: ry + 4,
                                               width: listW - 16, height: rowH - 8), 8)
            ctx.setFillColor(CGColor(red: 0.25, green: 0.5, blue: 1, alpha: 0.30))
            ctx.fillPath()
        }
        // app icon dot
        ctx.setFillColor(r.tint)
        ctx.fillEllipse(in: CGRect(x: pal.minX + 20, y: ry + rowH/2 - 8, width: 16, height: 16))
        DemoReel.drawText(ctx, r.title,
                          at: CGPoint(x: pal.minX + 46, y: ry + rowH/2 + 3),
                          size: 13, color: CGColor(gray: 0.95, alpha: 1))
        DemoReel.drawText(ctx, r.app,
                          at: CGPoint(x: pal.minX + 46, y: ry + rowH/2 - 15),
                          size: 10, color: CGColor(gray: 0.55, alpha: 1))
        // type badge
        let bw = DemoReel.textWidth(r.badge, size: 9) + 10
        DemoReel.roundRectPath(ctx, CGRect(x: pal.minX + listW - 20 - bw,
                                           y: ry + rowH/2 - 9, width: bw, height: 18), 4)
        ctx.setFillColor(r.tint.copy(alpha: 0.25)!); ctx.fillPath()
        DemoReel.drawText(ctx, r.badge,
                          at: CGPoint(x: pal.minX + listW - 15 - bw, y: ry + rowH/2 - 5),
                          size: 9, color: r.tint)
    }

    // preview pane (right): for the selected row
    if sel >= 0, sel < rows.count {
        let px = pal.minX + listW + 24
        DemoReel.drawText(ctx, rows[sel].badge,
                          at: CGPoint(x: px, y: pal.maxY - 92),
                          size: 11, color: rows[sel].tint)
        if previewImage && rows[sel].badge == "IMAGE" {
            // fake image thumbnail
            DemoReel.roundRectPath(ctx, CGRect(x: px, y: pal.minY + 60,
                                               width: pal.width - listW - 48,
                                               height: pal.height - 190), 8)
            ctx.setFillColor(CGColor(gray: 0.20, alpha: 1)); ctx.fillPath()
            DemoReel.roundRectPath(ctx, CGRect(x: px, y: pal.minY + 60,
                                               width: pal.width - listW - 48,
                                               height: pal.height - 190), 8); ctx.clip()
            // mini landscape: sky + sun + hill
            ctx.setFillColor(CGColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1))
            ctx.fill(CGRect(x: px, y: pal.minY + 60, width: pal.width - listW - 48, height: pal.height - 190))
            ctx.setFillColor(CGColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: px + 60, y: pal.minY + 200, width: 50, height: 50))
            ctx.setFillColor(CGColor(red: 0.3, green: 0.65, blue: 0.4, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: px - 40, y: pal.minY + 40, width: 300, height: 140))
        } else {
            DemoReel.drawText(ctx, String(rows[sel].title.prefix(40)),
                              at: CGPoint(x: px, y: pal.maxY - 140),
                              size: 14, color: CGColor(gray: 0.9, alpha: 1))
        }
        // source app footer
        DemoReel.drawText(ctx, "from " + rows[sel].app,
                          at: CGPoint(x: px, y: pal.minY + 40),
                          size: 11, color: CGColor(gray: 0.5, alpha: 1))
    }

    // footer hints
    let hints = ["⏎ paste", "⌘1-9 quick", "⌫ delete", "esc close"]
    var hx = pal.minX + 18
    for h in hints {
        DemoReel.drawText(ctx, h, at: CGPoint(x: hx, y: pal.minY + 12),
                          size: 10, color: CGColor(gray: 0.45, alpha: 1))
        hx += DemoReel.textWidth(h, size: 10) + 22
    }
    ctx.restoreGState()
}

// fake TextEdit-ish window that receives the paste
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

let demo = Demo(scenes: [
    // 0-100: doc open, menubar dim — user copies something
    Scene(0...100, caption: "ClipSpot — your clipboard, one hotkey away") { ctx, t, f in
        docWindow(ctx, text: "")
        hotkeyHint(ctx, "⌘⇧V", at: CGPoint(x: W/2, y: H - 120),
                   t: min(1, max(0, (CGFloat(f) - 30) / 20)))
    },
    // 101-220: palette pops in
    Scene(101...220, caption: "⌘⇧V — the palette appears") { ctx, t, f in
        docWindow(ctx, text: "")
        palette(ctx, sel: 0, query: "", t: Ease.out(min(1, CGFloat(f - 108) / 18)),
                previewImage: true)
    },
    // 221-340: typing filters — "report" narrows the list to 1 row
    Scene(221...340, caption: "Type to filter") { ctx, t, f in
        docWindow(ctx, text: "")
        var q = ""
        if f >= 245 { q = String("report".prefix(min(6, (f - 245) / 6))) }
        palette(ctx, sel: q.count >= 3 ? 3 : 0, query: q, t: 1, previewImage: true)
    },
    // 341-440: Enter pastes into the doc; palette fades
    Scene(341...440, caption: "⏎ — pasted where you were") { ctx, t, f in
        let fade = min(1, max(0, CGFloat(f - 348) / 14))
        docWindow(ctx, text: fade >= 1 ? "report.pdf" : "")
        palette(ctx, sel: 3, query: "report", t: 1 - fade, previewImage: true)
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/cs-frames")
