import SwiftUI

// MARK: - Plant illustration system
// Renders a stylized plant from species traits and growth stage,
// composed from Shape primitives — no SF Symbols, no emoji.

struct PlantIllustration: View {
    let species: Species
    let stage: GrowthStage
    var size: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width, proxy.size.height)
            ZStack {
                drawForFamily(s: s)
            }
            .frame(width: s, height: s)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(width: size, height: size)
        .clipped()
    }

    @ViewBuilder
    private func drawForFamily(s: CGFloat) -> some View {
        let color = species.traits.color.color
        let secondaryColor = species.family.accentColor
        let h = stageScale * s
        let baseY = s * 0.95
        switch species.family {
        case .bryophyta:
            mossView(color: color, height: h, baseY: baseY, s: s)
        case .pteridophyta:
            fernView(color: color, height: h, baseY: baseY, s: s, secondary: secondaryColor)
        case .coniferae:
            coniferView(color: color, height: h, baseY: baseY, s: s)
        case .angiosperma:
            angiospermView(color: color, height: h, baseY: baseY, s: s, secondary: secondaryColor)
        case .carnivora:
            carnivoraView(color: color, height: h, baseY: baseY, s: s, secondary: secondaryColor)
        }
    }

    private var stageScale: CGFloat {
        switch stage {
        case .seed: return 0.18
        case .sprout: return 0.32
        case .sapling: return 0.5
        case .mature: return 0.72
        case .flowering: return 0.88
        case .seeding: return 0.95
        }
    }

    // MARK: - Family drawings
    private func mossView(color: Color, height: CGFloat, baseY: CGFloat, s: CGFloat) -> some View {
        ZStack {
            // Mound of moss bumps
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(color.opacity(0.85))
                    .frame(width: s * 0.22, height: s * 0.22)
                    .offset(x: (CGFloat(i) - 2) * (s * 0.16), y: baseY - height + s * 0.05)
            }
            // Stalks (only at sapling+)
            if stage.rawValue >= GrowthStage.sapling.rawValue {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(CloisterPalette.mossDark)
                        .frame(width: s * 0.02, height: s * 0.18)
                        .offset(x: (CGFloat(i) - 2) * (s * 0.16), y: baseY - height - s * 0.04)
                    Circle()
                        .fill(CloisterPalette.gilded)
                        .frame(width: s * 0.05, height: s * 0.05)
                        .offset(x: (CGFloat(i) - 2) * (s * 0.16), y: baseY - height - s * 0.16)
                }
            }
        }
    }

    private func fernView(color: Color, height: CGFloat, baseY: CGFloat, s: CGFloat, secondary: Color) -> some View {
        ZStack {
            // Stem(s)
            ForEach(0..<3, id: \.self) { i in
                CloisterFernShape(leaflets: stage.rawValue + 4)
                    .stroke(color, lineWidth: 1.2)
                    .frame(width: s * 0.5, height: height)
                    .rotationEffect(.degrees(Double(i - 1) * 22))
                    .offset(y: baseY - height / 2)
            }
        }
    }

    private func coniferView(color: Color, height: CGFloat, baseY: CGFloat, s: CGFloat) -> some View {
        ZStack {
            CloisterConiferShape()
                .fill(color)
                .frame(width: s * 0.7, height: height)
                .offset(y: baseY - height / 2)
            CloisterConiferShape()
                .stroke(CloisterPalette.mossDark, lineWidth: 0.8)
                .frame(width: s * 0.7, height: height)
                .offset(y: baseY - height / 2)
        }
    }

    private func angiospermView(color: Color, height: CGFloat, baseY: CGFloat, s: CGFloat, secondary: Color) -> some View {
        ZStack {
            // Stem
            Rectangle()
                .fill(CloisterPalette.mossDark)
                .frame(width: s * 0.04, height: height)
                .offset(y: baseY - height / 2)
            // Leaves
            CloisterLeafShape()
                .fill(secondary)
                .frame(width: s * 0.18, height: s * 0.25)
                .rotationEffect(.degrees(-35))
                .offset(x: -s * 0.10, y: baseY - height * 0.5)
            CloisterLeafShape()
                .fill(secondary)
                .frame(width: s * 0.18, height: s * 0.25)
                .rotationEffect(.degrees(35))
                .offset(x: s * 0.10, y: baseY - height * 0.5)
            // Flower (only at flowering/seeding)
            if stage.rawValue >= GrowthStage.flowering.rawValue {
                CloisterFlower(petals: 6, petalColor: color, centerColor: CloisterPalette.gilded)
                    .frame(width: s * 0.35, height: s * 0.35)
                    .offset(y: baseY - height + s * 0.05)
            } else if stage.rawValue >= GrowthStage.mature.rawValue {
                Circle().fill(color.opacity(0.7))
                    .frame(width: s * 0.12, height: s * 0.12)
                    .offset(y: baseY - height + s * 0.05)
            }
        }
    }

    private func carnivoraView(color: Color, height: CGFloat, baseY: CGFloat, s: CGFloat, secondary: Color) -> some View {
        ZStack {
            // Pitcher form or trap
            CloisterTerrariumShape()
                .fill(color)
                .frame(width: s * 0.35, height: height * 0.6)
                .offset(y: baseY - height * 0.30)
            CloisterTerrariumShape()
                .stroke(CloisterPalette.ink, lineWidth: 0.8)
                .frame(width: s * 0.35, height: height * 0.6)
                .offset(y: baseY - height * 0.30)
            if stage.rawValue >= GrowthStage.mature.rawValue {
                CloisterTrapShape()
                    .stroke(secondary, lineWidth: 1.0)
                    .frame(width: s * 0.50, height: s * 0.18)
                    .offset(y: baseY - height + s * 0.02)
            }
        }
    }
}

