import Cocoa
// SwiftShot demo — full feature sweep, faithful to the app:
//  region-select dimmed overlay, editor with annotation tools,
//  floating preview toast, save flow, menubar quick actions.

let W: CGFloat = 1920, H: CGFloat = 1080
let mTop: CGFloat = 24

// region the user drags on screen
let regionStart = CGPoint(x: 560, y: 700)   // CG y-up
let regionEnd   = CGPoint(x: 1420, y: 260)
let region = CGRect(x: regionStart.x, y: regionEnd.y,
                    width: regionEnd.x - regionStart.x,
                    height: regionStart.y - regionEnd.y)

// editor window geometry (fits the captured region scaled ~0.62)
let edW: CGFloat = 980, edH: CGFloat = 640
let edTitleH: CGFloat = 38, toolbarH: CGFloat = 52
let edRect = CGRect(x: (W - edW)/2, y: (H - edH)/2 - 20, width: edW, height: edH)
var canvas: CGRect { CGRect(x: edRect.minX + 40, y: edRect.minY + 30,
                            width: edW - 80, height: edH - edTitleH - toolbarH - 60) }

func dim(_ ctx: CGContext, alpha: CGFloat, except r: CGRect? = nil) {
    ctx.saveGState()
    ctx.setFillColor(CGColor(gray: 0, alpha: alpha))
    if let r { // dim everything EXCEPT the selection: 4 rects around the hole
        for rr in [CGRect(x: 0, y: r.maxY, width: W, height: H - r.maxY),
                   CGRect(x: 0, y: 0, width: W, height: r.minY),
                   CGRect(x: 0, y: r.minY, width: r.minX, height: r.height),
                   CGRect(x: r.maxX, y: r.minY, width: W - r.maxX, height: r.height)] {
            ctx.fill(rr)
        }
    } else {
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    }
    ctx.restoreGState()
}

func selectionUI(_ ctx: CGContext, _ r: CGRect) {
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.95)); ctx.setLineWidth(1.5)
    ctx.stroke(r)
    // size badge
    let s = "\(Int(r.width)) × \(Int(r.height))"
    let w = DemoReel.textWidth(s, size: 15) + 20
    let br = CGRect(x: r.midX - w/2, y: r.minY - 34, width: w, height: 26)
    DemoReel.roundRectPath(ctx, br, 6)
    ctx.setFillColor(CGColor(gray: 0.1, alpha: 0.9)); ctx.fillPath()
    DemoReel.drawText(ctx, s, at: CGPoint(x: br.minX + 10, y: br.minY + 6),
                      size: 15, color: CGColor(gray: 1, alpha: 1))
}

