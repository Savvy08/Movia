import AppKit

let width: CGFloat = 660
let height: CGFloat = 440

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: width, height: height)

// 1. Sleek Deep Charcoal / Dark Background
let bgGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.18, alpha: 1.0),
    NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.11, alpha: 1.0)
])
bgGradient?.draw(in: rect, angle: -45)

// 2. Icon slot backdrops (glass cards behind icons and labels)
// Left icon center: (165, 215), Right icon center: (495, 215)
let card1Rect = NSRect(x: 75, y: 90, width: 180, height: 220)
let card2Rect = NSRect(x: 405, y: 90, width: 180, height: 220)

for cardRect in [card1Rect, card2Rect] {
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
    NSColor(calibratedWhite: 1.0, alpha: 0.04).setFill()
    cardPath.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.10).setStroke()
    cardPath.lineWidth = 1.2
    cardPath.stroke()
}

// 2b. Light frosted glass pills hugging icon labels tightly
let pill1Rect = NSRect(x: 133, y: 128, width: 64, height: 19)
let pill2Rect = NSRect(x: 441, y: 128, width: 108, height: 19)

for pillRect in [pill1Rect, pill2Rect] {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    shadow.shadowBlurRadius = 4
    shadow.set()
    
    let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 9.5, yRadius: 9.5)
    NSColor(calibratedWhite: 0.95, alpha: 0.94).setFill()
    pillPath.fill()
    NSGraphicsContext.restoreGraphicsState()
    
    let borderPill = NSBezierPath(roundedRect: pillRect, xRadius: 9.5, yRadius: 9.5)
    borderPill.lineWidth = 1.0
    NSColor(calibratedWhite: 1.0, alpha: 0.95).setStroke()
    borderPill.stroke()
}

// Subtle Glow behind Movia icon on the left
let glowPath = NSBezierPath(ovalIn: NSRect(x: 95, y: 135, width: 140, height: 140))
let glowGrad = NSGradient(colors: [
    NSColor(calibratedRed: 0.0, green: 0.78, blue: 0.95, alpha: 0.20),
    NSColor.clear
])
glowGrad?.draw(in: glowPath, relativeCenterPosition: .zero)

// 3. Header Text: "Movia" (Pure White)
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
    .foregroundColor: NSColor.white
]
let title = "Movia"
let titleSize = title.size(withAttributes: titleAttributes)
title.draw(at: NSPoint(x: (width - titleSize.width) / 2, y: height - 60), withAttributes: titleAttributes)

// Subtitle (Pure White)
let subAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor.white
]
let subtitle = "Нейросетевое замедление видео для Apple Silicon (Metal & ANE)"
let subSize = subtitle.size(withAttributes: subAttributes)
subtitle.draw(at: NSPoint(x: (width - subSize.width) / 2, y: height - 88), withAttributes: subAttributes)

// 4. Large Prominent Arrow between Movia (left) and Applications (right)
let arrowY: CGFloat = 215
let arrowLeft: CGFloat = 280
let arrowRight: CGFloat = 380

// Arrow Glow behind
let glowShaft = NSBezierPath()
glowShaft.move(to: NSPoint(x: arrowLeft, y: arrowY))
glowShaft.line(to: NSPoint(x: arrowRight, y: arrowY))
glowShaft.lineWidth = 14
glowShaft.lineCapStyle = .round
NSColor(calibratedRed: 0.0, green: 0.82, blue: 1.0, alpha: 0.25).setStroke()
glowShaft.stroke()

// Arrow shaft (Main)
let shaft = NSBezierPath()
shaft.move(to: NSPoint(x: arrowLeft, y: arrowY))
shaft.line(to: NSPoint(x: arrowRight, y: arrowY))
shaft.lineWidth = 6
shaft.lineCapStyle = .round
NSColor(calibratedRed: 0.0, green: 0.88, blue: 1.0, alpha: 0.95).setStroke()
shaft.stroke()

// Arrow head
let head = NSBezierPath()
head.move(to: NSPoint(x: arrowRight - 16, y: arrowY + 14))
head.line(to: NSPoint(x: arrowRight + 4, y: arrowY))
head.line(to: NSPoint(x: arrowRight - 16, y: arrowY - 14))
head.lineWidth = 6
head.lineCapStyle = .round
head.lineJoinStyle = .round
NSColor(calibratedRed: 0.0, green: 0.88, blue: 1.0, alpha: 0.95).setStroke()
head.stroke()

// Arrow Label (Pure White, Bold)
let arrowLabelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .bold),
    .foregroundColor: NSColor.white
]
let arrowText = "Перетащите в Программы"
let arrowTextSize = arrowText.size(withAttributes: arrowLabelAttrs)
arrowText.draw(at: NSPoint(x: (width - arrowTextSize.width) / 2, y: arrowY - 38), withAttributes: arrowLabelAttrs)

// 5. Border around the DMG canvas
let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 12, yRadius: 12)
borderPath.lineWidth = 1
NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
borderPath.stroke()

image.unlockFocus()

// Save to Resources/dmg_background.png
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let outURL = URL(fileURLWithPath: "Resources/dmg_background.png")
    try? pngData.write(to: outURL)
    print("Created Resources/dmg_background.png (660x440)")
}
