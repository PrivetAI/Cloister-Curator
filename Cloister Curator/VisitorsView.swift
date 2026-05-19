import SwiftUI

// MARK: - Visitors tab
struct VisitorsView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var sellingForVisitor: UUID? = nil
    @State private var lastEvent: String? = nil

    var body: some View {
        ZStack {
            CloisterPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloisterHeader(
                        eyebrow: "VISITORS' QUEUE",
                        title: "Today's Callers",
                        subtitle: "Each visitor will pay extra if their preferred trait is met."
                    )
                    if let evt = lastEvent {
                        EventBanner(text: evt) { lastEvent = nil }
                    }
                    if store.state.visitorQueue.isEmpty {
                        Text("No callers today. Try ending the day to draw a new queue.")
                            .font(CloisterFont.body(14))
                            .foregroundColor(CloisterPalette.textSecondary)
                            .cloisterCard()
                    } else {
                        ForEach(store.state.visitorQueue, id: \.id) { visitor in
                            visitorCard(visitor: visitor)
                        }
                    }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
        }
        .sheet(item: Binding<VisitorSellSheetData?>(
            get: { sellingForVisitor.flatMap { VisitorSellSheetData(visitorId: $0) } },
            set: { sellingForVisitor = $0?.visitorId }
        )) { data in
            VisitorSellSheet(visitorId: data.visitorId) { speciesId in
                if let price = store.sellTo(visitorId: data.visitorId, speciesId: speciesId) {
                    if let s = HybridCatalog.species(forId: speciesId) {
                        lastEvent = "Sold \(s.name) for \(price) silver."
                    }
                } else {
                    lastEvent = "Couldn't sell — no actions, or specimen unavailable."
                }
                sellingForVisitor = nil
            } onCancel: {
                sellingForVisitor = nil
            }
            .environmentObject(store)
        }
    }

    private func visitorCard(visitor: QueuedVisitor) -> some View {
        guard let arch = VisitorCatalog.archetype(id: visitor.archetypeId) else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                VisitorAvatar(seed: arch.avatarSeed, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(arch.name)
                        .font(CloisterFont.display(15, weight: .black))
                        .foregroundColor(CloisterPalette.textPrimary)
                    Text(arch.title)
                        .font(CloisterFont.body(12))
                        .foregroundColor(CloisterPalette.textMuted)
                    Text(arch.preferenceText)
                        .font(CloisterFont.body(13))
                        .foregroundColor(CloisterPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        CloisterBadge(text: arch.trait.displayName, color: CloisterPalette.gilded)
                        HStack(spacing: 4) {
                            CloisterCoinView(size: 12)
                            Text("+\(arch.bonusCoins) bonus")
                                .font(CloisterFont.ui(11, weight: .heavy))
                                .foregroundColor(CloisterPalette.textPrimary)
                        }
                    }
                    if visitor.fulfilled {
                        HStack(spacing: 6) {
                            CloisterBadge(text: "FULFILLED", color: CloisterPalette.moss)
                            Text("Paid \(visitor.paidCoins) silver.")
                                .font(CloisterFont.body(12))
                                .foregroundColor(CloisterPalette.textSecondary)
                        }
                    } else {
                        Button {
                            sellingForVisitor = visitor.id
                        } label: {
                            Text("Offer Specimen").cloisterPrimary(enabled: store.state.actionsLeft > 0)
                        }
                        .disabled(store.state.actionsLeft <= 0)
                    }
                }
                Spacer()
            }
            .cloisterCard()
        )
    }
}

// MARK: - Visitor avatar (composed shapes)
struct VisitorAvatar: View {
    let seed: Int
    var size: CGFloat = 64
    var body: some View {
        let robeColor = robeColors[seed % robeColors.count]
        let hatColor = hatColors[(seed / 3) % hatColors.count]
        let trimColor = trimColors[(seed / 5) % trimColors.count]
        return ZStack {
            Circle().fill(CloisterPalette.surfaceRaised)
            // Figure body
            CloisterFigureShape()
                .fill(robeColor)
                .padding(8)
            CloisterFigureShape()
                .stroke(CloisterPalette.ink.opacity(0.7), lineWidth: 0.8)
                .padding(8)
            // Hat
            Rectangle().fill(hatColor)
                .frame(width: size * 0.30, height: size * 0.06)
                .offset(y: -size * 0.30)
            Rectangle().fill(hatColor)
                .frame(width: size * 0.22, height: size * 0.10)
                .offset(y: -size * 0.35)
            // Trim/sash
            Rectangle().fill(trimColor)
                .frame(width: size * 0.05, height: size * 0.45)
                .offset(y: size * 0.05)
            // Border
            Circle().stroke(CloisterPalette.divider, lineWidth: 1)
        }
        .frame(width: size, height: size)
    }
    private var robeColors: [Color] { [
        CloisterPalette.stoneDark, CloisterPalette.mossDark, CloisterPalette.ink,
        CloisterPalette.reliquary, CloisterPalette.gilded, CloisterPalette.parchmentDeep,
        CloisterPalette.moss, CloisterPalette.stone, CloisterPalette.inkSoft
    ]}
    private var hatColors: [Color] { [
        CloisterPalette.ink, CloisterPalette.moss, CloisterPalette.gilded,
        CloisterPalette.reliquaryLight, CloisterPalette.stoneDark
    ]}
    private var trimColors: [Color] { [
        CloisterPalette.gilded, CloisterPalette.reliquary, CloisterPalette.moss,
        CloisterPalette.parchment, CloisterPalette.ink
    ]}
}

