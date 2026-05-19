import SwiftUI

// MARK: - Herbarium tab
struct HerbariumView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var familyFilter: CloisterFamily? = nil
    @State private var rarityFilter: SpecimenRarity? = nil
    @State private var searchText: String = ""
    @State private var showOnlyDiscovered: Bool = false
    @State private var selectedSpeciesId: Int? = nil

    var body: some View {
        ZStack {
            CloisterPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloisterHeader(
                        eyebrow: "THE LOST HERBARIUM",
                        title: "Catalog of Specimens",
                        subtitle: "240 entries. \(store.state.discoveredSpeciesIds.count) discovered. Filter to find what remains."
                    )
                    HStack {
                        TextField("Search...", text: $searchText)
                            .font(CloisterFont.body(13))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(CloisterPalette.surfaceRaised))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CloisterPalette.divider, lineWidth: 1))
                    }

                    filterChips

                    let entries = filtered()
                    Text("\(entries.count) entries")
                        .font(CloisterFont.ui(10, weight: .heavy))
                        .tracking(1.0)
                        .foregroundColor(CloisterPalette.textMuted)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(entries, id: \.id) { species in
                            entryCard(species: species)
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
        }
        .sheet(item: Binding<HerbariumSheetData?>(
            get: { selectedSpeciesId.flatMap { HerbariumSheetData(speciesId: $0) } },
            set: { selectedSpeciesId = $0?.speciesId }
        )) { data in
            HerbariumDetailSheet(speciesId: data.speciesId) { selectedSpeciesId = nil }
                .environmentObject(store)
        }
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("FAMILY")
                    .font(CloisterFont.ui(9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(CloisterPalette.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterChip(title: "All", isSelected: familyFilter == nil, color: CloisterPalette.stone) {
                            familyFilter = nil
                        }
                        ForEach(CloisterFamily.allCases, id: \.self) { f in
                            filterChip(title: f.shortName, isSelected: familyFilter == f, color: f.accentColor) {
                                familyFilter = (familyFilter == f) ? nil : f
                            }
                        }
                    }
                }
            }
            HStack(spacing: 6) {
                Text("RARITY")
                    .font(CloisterFont.ui(9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(CloisterPalette.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterChip(title: "All", isSelected: rarityFilter == nil, color: CloisterPalette.stone) {
                            rarityFilter = nil
                        }
                        ForEach(SpecimenRarity.allCases, id: \.self) { r in
                            filterChip(title: r.rawValue, isSelected: rarityFilter == r, color: r.color) {
                                rarityFilter = (rarityFilter == r) ? nil : r
                            }
                        }
                    }
                }
            }
            Toggle(isOn: $showOnlyDiscovered) {
                Text("Show only discovered")
                    .font(CloisterFont.body(13))
                    .foregroundColor(CloisterPalette.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: CloisterPalette.moss))
        }
    }

    private func filterChip(title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(CloisterFont.ui(11, weight: .bold))
                .foregroundColor(isSelected ? .white : CloisterPalette.textPrimary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    Capsule().fill(isSelected ? color : CloisterPalette.surfaceRaised)
                )
                .overlay(
                    Capsule().stroke(color, lineWidth: 1)
                )
        }
    }

    private func filtered() -> [Species] {
        var list = HybridCatalog.allSpecies
        if let f = familyFilter { list = list.filter { $0.family == f } }
        if let r = rarityFilter { list = list.filter { $0.rarity == r } }
        if showOnlyDiscovered {
            list = list.filter { store.state.discoveredSpeciesIds.contains($0.id) }
        }
        let q = searchText.lowercased()
        if !q.isEmpty {
            list = list.filter { s in
                // Locked entries are only searchable by family/rarity, not name
                if store.state.discoveredSpeciesIds.contains(s.id) {
                    return s.name.lowercased().contains(q)
                } else {
                    return s.family.shortName.lowercased().contains(q) ||
                           s.rarity.rawValue.lowercased().contains(q)
                }
            }
        }
        return list
    }

    private func entryCard(species: Species) -> some View {
        let discovered = store.state.discoveredSpeciesIds.contains(species.id)
        return Button {
            selectedSpeciesId = species.id
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    CloisterBadge(text: "#\(species.id + 1)", color: CloisterPalette.stoneDark)
                    Spacer()
                    if species.isBase {
                        CloisterBadge(text: "BASE", color: CloisterPalette.stone)
                    } else {
                        CloisterBadge(text: "HYBRID", color: CloisterPalette.gilded)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(CloisterPalette.surfaceRaised)
                    if discovered {
                        PlantIllustration(species: species, stage: .flowering, size: 80)
                    } else {
                        ZStack {
                            PlantIllustration(species: species, stage: .mature, size: 80)
                                .opacity(0.18)
                            Text("?")
                                .font(CloisterFont.display(34, weight: .black))
                                .foregroundColor(CloisterPalette.stoneDark)
                        }
                    }
                }
                .frame(height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(CloisterPalette.divider, lineWidth: 1)
                )
                Text(discovered ? species.name : "Unknown specimen")
                    .font(CloisterFont.display(13, weight: .bold))
                    .foregroundColor(CloisterPalette.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    CloisterBadge(text: species.family.shortName, color: species.family.accentColor)
                    if discovered {
                        CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                    } else {
                        CloisterBadge(text: "???", color: CloisterPalette.stoneDark)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CloisterPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CloisterPalette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct HerbariumSheetData: Identifiable {
    let speciesId: Int
    var id: Int { speciesId }
}

struct HerbariumDetailSheet: View {
    let speciesId: Int
    let onClose: () -> Void
    @EnvironmentObject var store: CloisterGameStore

    var body: some View {
        NavigationView {
            ZStack {
                CloisterPageBackground()
                ScrollView {
                    if let species = HybridCatalog.species(forId: speciesId) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Page #\(species.id + 1)")
                                    .font(CloisterFont.ui(10, weight: .heavy))
                                    .tracking(1.2)
                                    .foregroundColor(CloisterPalette.textMuted)
                                Spacer()
                                Button("Close", action: onClose)
                                    .foregroundColor(CloisterPalette.accent)
                            }
                            VStack(spacing: 8) {
                                if store.state.discoveredSpeciesIds.contains(species.id) {
                                    PlantIllustration(species: species, stage: .flowering, size: 160)
                                    Text(species.name)
                                        .font(CloisterFont.display(26, weight: .black))
                                        .foregroundColor(CloisterPalette.textPrimary)
                                        .multilineTextAlignment(.center)
                                } else {
                                    ZStack {
                                        Circle().fill(CloisterPalette.surfaceRaised).frame(width: 160, height: 160)
                                        Text("?").font(CloisterFont.display(80, weight: .black))
                                            .foregroundColor(CloisterPalette.stoneDark)
                                    }
                                    Text("Locked Entry")
                                        .font(CloisterFont.display(20, weight: .black))
                                        .foregroundColor(CloisterPalette.textSecondary)
                                }
                                HStack(spacing: 6) {
                                    CloisterBadge(text: species.family.displayName, color: species.family.accentColor)
                                    CloisterBadge(text: species.rarity.rawValue, color: species.rarity.color)
                                    if !species.isBase {
                                        CloisterBadge(text: "HYBRID", color: CloisterPalette.gilded)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)

                            VStack(alignment: .leading, spacing: 8) {
                                CloisterSectionHeader("HINT")
                                Text(species.hint)
                                    .font(CloisterFont.body(14))
                                    .foregroundColor(CloisterPalette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .cloisterCard()

                            if store.state.discoveredSpeciesIds.contains(species.id) {
                                VStack(alignment: .leading, spacing: 8) {
                                    CloisterSectionHeader("TRAITS")
                                    TraitGrid(traits: species.traits)
                                }
                                .cloisterCard()
                                VStack(alignment: .leading, spacing: 8) {
                                    CloisterSectionHeader("CARE PRESET")
                                    HStack(spacing: 14) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Substrate")
                                                .font(CloisterFont.ui(10, weight: .heavy))
                                                .tracking(0.8)
                                                .foregroundColor(CloisterPalette.textMuted)
                                            HStack(spacing: 6) {
                                                CloisterTraitDot(color: species.care.substrate.color, size: 14)
                                                Text(species.care.substrate.label)
                                                    .font(CloisterFont.ui(13, weight: .semibold))
                                                    .foregroundColor(CloisterPalette.textPrimary)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Light")
                                                .font(CloisterFont.ui(10, weight: .heavy))
                                                .tracking(0.8)
                                                .foregroundColor(CloisterPalette.textMuted)
                                            HStack(spacing: 6) {
                                                CloisterSunShape().stroke(CloisterPalette.gilded, lineWidth: 1.2)
                                                    .frame(width: 16, height: 16)
                                                Text(species.care.light.label)
                                                    .font(CloisterFont.ui(13, weight: .semibold))
                                                    .foregroundColor(CloisterPalette.textPrimary)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Humidity")
                                                .font(CloisterFont.ui(10, weight: .heavy))
                                                .tracking(0.8)
                                                .foregroundColor(CloisterPalette.textMuted)
                                            HStack(spacing: 6) {
                                                CloisterDropShape().fill(CloisterPalette.azureLike)
                                                    .frame(width: 12, height: 16)
                                                Text(species.care.humidity.label)
                                                    .font(CloisterFont.ui(13, weight: .semibold))
                                                    .foregroundColor(CloisterPalette.textPrimary)
                                            }
                                        }
                                    }
                                }
                                .cloisterCard()
                                if let parents = species.parentSpeciesIds {
                                    VStack(alignment: .leading, spacing: 8) {
                                        CloisterSectionHeader("LINEAGE")
                                        ForEach(parents, id: \.self) { pid in
                                            if let p = HybridCatalog.species(forId: pid) {
                                                HStack(spacing: 8) {
                                                    PlantIllustration(species: p, stage: .mature, size: 36)
                                                    Text(p.name)
                                                        .font(CloisterFont.body(13))
                                                        .foregroundColor(CloisterPalette.textPrimary)
                                                    Spacer()
                                                    CloisterBadge(text: p.family.shortName, color: p.family.accentColor)
                                                }
                                            }
                                        }
                                    }
                                    .cloisterCard()
                                }
                            }
                            Spacer(minLength: 30)
                        }
                        .padding(.horizontal, 14).padding(.top, 14)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

extension CloisterPalette {
    static let azureLike = Color(red: 0.36, green: 0.55, blue: 0.72)
}
