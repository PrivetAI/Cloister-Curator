import SwiftUI

// MARK: - Geometric primitives used throughout the app
// Every icon is rendered as a Shape composition — no SF Symbols, no emoji.

// MARK: - Leaf
struct CloisterLeafShape: Shape {
    var pointy: Bool = false
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        if pointy {
            p.move(to: CGPoint(x: mid.x, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.maxY),
                           control: CGPoint(x: rect.maxX + w * 0.05, y: mid.y))
            p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.minY),
                           control: CGPoint(x: rect.minX - w * 0.05, y: mid.y))
        } else {
            p.move(to: CGPoint(x: mid.x, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.maxY),
                           control: CGPoint(x: rect.maxX, y: mid.y + h * 0.15))
            p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.minY),
                           control: CGPoint(x: rect.minX, y: mid.y - h * 0.15))
        }
        return p
    }
}

// MARK: - Fern frond
struct CloisterFernShape: Shape {
    var leaflets: Int = 8
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let stem = CGPoint(x: rect.midX, y: rect.maxY)
        let top = CGPoint(x: rect.midX, y: rect.minY)
        p.move(to: stem)
        p.addQuadCurve(to: top, control: CGPoint(x: rect.midX + rect.width * 0.05, y: rect.midY))
        let total = max(2, leaflets)
        for i in 0..<total {
            let t = CGFloat(i + 1) / CGFloat(total + 1)
            let basePoint = CGPoint(x: rect.midX, y: rect.maxY - t * rect.height)
            let len = (1.0 - t) * rect.width * 0.50 + rect.width * 0.07
            // left leaflet
            let lend = CGPoint(x: basePoint.x - len, y: basePoint.y - len * 0.45)
            p.move(to: basePoint)
            p.addQuadCurve(to: lend, control: CGPoint(x: basePoint.x - len * 0.55, y: basePoint.y - len * 0.05))
            // right leaflet
            let rend = CGPoint(x: basePoint.x + len, y: basePoint.y - len * 0.45)
            p.move(to: basePoint)
            p.addQuadCurve(to: rend, control: CGPoint(x: basePoint.x + len * 0.55, y: basePoint.y - len * 0.05))
        }
        return p
    }
}

// MARK: - Petal (used to build flowers)
struct CloisterPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        p.move(to: CGPoint(x: mid.x, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: mid.y))
        p.addQuadCurve(to: CGPoint(x: mid.x, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: mid.y))
        return p
    }
}

// MARK: - Flower (composed of petals + center)
struct CloisterFlower: View {
    var petals: Int = 6
    var petalColor: Color
    var centerColor: Color = CloisterPalette.gilded
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<petals, id: \.self) { idx in
                    CloisterPetalShape()
                        .fill(petalColor)
                        .frame(width: s * 0.30, height: s * 0.55)
                        .offset(y: -s * 0.22)
                        .rotationEffect(.degrees(Double(idx) * 360.0 / Double(petals)))
                }
                Circle()
                    .fill(centerColor)
                    .frame(width: s * 0.25, height: s * 0.25)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

// MARK: - Droplet (water/humidity indicator)
struct CloisterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midX
        p.move(to: CGPoint(x: mid, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY + rect.height * 0.10),
                       control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45))
        p.addArc(center: CGPoint(x: mid, y: rect.midY + rect.height * 0.10),
                 radius: rect.width / 2,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: mid, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.45))
        return p
    }
}

// MARK: - Sun (for light level)
struct CloisterSunShape: Shape {
    var rays: Int = 8
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 4.0
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        let outerR = min(rect.width, rect.height) / 2.0
        let innerR = r * 1.25
        for i in 0..<rays {
            let a = Double(i) * (.pi * 2) / Double(rays)
            let p1 = CGPoint(x: c.x + cos(a) * innerR, y: c.y + sin(a) * innerR)
            let p2 = CGPoint(x: c.x + cos(a) * outerR, y: c.y + sin(a) * outerR)
            p.move(to: p1)
            p.addLine(to: p2)
        }
        return p
    }
}