func editorWindow(_ ctx: CGContext, alpha: CGFloat) {
    ctx.saveGState(); ctx.setAlpha(alpha)
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 40,
                  color: CGColor(gray: 0, alpha: 0.6))
    DemoReel.roundRectPath(ctx, edRect, 10)
    ctx.setFillColor(CGColor(gray: 0.12, alpha: 1)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    DemoReel.roundRectPath(ctx, edRect, 10); ctx.clip()
    // titlebar
    ctx.setFillColor(CGColor(gray: 0.18, alpha: 1))
    ctx.fill(CGRect(x: edRect.minX, y: edRect.maxY - edTitleH, width: edW, height: edTitleH))
    for (i,c) in [CGColor(red:1,green:0.37,blue:0.34,alpha:1),
                  CGColor(red:1,green:0.74,blue:0.18,alpha:1),
                  CGColor(red:0.16,green:0.78,blue:0.25,alpha:1)].enumerated() {
        ctx.setFillColor(c)
        ctx.fillEllipse(in: CGRect(x: edRect.minX + 12 + CGFloat(i)*20, y: edRect.maxY - 25,
                                   width: 12, height: 12))
    }
    let t = "SwiftShot — Editor"
    DemoReel.drawText(ctx, t, at: CGPoint(x: edRect.midX - DemoReel.textWidth(t, size: 13)/2,
                                          y: edRect.maxY - 24), size: 13,
                      color: CGColor(gray: 0.7, alpha: 1))
    // toolbar: tool dots + color dots + Copy/Save buttons
    let ty = edRect.maxY - edTitleH - toolbarH
    ctx.setFillColor(CGColor(gray: 0.16, alpha: 1))
    ctx.fill(CGRect(x: edRect.minX, y: ty, width: edW, height: toolbarH))
    let tools = ["pen","arrow","rect","oval","hl","mosaic","txt"]
    for (i,_) in tools.enumerated() {
        let r = CGRect(x: edRect.minX + 16 + CGFloat(i)*44, y: ty + 12, width: 30, height: 28)
        DemoReel.roundRectPath(ctx, r, 6)
        ctx.setFillColor(CGColor(gray: 0.28, alpha: 1)); ctx.fillPath()
        DemoReel.drawText(ctx, tools[i],
            at: CGPoint(x: r.midX - DemoReel.textWidth(tools[i], size: 9)/2, y: r.midY - 4),
            size: 9, color: CGColor(gray: 1, alpha: 0.9))
    }
    for i in 0..<7 { // 7 preset colors
        let hue = CGFloat(i)/7
        ctx.setFillColor(CGColor(red: CGFloat((sin(hue*6.28)+1)/2*0.8+0.15),
                                 green: CGFloat((sin(hue*6.28+2.1)+1)/2*0.8+0.15),
                                 blue: CGFloat((sin(hue*6.28+4.2)+1)/2*0.8+0.15), alpha: 1))
        ctx.fillEllipse(in: CGRect(x: edRect.minX + 340 + CGFloat(i)*26, y: ty + 17,
                                   width: 16, height: 16))
    }
    for (j,b) in ["Copy","Save…"].enumerated() {
        let r = CGRect(x: edRect.maxX - 160 + CGFloat(j)*78, y: ty + 10, width: 70, height: 32)
        DemoReel.roundRectPath(ctx, r, 7)
        ctx.setFillColor(j == 1 ? CGColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)
                                : CGColor(gray: 0.3, alpha: 1)); ctx.fillPath()
        DemoReel.drawText(ctx, b,
            at: CGPoint(x: r.midX - DemoReel.textWidth(b, size: 13)/2, y: r.midY - 6),
            size: 13, color: CGColor(gray: 1, alpha: 1))
    }
    // canvas area: dim desktop seen "through" the capture
    ctx.saveGState()
    ctx.clip(to: [canvas])
    ctx.setFillColor(CGColor(gray: 0.05, alpha: 1)); ctx.fill(canvas)
    ctx.restoreGState()
    ctx.restoreGState()
}

func floatingPreview(_ ctx: CGContext, t: CGFloat) {
    guard t > 0 else { return }
    let r = CGRect(x: W - 340, y: 40, width: 300, height: 190)
    ctx.saveGState(); ctx.setAlpha(min(1, t * 1.3))
    ctx.translateBy(x: 0, y: (1-t) * -30)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 26,
                  color: CGColor(gray: 0, alpha: 0.55))
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setFillColor(CGColor(gray: 0.09, alpha: 1)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    // × button
    ctx.setFillColor(CGColor(gray: 0.3, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: r.maxX - 16, y: r.maxY - 16, width: 18, height: 18))
    DemoReel.drawText(ctx, "×", at: CGPoint(x: r.maxX - 13, y: r.maxY - 13),
                      size: 12, color: CGColor(gray: 1, alpha: 1))
    // thumbnail = mini desktop
    if let desk = DemoReel.desktopImage(size: CGSize(width: W, height: H)) {
        ctx.saveGState()
        let th = r.insetBy(dx: 12, dy: 12)
        DemoReel.roundRectPath(ctx, th, 6); ctx.clip()
        // draw only the captured region scaled in
        let crop = CGImageSourceCreateWithData(Data() as CFData, nil) // noop guard
        _ = crop
        let iw = CGFloat(desk.width), ih = CGFloat(desk.height)
        let sx = region.minX / W * iw, sy = (H - region.maxY) / H * ih
        let sw = region.width / W * iw, sh = region.height / H * ih
        if let sub = desk.cropping(to: CGRect(x: sx, y: sy, width: sw, height: sh)) {
            ctx.draw(sub, in: th)
        }
        ctx.restoreGState()
    }
    ctx.restoreGState()
}

