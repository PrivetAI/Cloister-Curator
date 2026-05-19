import SwiftUI

// MARK: - Cloister tab: the working garden
struct CloisterYardView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var plantingSlotIndex: Int? = nil
    @State private var lastEvent: String? = nil

    var body: some View {
        ZStack {
            CloisterPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloisterHeader(
                        eyebrow: "THE CLOISTER YARD",
                        title: "Tend the Garden",
                        subtitle: "Plant seeds, care for specimens, and harvest those that have set seed."
                    )

                    if let evt = lastEvent {
                        EventBanner(text: evt) { lastEvent = nil }
                    }

                    actionsBar

                    if store.state.slots.isEmpty {
                        Text("No cultivation surfaces yet. Visit the Almanac to purchase your first pot.")
                            .font(CloisterFont.body(14))
                            .foregroundColor(CloisterPalette.textSecondary)
                            .cloisterCard()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(Array(store.state.slots.enumerated()), id: \.offset) { idx, slot in
                                slotCard(idx: idx, slot: slot)
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
        }
        .sheet(item: Binding<PlantingSheetData?>(
            get: { plantingSlotIndex.flatMap { PlantingSheetData(slotIndex: $0) } },
            set: { plantingSlotIndex = $0?.slotIndex }
        )) { data in
            PlantingSheet(slotIndex: data.slotIndex) { speciesId in
                if let s = HybridCatalog.species(forId: speciesId) {
                    if store.plantSeed(slotIndex: data.slotIndex, speciesId: speciesId) {
                        lastEvent = "Planted \(s.name) in slot \(data.slotIndex + 1)."
                    } else {
                        lastEvent = "Cannot plant: no actions remaining."
                    }
                }
                plantingSlotIndex = nil
            } onCancel: {
                plantingSlotIndex = nil
            }
            .environmentObject(store)
        }
    }

    private var actionsBar: some View {
        HStack(spacing: 10) {
            Button {
                store.endDay()
                lastEvent = "Day \(store.state.day - 1) ended. The cloister hums into day \(store.state.day)."
            } label: {
                HStack(spacing: 6) {
                    CloisterHourglassShape()
                        .stroke(CloisterPalette.parchment, lineWidth: 1.4)
                        .frame(width: 14, height: 14)
                    Text("End Day")
                }
                .cloisterPrimary()
            }
            Spacer()
            HStack(spacing: 6) {
                CloisterCoinView(size: 14)
                Text("\(store.state.coins)")
                    .font(CloisterFont.ui(13, weight: .bold))
                    .foregroundColor(CloisterPalette.textPrimary)
            }
            HStack(spacing: 6) {
                CloisterHourglassShape()
                    .stroke(CloisterPalette.moss, lineWidth: 1.4)
                    .frame(width: 14, height: 14)
                Text("\(store.state.actionsLeft) actions")
                    .font(CloisterFont.ui(13, weight: .bold))
                    .foregroundColor(CloisterPalette.textPrimary)
            }
        }
        .cloisterCard(padding: 10, corner: 12)
    }

    private func slotCard(idx: Int, slot: CultivationSlot) -> some View {
        let surfaceLabel = slot.surface.label
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Slot \(idx + 1)")
                    .font(CloisterFont.ui(10, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(CloisterPalette.textMuted)
                Spacer()
                CloisterBadge(text: surfaceLabel.uppercased(), color: CloisterPalette.moss)
            }
            ZStack {
                surfaceBackground(for: slot.surface)
                if let plant = slot.plant, let species = HybridCatalog.species(forId: plant.speciesId) {
                    PlantIllustration(species: species, stage: plant.stage, size: 92)
                } else {
                    VStack(spacing: 4) {
                        CloisterEmptySlotShape()
                            .stroke(CloisterPalette.divider, style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                            .frame(height: 56)
                        Text("Empty")
                            .font(CloisterFont.body(11))
                            .foregroundColor(CloisterPalette.textMuted)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .frame(height: 110)

            if let plant = slot.plant, let species = HybridCatalog.species(forId: plant.speciesId) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(species.name)
                        .font(CloisterFont.display(13, weight: .bold))
                        .foregroundColor(CloisterPalette.textPrimary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        CloisterBadge(text: plant.stage.label, color: CloisterPalette.gilded)
                        CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                    }
                    let frac = plant.stage == .seeding ? 1.0 :
                        Double(plant.ticksAtStage) / Double(max(1, plant.stage.ticksToAdvance))
                    CloisterProgressBar(progress: frac)
                        .padding(.top, 2)
                    HStack(spacing: 6) {
                        // Care is meaningless once a plant has set seed — disable to avoid wasting an action.
                        if plant.stage != .seeding {
                            Button {
                                if store.careForSlot(slotIndex: idx) {
                                    lastEvent = "Cared for \(species.name)."
                                } else {
                                    lastEvent = "Cannot care: no actions remaining."
                                }
                            } label: {
                                Text("Care").cloisterSecondary()
                            }
                        }
                        if plant.stage == .seeding {
                            Button {
                                if store.harvest(slotIndex: idx) {
                                    lastEvent = "Harvested seed from \(species.name)."
                                } else {
                                    lastEvent = "Cannot harvest now."
                                }
                            } label: {
                                Text("Harvest").cloisterPrimary()
                            }
                        }
                    }
                }
            } else {
                Button {
                    plantingSlotIndex = idx
                } label: {
                    Text("Plant")
                        .cloisterPrimary()
                }
                .padding(.top, 4)
            }
        }
        .cloisterCard(padding: 10, corner: 12)
    }

    @ViewBuilder
    private func surfaceBackground(for surface: CultivationSurface) -> some View {
        let pad: CGFloat = 6
        switch surface {
        case .pot:
            CloisterPotShape()
                .fill(CloisterPalette.clay)
                .padding(pad)
                .overlay(
                    CloisterPotShape()
                        .stroke(CloisterPalette.ink, lineWidth: 1)
                        .padding(pad)
                )
        case .bed:
            CloisterBedShape()
                .fill(CloisterPalette.peat)
                .padding(pad)
                .overlay(
                    CloisterBedShape()
                        .stroke(CloisterPalette.ink, lineWidth: 1)
                        .padding(pad)
                )
        case .terrarium:
            CloisterTerrariumShape()
                .fill(CloisterPalette.glass)
                .padding(pad)
                .overlay(
                    CloisterTerrariumShape()
                        .stroke(CloisterPalette.ink, lineWidth: 1)
                        .padding(pad)
                )
        }
    }
}

private struct PlantingSheetData: Identifiable {
    let slotIndex: Int
    var id: Int { slotIndex }
}

struct PlantingSheet: View {
    let slotIndex: Int
    let onPick: (Int) -> Void
    let onCancel: () -> Void
    @EnvironmentObject var store: CloisterGameStore
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                CloisterPageBackground()
                VStack(spacing: 0) {
                    HStack {
                        Text("Plant in slot \(slotIndex + 1)")
                            .font(CloisterFont.display(20, weight: .bold))
                            .foregroundColor(CloisterPalette.textPrimary)
                        Spacer()
                        Button("Cancel", action: onCancel)
                            .foregroundColor(CloisterPalette.accent)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    HStack {
                        TextField("Search by name...", text: $searchText)
                            .font(CloisterFont.body(14))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(CloisterPalette.surfaceRaised))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CloisterPalette.divider, lineWidth: 1))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSeeds(), id: \.0) { item in
                                let (speciesId, count) = item
                                if let species = HybridCatalog.species(forId: speciesId) {
                                    Button {
                                        onPick(speciesId)
                                    } label: {
                                        HStack(spacing: 10) {
                                            PlantIllustration(species: species, stage: .mature, size: 42)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(species.name)
                                                    .font(CloisterFont.display(14, weight: .bold))
                                                    .foregroundColor(CloisterPalette.textPrimary)
                                                HStack(spacing: 6) {
                                                    CloisterBadge(text: species.family.shortName, color: species.family.accentColor)
                                                    CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                                                }
                                            }
                                            Spacer()
                                            Text("x\(count)")
                                                .font(CloisterFont.ui(13, weight: .bold))
                                                .foregroundColor(CloisterPalette.textSecondary)
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(CloisterPalette.surfaceRaised)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(CloisterPalette.divider, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    private func filteredSeeds() -> [(Int, Int)] {
        let q = searchText.lowercased()
        return store.seedsListSorted.filter { item in
            guard q.isEmpty == false else { return true }
            if let s = HybridCatalog.species(forId: item.0) {
                return s.name.lowercased().contains(q) || s.family.shortName.lowercased().contains(q)
            }
            return false
        }
    }
}

// MARK: - Header/banner
struct CloisterHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(CloisterFont.ui(10, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(CloisterPalette.textMuted)
            Text(title)
                .font(CloisterFont.display(26, weight: .black))
                .foregroundColor(CloisterPalette.textPrimary)
            Text(subtitle)
                .font(CloisterFont.body(14))
                .foregroundColor(CloisterPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EventBanner: View {
    let text: String
    let onDismiss: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle().fill(CloisterPalette.gilded)
                Text("!")
                    .font(CloisterFont.display(14, weight: .black))
                    .foregroundColor(CloisterPalette.parchmentDeep)
            }
            .frame(width: 22, height: 22)
            Text(text)
                .font(CloisterFont.body(13))
                .foregroundColor(CloisterPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Text("×")
                    .font(CloisterFont.display(20, weight: .bold))
                    .foregroundColor(CloisterPalette.textMuted)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(CloisterPalette.gildedLight.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(CloisterPalette.gilded, lineWidth: 1)
        )
    }
}

// MARK: - Extra palette helpers needed
extension CloisterPalette {
    static let clay = Color(red: 0.62, green: 0.38, blue: 0.27)
    static let peat = Color(red: 0.41, green: 0.27, blue: 0.18)
    static let glass = Color(red: 0.85, green: 0.91, blue: 0.92).opacity(0.55)
}