// MARK: - Substrate (mound) shape
struct CloisterMoundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Pot
struct CloisterPotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topInset = rect.width * 0.06
        let bottomInset = rect.width * 0.18
        let rimH = rect.height * 0.15
        // Rim
        p.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - topInset * 1.2, y: rect.minY + rimH))
        p.addLine(to: CGPoint(x: rect.minX + topInset * 1.2, y: rect.minY + rimH))
        p.closeSubpath()
        // Body
        p.move(to: CGPoint(x: rect.minX + topInset * 1.2, y: rect.minY + rimH))
        p.addLine(to: CGPoint(x: rect.maxX - topInset * 1.2, y: rect.minY + rimH))
        p.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + bottomInset, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Terrarium (dome)
struct CloisterTerrariumShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let baseH = rect.height * 0.10
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - baseH))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - baseH),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Bed (rectangular planter)
struct CloisterBedShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 6
        return Path(roundedRect: rect, cornerRadius: r)
    }
}

// MARK: - Conifer (triangle cluster)
struct CloisterConiferShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let stages = 3
        let stageH = rect.height / CGFloat(stages + 1)
        for i in 0..<stages {
            let topY = CGFloat(i) * stageH
            let baseY = topY + stageH * 1.4
            let halfW = rect.width * (CGFloat(i + 1) / CGFloat(stages + 1)) * 0.55
            let mid = rect.midX
            p.move(to: CGPoint(x: mid, y: topY))
            p.addLine(to: CGPoint(x: mid + halfW, y: baseY))
            p.addLine(to: CGPoint(x: mid - halfW, y: baseY))
            p.closeSubpath()
        }
        // trunk
        let trunkW = rect.width * 0.10
        let trunkRect = CGRect(x: rect.midX - trunkW / 2, y: rect.height * 0.85, width: trunkW, height: rect.height * 0.15)
        p.addRect(trunkRect)
        return p
    }
}

// MARK: - Carnivorous trap
struct CloisterTrapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Upper jaw
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        // Lower jaw
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.maxY))
        // Teeth
        let teeth = 6
        for i in 0..<teeth {
            let t = CGFloat(i + 1) / CGFloat(teeth + 1)
            let x = rect.minX + t * rect.width
            p.move(to: CGPoint(x: x, y: rect.midY - rect.height * 0.05))
            p.addLine(to: CGPoint(x: x + rect.width * 0.02, y: rect.midY - rect.height * 0.18))
            p.move(to: CGPoint(x: x, y: rect.midY + rect.height * 0.05))
            p.addLine(to: CGPoint(x: x + rect.width * 0.02, y: rect.midY + rect.height * 0.18))
        }
        return p
    }
}

// MARK: - Coin
/// Inner stamped emblem on the coin: an open crescent/horseshoe form built from arcs and a
/// horizontal bar. Pure Shape composition — no SF Symbols, no Text glyphs.
struct CloisterCoinEmblemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) * 0.40
        // Open crescent: arc opening to the right (from 30deg to 330deg counter-clockwise).
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                 startAngle: .degrees(30), endAngle: .degrees(330),
                 clockwise: true)
        // Centered horizontal serif bar across the crescent's interior.
        let barInset = r * 0.55
        let barY = cy
        p.move(to: CGPoint(x: cx - barInset, y: barY))
        p.addLine(to: CGPoint(x: cx + barInset, y: barY))
        // Two small terminal pips on the bar ends.
        let pipR = r * 0.12
        p.addEllipse(in: CGRect(x: cx - barInset - pipR, y: barY - pipR,
                                width: pipR * 2, height: pipR * 2))
        p.addEllipse(in: CGRect(x: cx + barInset - pipR, y: barY - pipR,
                                width: pipR * 2, height: pipR * 2))
        return p
    }
}

struct CloisterCoinView: View {
    var size: CGFloat = 16
    var body: some View {
        ZStack {
            Circle().fill(CloisterPalette.gilded)
            Circle().stroke(CloisterPalette.gildedLight, lineWidth: max(1, size * 0.06))
            CloisterCoinEmblemShape()
                .stroke(CloisterPalette.parchmentDeep,
                        style: StrokeStyle(lineWidth: max(1, size * 0.10), lineCap: .round, lineJoin: .round))
                .padding(size * 0.18)
        }.frame(width: size, height: size)
    }
}