// MARK: - Family icon (small)
struct FamilyIcon: View {
    let family: CloisterFamily
    var size: CGFloat = 22
    var color: Color
    var body: some View {
        Group {
            switch family {
            case .bryophyta:
                ZStack {
                    Circle().fill(color.opacity(0.8)).frame(width: size * 0.5, height: size * 0.5)
                        .offset(x: -size * 0.18, y: size * 0.15)
                    Circle().fill(color.opacity(0.65)).frame(width: size * 0.4, height: size * 0.4)
                        .offset(x: size * 0.10, y: size * 0.20)
                }
            case .pteridophyta:
                CloisterFernShape(leaflets: 6).stroke(color, lineWidth: 1.4)
            case .coniferae:
                CloisterConiferShape().stroke(color, lineWidth: 1.4)
            case .angiosperma:
                CloisterFlower(petals: 6, petalColor: color, centerColor: CloisterPalette.gilded)
            case .carnivora:
                ZStack {
                    CloisterTerrariumShape().stroke(color, lineWidth: 1.4)
                    CloisterTrapShape().stroke(color, lineWidth: 1.2).frame(width: size * 0.7, height: size * 0.25)
                        .offset(y: -size * 0.25)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Trait visual chip
struct TraitChip: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(CloisterFont.ui(8, weight: .heavy))
                .tracking(0.8)
                .foregroundColor(CloisterPalette.textMuted)
            Text(value)
                .font(CloisterFont.ui(11, weight: .bold))
                .foregroundColor(CloisterPalette.textPrimary)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.45), lineWidth: 0.6)
        )
    }
}

struct TraitGrid: View {
    let traits: TraitBundle
    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            TraitChip(label: "Leaf", value: traits.leaf.label, color: CloisterPalette.moss)
            TraitChip(label: "Color", value: traits.color.label, color: traits.color.color)
            TraitChip(label: "Scent", value: traits.scent.label, color: CloisterPalette.gilded)
            TraitChip(label: "Life", value: traits.lifespan.label, color: CloisterPalette.stoneDark)
            TraitChip(label: "Frost", value: traits.frost.label, color: CloisterPalette.stone)
            TraitChip(label: "Drought", value: traits.drought.label, color: CloisterPalette.reliquary)
        }
    }
}