// annotation drawing inside canvas, staged by f
func annotations(_ ctx: CGContext, f: Int) {
    let c = canvas
    ctx.saveGState(); ctx.clip(to: [c])
    let red = CGColor(red: 1, green: 0.25, blue: 0.25, alpha: 1)
    let yel = CGColor(red: 1, green: 0.85, blue: 0.2, alpha: 0.55)
    let grn = CGColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1)
    if f >= 480 { // pen stroke
        ctx.setStrokeColor(red); ctx.setLineWidth(4); ctx.setLineCap(.round)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: c.minX + 60, y: c.maxY - 60))
        path.addCurve(to: CGPoint(x: c.minX + 320, y: c.maxY - 140),
                      control1: CGPoint(x: c.minX + 140, y: c.maxY - 200),
                      control2: CGPoint(x: c.minX + 240, y: c.maxY - 40))
        ctx.addPath(path); ctx.strokePath()
    }
    if f >= 540 { // arrow
        let a = CGPoint(x: c.minX + 80, y: c.minY + 120)
        let b = CGPoint(x: c.minX + 300, y: c.minY + 60)
        ctx.setStrokeColor(grn); ctx.setLineWidth(5); ctx.setLineCap(.round)
        ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
        // head
        let ang = atan2(b.y - a.y, b.x - a.x)
        for s in [-0.5, 0.5] as [CGFloat] {
            ctx.move(to: b)
            ctx.addLine(to: CGPoint(x: b.x - 22*cos(ang + s*CGFloat.pi/3),
                                    y: b.y - 22*sin(ang + s*CGFloat.pi/3)))
        }
        ctx.strokePath()
    }
    if f >= 600 { // rectangle
        ctx.setStrokeColor(CGColor(red: 0.3, green: 0.6, blue: 1, alpha: 1))
        ctx.setLineWidth(4)
        ctx.stroke(CGRect(x: c.maxX - 330, y: c.maxY - 260, width: 240, height: 150))
    }
    if f >= 650 { // highlight band
        ctx.setFillColor(yel)
        ctx.fill(CGRect(x: c.minX + 60, y: c.minY + 210, width: 420, height: 34))
    }
    if f >= 700 { // mosaic patch
        let mr = CGRect(x: c.maxX - 330, y: c.minY + 40, width: 240, height: 110)
        let px: CGFloat = 12
        var i = 0
        var y = mr.minY
        while y < mr.maxY { var x = mr.minX
            while x < mr.maxX {
                ctx.setFillColor(CGColor(gray: CGFloat((i*37%100))/100*0.7+0.15, alpha: 1))
                ctx.fill(CGRect(x: x, y: y, width: px-1, height: px-1))
                x += px; i += 1
            }
            y += px
        }
    }
    if f >= 750 { // text label
        DemoReel.drawText(ctx, "Ship it 🚀",
            at: CGPoint(x: c.midX - 90, y: c.midY + 40), size: 34,
            color: CGColor(gray: 1, alpha: 1))
    }
    ctx.restoreGState()
}

func chip(_ ctx: CGContext, _ text: String, x: CGFloat, y: CGFloat, t: CGFloat) {
    guard t > 0 else { return }
    let pop = Ease.spring(t)
    let size: CGFloat = 40
    let a = NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: .heavy)])
    let w = a.size().width + 64, h: CGFloat = 86
    let xc = min(max(x, 20), W - w - 20)
    let r = CGRect(x: xc, y: y - (1-pop)*30, width: w*pop, height: h*pop)
    ctx.saveGState(); ctx.setAlpha(t)
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 24,
                  color: CGColor(gray: 0, alpha: 0.55))
    DemoReel.roundRectPath(ctx, r, 22*pop)
    ctx.setFillColor(CGColor(gray: 0.08, alpha: 0.92)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setStrokeColor(CGColor(red: 1, green: 0.84, blue: 0.3, alpha: 1))
    ctx.setLineWidth(2.5)
    DemoReel.roundRectPath(ctx, r, 22*pop); ctx.strokePath()
    let line = CTLineCreateWithAttributedString(NSAttributedString(
        string: text, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: .heavy),
            .foregroundColor: NSColor.white]))
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: r.midX - a.size().width*pop/2, y: r.midY - 14*pop)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
    ctx.restoreGState()
}

func hotkeyBadge(_ ctx: CGContext, _ keys: String, at p: CGPoint, t: CGFloat) {
    guard t > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(t)
    let w = DemoReel.textWidth(keys, size: 22) + 36
    let r = CGRect(x: p.x - w/2, y: p.y, width: w, height: 44)
    DemoReel.roundRectPath(ctx, r, 10)
    ctx.setFillColor(CGColor(gray: 0.08, alpha: 0.95)); ctx.fillPath()
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.4)); ctx.setLineWidth(1)
    DemoReel.roundRectPath(ctx, r, 10); ctx.strokePath()
    DemoReel.drawText(ctx, keys, at: CGPoint(x: r.minX + 18, y: r.minY + 12),
                      size: 22, color: CGColor(gray: 1, alpha: 1))
    ctx.restoreGState()
}