private struct VisitorSellSheetData: Identifiable {
    let visitorId: UUID
    var id: UUID { visitorId }
}

struct VisitorSellSheet: View {
    let visitorId: UUID
    let onSell: (Int) -> Void
    let onCancel: () -> Void
    @EnvironmentObject var store: CloisterGameStore
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                CloisterPageBackground()
                VStack(spacing: 0) {
                    HStack {
                        Text("Offer to visitor")
                            .font(CloisterFont.display(20, weight: .bold))
                            .foregroundColor(CloisterPalette.textPrimary)
                        Spacer()
                        Button("Cancel", action: onCancel)
                            .foregroundColor(CloisterPalette.accent)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    if let visitor = store.state.visitorQueue.first(where: { $0.id == visitorId }),
                       let arch = VisitorCatalog.archetype(id: visitor.archetypeId) {
                        HStack(spacing: 8) {
                            VisitorAvatar(seed: arch.avatarSeed, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(arch.name)
                                    .font(CloisterFont.display(14, weight: .bold))
                                    .foregroundColor(CloisterPalette.textPrimary)
                                Text("Wants: \(arch.trait.displayName)")
                                    .font(CloisterFont.body(12))
                                    .foregroundColor(CloisterPalette.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    }
                    TextField("Search specimen...", text: $searchText)
                        .font(CloisterFont.body(13))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(CloisterPalette.surfaceRaised))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(CloisterPalette.divider, lineWidth: 1))
                        .padding(.horizontal, 16)
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredOffers(), id: \.0) { item in
                                if let s = HybridCatalog.species(forId: item.0) {
                                    Button {
                                        onSell(item.0)
                                    } label: {
                                        offerRow(species: s, count: item.1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24).padding(.top, 8)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    private func filteredOffers() -> [(Int, Int)] {
        var list: [(Int, Int)] = []
        var seenSpeciesIds: Set<Int> = []
        for (sid, count) in store.state.seedInventory where count > 0 {
            list.append((sid, count))
            seenSpeciesIds.insert(sid)
        }
        // Also add seeding-stage plants, skipping species already in seed inventory
        // and avoiding duplicate plants of the same species.
        for slot in store.state.slots {
            if let p = slot.plant, p.stage == .seeding, !seenSpeciesIds.contains(p.speciesId) {
                list.append((p.speciesId, 0)) // 0 means "in cloister"
                seenSpeciesIds.insert(p.speciesId)
            }
        }
        list.sort { $0.0 < $1.0 }
        let q = searchText.lowercased()
        if !q.isEmpty {
            list = list.filter {
                if let s = HybridCatalog.species(forId: $0.0) {
                    return s.name.lowercased().contains(q)
                }
                return false
            }
        }
        return list
    }
    private func offerRow(species: Species, count: Int) -> some View {
        HStack(spacing: 10) {
            PlantIllustration(species: species, stage: count > 0 ? .mature : .seeding, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(species.name)
                    .font(CloisterFont.display(14, weight: .bold))
                    .foregroundColor(CloisterPalette.textPrimary)
                HStack(spacing: 4) {
                    CloisterBadge(text: species.family.shortName, color: species.family.accentColor)
                    CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                }
            }
            Spacer()
            if count > 0 {
                Text("Seed x\(count)")
                    .font(CloisterFont.ui(12, weight: .bold))
                    .foregroundColor(CloisterPalette.textMuted)
            } else {
                Text("In cloister")
                    .font(CloisterFont.ui(12, weight: .bold))
                    .foregroundColor(CloisterPalette.gilded)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(CloisterPalette.surfaceRaised))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(CloisterPalette.divider, lineWidth: 1))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return (index >= 0 && index < count) ? self[index] : nil
    }
}