// MARK: - Page-corner ornament for headers
struct CloisterCornerOrnament: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s = min(rect.width, rect.height)
        // Three nested arcs
        for i in 1...3 {
            let r = s * (CGFloat(i) / 4.0)
            p.addArc(center: CGPoint(x: 0, y: 0), radius: r,
                     startAngle: .degrees(0), endAngle: .degrees(90),
                     clockwise: false)
        }
        // Diagonal lines
        for i in 0..<4 {
            let t = CGFloat(i) / 4.0
            p.move(to: CGPoint(x: s * t, y: 0))
            p.addLine(to: CGPoint(x: 0, y: s * t))
        }
        return p
    }
}

// MARK: - Quill icon (used for journaling)
struct CloisterQuillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX * 0.75, y: rect.minY + rect.height * 0.25))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.10))
        p.addQuadCurve(to: CGPoint(x: rect.maxX * 0.75, y: rect.minY + rect.height * 0.25),
                       control: CGPoint(x: rect.maxX * 0.78, y: rect.minY + rect.height * 0.08))
        return p
    }
}

// MARK: - Hourglass (action/turn icon)
struct CloisterHourglassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let pad = rect.width * 0.08
        p.move(to: CGPoint(x: rect.minX + pad, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - pad, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - pad, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + pad, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Cross (cross icon, looks like a punnet square)
struct CloisterCrossIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let half = rect.width / 2
        p.addRect(rect)
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        // Inner dots
        for x in [rect.minX + half * 0.5, rect.minX + half * 1.5] {
            for y in [rect.minY + half * 0.5, rect.minY + half * 1.5] {
                p.addEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
            }
        }
        return p
    }
}

// MARK: - Visitor silhouette (abstract figure)
struct CloisterFigureShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Head
        let headR = rect.width * 0.18
        p.addEllipse(in: CGRect(x: rect.midX - headR, y: rect.minY + rect.height * 0.05,
                                width: headR * 2, height: headR * 2))
        // Body (cloak)
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.30))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.30),
                       control: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Page/book icon
struct CloisterBookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let spineW = rect.width * 0.04
        // Left page
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.10))
        p.addLine(to: CGPoint(x: rect.midX - spineW, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - spineW, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.10))
        p.closeSubpath()
        // Right page
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.10))
        p.addLine(to: CGPoint(x: rect.midX + spineW, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + spineW, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.10))
        p.closeSubpath()
        return p
    }
}

// MARK: - Tab icons (used in HStack tab bar)
struct CloisterTabIcon: View {
    enum Kind { case cloister, cross, herbarium, visitors, almanac }
    let kind: Kind
    var size: CGFloat = 24
    var color: Color
    var body: some View {
        Group {
            switch kind {
            case .cloister:
                ZStack {
                    CloisterPotShape().stroke(color, lineWidth: 1.6)
                    CloisterLeafShape().fill(color).frame(width: size * 0.38, height: size * 0.55).offset(y: -size * 0.22)
                }
            case .cross:
                CloisterCrossIconShape().stroke(color, lineWidth: 1.6)
            case .herbarium:
                CloisterBookShape().stroke(color, lineWidth: 1.6)
            case .visitors:
                CloisterFigureShape().stroke(color, lineWidth: 1.6)
            case .almanac:
                CloisterQuillShape().stroke(color, lineWidth: 1.6)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Trait dot (decorative inline indicator)
struct CloisterTraitDot: View {
    let color: Color
    var size: CGFloat = 10
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(CloisterPalette.divider, lineWidth: 0.5))
    }
}

// MARK: - Empty plant slot
struct CloisterEmptySlotShape: Shape {
    func path(in rect: CGRect) -> Path {
        return Path(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 8)
    }
}

// MARK: - Progress bar (custom)
struct CloisterProgressBar: View {
    var progress: Double // 0...1
    var fill: Color = CloisterPalette.moss
    var trackHeight: CGFloat = 8
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                    .fill(CloisterPalette.stoneLight.opacity(0.45))
                RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                    .fill(fill)
                    .frame(width: max(0, min(1, progress)) * proxy.size.width)
            }
        }
        .frame(height: trackHeight)
    }
}
