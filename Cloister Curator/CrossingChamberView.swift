import SwiftUI

// MARK: - Cross tab
struct CrossingChamberView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var selectedSlotA: Int? = nil
    @State private var selectedSlotB: Int? = nil
    @State private var lastResultId: Int? = nil
    @State private var lastEvent: String? = nil

    var body: some View {
        ZStack {
            CloisterPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloisterHeader(
                        eyebrow: "MENDEL GRID",
                        title: "The Crossing Chamber",
                        subtitle: "Pair two seeding-stage plants. For each trait, the dominant value between the parents becomes the offspring's expression."
                    )

                    if let evt = lastEvent {
                        EventBanner(text: evt) { lastEvent = nil }
                    }

                    parentChooserSection

                    if let aIdx = selectedSlotA, let bIdx = selectedSlotB,
                       aIdx != bIdx,
                       let pA = store.state.slots[aIdx].plant,
                       let pB = store.state.slots[bIdx].plant,
                       pA.stage == .seeding, pB.stage == .seeding,
                       let sA = HybridCatalog.species(forId: pA.speciesId),
                       let sB = HybridCatalog.species(forId: pB.speciesId) {
                        punnettSection(parentA: sA, parentB: sB)
                        Button {
                            performCross(aIdx: aIdx, bIdx: bIdx)
                        } label: {
                            HStack(spacing: 8) {
                                CloisterCrossIconShape()
                                    .stroke(CloisterPalette.parchment, lineWidth: 1.4)
                                    .frame(width: 16, height: 16)
                                Text("Commit Cross")
                            }
                            .cloisterPrimary(enabled: store.state.actionsLeft > 0)
                        }
                        .disabled(store.state.actionsLeft <= 0)
                    } else {
                        Text("Select two mature seeding-stage plants to project a cross.")
                            .font(CloisterFont.body(13))
                            .foregroundColor(CloisterPalette.textMuted)
                            .padding(.horizontal, 4)
                    }

                    if let r = lastResultId, let s = HybridCatalog.species(forId: r) {
                        lastResultCard(species: s)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
        }
    }

    private var parentChooserSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CloisterSectionHeader("PARENTS", subtitle: "Choose two distinct seeding plants from the cloister.")
            let seedings = store.matureSeedingPlants
            if seedings.isEmpty {
                Text("No seeding plants available yet. Grow plants to the seeding stage to enable crossing.")
                    .font(CloisterFont.body(13))
                    .foregroundColor(CloisterPalette.textSecondary)
                    .cloisterCard()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(seedings, id: \.slotIndex) { item in
                        parentTile(item: item)
                    }
                }
            }
        }
    }

    private func parentTile(item: (slotIndex: Int, plant: PlantedSpecimen)) -> some View {
        let isA = (selectedSlotA == item.slotIndex)
        let isB = (selectedSlotB == item.slotIndex)
        return Button {
            if isA {
                selectedSlotA = nil
            } else if isB {
                selectedSlotB = nil
            } else if selectedSlotA == nil {
                selectedSlotA = item.slotIndex
            } else if selectedSlotB == nil {
                selectedSlotB = item.slotIndex
            } else {
                selectedSlotB = item.slotIndex
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Slot \(item.slotIndex + 1)")
                        .font(CloisterFont.ui(10, weight: .heavy))
                        .tracking(1.0)
                        .foregroundColor(CloisterPalette.textMuted)
                    Spacer()
                    if isA {
                        CloisterBadge(text: "PARENT A", color: CloisterPalette.moss)
                    } else if isB {
                        CloisterBadge(text: "PARENT B", color: CloisterPalette.reliquary)
                    }
                }
                if let s = HybridCatalog.species(forId: item.plant.speciesId) {
                    HStack(spacing: 10) {
                        PlantIllustration(species: s, stage: .seeding, size: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name)
                                .font(CloisterFont.display(13, weight: .bold))
                                .foregroundColor(CloisterPalette.textPrimary)
                                .lineLimit(2)
                            HStack(spacing: 4) {
                                CloisterBadge(text: s.family.shortName, color: s.family.accentColor)
                                CloisterBadge(text: s.rarity.rawValue, color: s.rarity.color)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isA || isB ? CloisterPalette.gildedLight.opacity(0.35) : CloisterPalette.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isA ? CloisterPalette.moss :
                            isB ? CloisterPalette.reliquary :
                            CloisterPalette.divider, lineWidth: isA || isB ? 1.5 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func punnettSection(parentA: Species, parentB: Species) -> some View {
        let p = CrossEngine.projectedOffspring(parentASpecies: parentA, parentBSpecies: parentB)
        return VStack(alignment: .leading, spacing: 10) {
            CloisterSectionHeader("PUNNETT PROJECTION", subtitle: "Two possible expressions per cross: primary (all dominant traits) or alternate (mixed recessive).")
            VStack(spacing: 0) {
                punnettHeaderRow()
                Rectangle().fill(CloisterPalette.divider).frame(height: 0.5)
                punnettRow(label: "Leaf",
                           a: p.leafA.label, b: p.leafB.label,
                           dom: TraitDominance.dominant(p.leafA, p.leafB, order: TraitDominance.leafOrder).label)
                punnettRow(label: "Color",
                           a: p.colorA.label, b: p.colorB.label,
                           dom: TraitDominance.dominant(p.colorA, p.colorB, order: TraitDominance.colorOrder).label)
                punnettRow(label: "Scent",
                           a: p.scentA.label, b: p.scentB.label,
                           dom: TraitDominance.dominant(p.scentA, p.scentB, order: TraitDominance.scentOrder).label)
                punnettRow(label: "Life",
                           a: p.lifeA.label, b: p.lifeB.label,
                           dom: TraitDominance.dominant(p.lifeA, p.lifeB, order: TraitDominance.lifeOrder).label)
                punnettRow(label: "Frost",
                           a: p.frostA.label, b: p.frostB.label,
                           dom: TraitDominance.dominant(p.frostA, p.frostB, order: TraitDominance.frostOrder).label)
                punnettRow(label: "Drought",
                           a: p.droughtA.label, b: p.droughtB.label,
                           dom: TraitDominance.dominant(p.droughtA, p.droughtB, order: TraitDominance.droughtOrder).label,
                           isLast: true)
            }
            .cloisterCard(padding: 0, corner: 12)
        }
    }
    private func punnettHeaderRow() -> some View {
        HStack(spacing: 0) {
            Text("TRAIT")
                .font(CloisterFont.ui(10, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(CloisterPalette.textMuted)
                .frame(width: 60, alignment: .leading)
            Text("PARENT A")
                .font(CloisterFont.ui(10, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(CloisterPalette.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PARENT B")
                .font(CloisterFont.ui(10, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(CloisterPalette.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("OFFSPRING")
                .font(CloisterFont.ui(10, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(CloisterPalette.moss)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private func punnettRow(label: String, a: String, b: String, dom: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(label).font(CloisterFont.ui(11, weight: .heavy)).tracking(1.0)
                    .foregroundColor(CloisterPalette.textMuted)
                    .frame(width: 60, alignment: .leading)
                Text(a)
                    .font(CloisterFont.ui(13, weight: .semibold))
                    .foregroundColor(CloisterPalette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(b)
                    .font(CloisterFont.ui(13, weight: .semibold))
                    .foregroundColor(CloisterPalette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(dom)
                    .font(CloisterFont.ui(13, weight: .heavy))
                    .foregroundColor(CloisterPalette.moss)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            if !isLast {
                Rectangle().fill(CloisterPalette.divider).frame(height: 0.5)
            }
        }
    }

    private func lastResultCard(species: Species) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CloisterSectionHeader("LATEST CROSS", subtitle: "A new seed has been added to your inventory.")
            HStack(alignment: .top, spacing: 12) {
                PlantIllustration(species: species, stage: .mature, size: 68)
                VStack(alignment: .leading, spacing: 4) {
                    Text(species.name)
                        .font(CloisterFont.display(16, weight: .black))
                        .foregroundColor(CloisterPalette.textPrimary)
                    HStack(spacing: 6) {
                        CloisterBadge(text: species.family.shortName, color: species.family.accentColor)
                        CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                    }
                    Text(species.hint)
                        .font(CloisterFont.body(12))
                        .foregroundColor(CloisterPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TraitGrid(traits: species.traits)
                .padding(.top, 4)
        }
        .cloisterCard()
    }

    private func performCross(aIdx: Int, bIdx: Int) {
        if let hybridId = store.performCross(slotIndexA: aIdx, slotIndexB: bIdx) {
            lastResultId = hybridId
            if let s = HybridCatalog.species(forId: hybridId) {
                lastEvent = "A new hybrid: \(s.name). Added one seed to inventory."
            }
            selectedSlotA = nil
            selectedSlotB = nil
        } else {
            lastEvent = "The cross failed — no actions, or pair is not crossable."
        }
    }
}