let demo = Demo(scenes: [
    // menubar icon + hotkey
    Scene(0...150, caption: "SwiftShot lives in the menubar") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.15 * t))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        // highlight camera icon in menubar (engine draws it near right side)
        let icon = CGPoint(x: W - 180, y: H - mTop/2)
        let tt = min(1, max(0, (t - 0.3) * 2))
        if tt > 0 {
            ctx.saveGState(); ctx.setAlpha(tt)
            ctx.setStrokeColor(CGColor(red: 1, green: 0.84, blue: 0.3, alpha: 1))
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: icon.x - 18, y: icon.y - 18, width: 36, height: 36))
            ctx.restoreGState()
        }
        hotkeyBadge(ctx, "⌃⌘1", at: CGPoint(x: W - 260, y: H - 120), t: tt)
        chip(ctx, "Press ⌃⌘1 — Capture Region", x: 640, y: 700, t: tt)
    },

    // drag selection over dimmed screen
    Scene(151...450, caption: "Drag anywhere — rubber-band selection") { ctx, t, f in
        dim(ctx, alpha: 0.45 * min(1, t * 2))
        var p = regionStart
        if f >= 190 && f < 250 {
            let dt = Ease.inOut(CGFloat(f - 190) / 60)
            p = CGPoint(x: regionStart.x + (regionEnd.x - regionStart.x) * dt,
                        y: regionStart.y + (regionEnd.y - regionStart.y) * dt)
            let r = CGRect(x: min(regionStart.x, p.x), y: min(p.y, regionStart.y),
                           width: abs(p.x - regionStart.x), height: abs(regionStart.y - p.y))
            dim(ctx, alpha: 0.45 * min(1, t*2), except: r)
            selectionUI(ctx, r)
            DemoReel.cursor(ctx, at: p, clicking: true)
        } else if f >= 250 {
            dim(ctx, alpha: 0.45 * min(1, t*2), except: region)
            selectionUI(ctx, region)
            DemoReel.cursor(ctx, at: regionEnd, clicking: false)
        } else {
            DemoReel.cursor(ctx, at: p, clicking: false)
        }
        chip(ctx, "Release — or press ⏎ — to capture", x: 60, y: 160,
             t: min(1, max(0, CGFloat(f - 255) / 30)))
    },

    // editor opens, annotations stage in
    Scene(451...830, caption: "Annotate before saving — pen, arrow, rect, highlight, mosaic, text") { ctx, t, f in
        let et = min(1, t * 2)
        // desktop behind slightly dimmed
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.3 * et))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        editorWindow(ctx, alpha: et)
        // draw captured region content inside canvas (real desktop crop)
        if let desk = DemoReel.desktopImage(size: CGSize(width: W, height: H)) {
            let iw = CGFloat(desk.width), ih = CGFloat(desk.height)
            let sx = region.minX / W * iw, sy = (H - region.maxY) / H * ih
            let sw = region.width / W * iw, sh = region.height / H * ih
            if let sub = desk.cropping(to: CGRect(x: sx, y: sy, width: sw, height: sh)) {
                ctx.saveGState(); ctx.clip(to: [canvas])
                ctx.setAlpha(et)
                ctx.draw(sub, in: canvas)
                ctx.restoreGState()
            }
        }
        ctx.saveGState(); ctx.setAlpha(et); annotations(ctx, f: f); ctx.restoreGState()
        let stages: [(Int, String)] = [(480,"Pen"),(540,"Arrow"),(600,"Rectangle"),
                                       (650,"Highlight"),(700,"Mosaic"),(750,"Text")]
        for (i,(sf,name)) in stages.enumerated() where f >= sf && f < sf + 55 {
            chip(ctx, name, x: 60 + CGFloat(i%2)*0, y: 160 + CGFloat(i)*0, // stacked left
                 t: min(1, CGFloat(f - sf)/15) * min(1, CGFloat(sf+55-f)/15))
        }
    },

    // copy + floating preview
    Scene(831...1050, caption: "Copy — then the floating preview pins bottom-right") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.15))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        // editor fades away after "Copy" click
        if f < 880 { editorWindow(ctx, alpha: 1 - CGFloat(f-831)/50) }
        if f >= 880 {
            floatingPreview(ctx, t: min(1, CGFloat(f - 880) / 20))
        }
        if f >= 845 && f < 870 { // cursor on Copy button
            DemoReel.cursor(ctx, at: CGPoint(x: edRect.maxX - 125, y: edRect.maxY - edTitleH - toolbarH/2), clicking: f >= 855)
        }
        chip(ctx, "PNG + TIFF straight to clipboard", x: 60, y: 160,
             t: min(1, max(0, CGFloat(f - 885) / 30)))
    },

    // save dialog
    Scene(1051...1280, caption: "Save… — PNG or JPEG, wherever you want") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.2))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        floatingPreview(ctx, t: 1)
        // NSSavePanel-ish sheet
        let st = min(1, t * 2)
        let sr = CGRect(x: W/2 - 320, y: H/2 - 140, width: 640, height: 280)
        ctx.saveGState(); ctx.setAlpha(st)
        DemoReel.roundRectPath(ctx, sr, 12)
        ctx.setFillColor(CGColor(gray: 0.16, alpha: 1)); ctx.fillPath()
        DemoReel.drawText(ctx, "Save As", at: CGPoint(x: sr.minX + 20, y: sr.maxY - 34),
                          size: 15, color: CGColor(gray: 1, alpha: 1))
        // filename field
        let fr = CGRect(x: sr.minX + 20, y: sr.maxY - 80, width: sr.width - 40, height: 34)
        DemoReel.roundRectPath(ctx, fr, 6)
        ctx.setFillColor(CGColor(gray: 0.08, alpha: 1)); ctx.fillPath()
        let name = "SwiftShot 2026-10-19 at 15.42.30.png"
        DemoReel.drawText(ctx, name, at: CGPoint(x: fr.minX + 10, y: fr.minY + 9),
                          size: 14, color: CGColor(gray: 0.9, alpha: 1))
        for (j,b) in ["Cancel","Save"].enumerated() {
            let br = CGRect(x: sr.maxX - 190 + CGFloat(j)*95, y: sr.minY + 20, width: 85, height: 34)
            DemoReel.roundRectPath(ctx, br, 7)
            ctx.setFillColor(j == 1 ? CGColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)
                                    : CGColor(gray: 0.3, alpha: 1)); ctx.fillPath()
            DemoReel.drawText(ctx, b, at: CGPoint(x: br.midX - DemoReel.textWidth(b, size: 13)/2,
                                                  y: br.midY - 6), size: 13,
                              color: CGColor(gray: 1, alpha: 1))
        }
        ctx.restoreGState()
        if f >= 1150 && f < 1180 {
            DemoReel.cursor(ctx, at: CGPoint(x: sr.maxX - 100, y: sr.minY + 37), clicking: f >= 1160)
        }
    },

    // extras + outro
    Scene(1281...1500, caption: "⌃⌘2 fullscreen · ⌘Z undo · ⎋ cancel · hide desktop icons") { ctx, t, f in
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.45 * min(1, t * 2)))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        floatingPreview(ctx, t: min(1, CGFloat(1320 - f) / 15))
        let chips = ["⌃⌘1 Region","⌃⌘2 Fullscreen","⌘Z Undo","⎋ Cancel","Hide Desktop Icons","Auto-fade Preview"]
        for (i, c) in chips.enumerated() {
            let tt = min(1, max(0, t * 2.6 - CGFloat(i) * 0.12))
            let gap: CGFloat = 18, w: CGFloat = 240, h: CGFloat = 64
            let cols = 3, row = i / cols, col = i % cols
            let total = CGFloat(cols) * (w + gap) - gap
            let x = (W - total) / 2 + CGFloat(col) * (w + gap)
            let y = H/2 + 60 - CGFloat(row) * (h + gap) - (1 - tt) * 30
            ctx.saveGState(); ctx.setAlpha(tt)
            DemoReel.roundRectPath(ctx, CGRect(x: x, y: y, width: w, height: h), 14)
            ctx.setFillColor(CGColor(gray: 0.13, alpha: 0.95)); ctx.fillPath()
            DemoReel.drawText(ctx, c,
                at: CGPoint(x: x + w/2 - DemoReel.textWidth(c, size: 18)/2, y: y + h/2 - 8),
                size: 18, color: CGColor(gray: 1, alpha: 1))
            ctx.restoreGState()
        }
    },
])
DemoReel.run(demo: demo, outdir: "/tmp/ss-frames")
