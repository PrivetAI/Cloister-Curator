import Foundation

// MARK: - Hybrid catalog
// 160 hybrid entries (ids 80..239) generated deterministically from 80 base parent pairs.
// Each pair yields exactly 2 catalog entries (a "primary" and "alternate" expression),
// for a total of 160. The generation pairs are fixed; trait inheritance uses TraitDominance.
//
// Discovery happens by performing the matching cross in-game; until then entries are locked.

enum HybridCatalog {
    static let hybridSpecies: [Species] = makeHybrids()
    static let allSpecies: [Species] = SpeciesCatalog.baseSpecies + hybridSpecies

    /// 80 fixed parent pairs (parentA, parentB). Chosen to span all families and rarities.
    static let parentPairs: [(Int, Int)] = makeParentPairs()

    /// Look up a species by id.
    static func species(forId id: Int) -> Species? {
        guard id >= 0 && id < allSpecies.count else { return nil }
        return allSpecies[id]
    }

    /// Returns the species id of the hybrid result of crossing two given parent ids,
    /// or nil if no curated hybrid exists for that pair.
    static func hybridResultId(parentA: Int, parentB: Int, deterministicSeed: UInt32) -> Int? {
        let normalized = parentA < parentB ? (parentA, parentB) : (parentB, parentA)
        guard let pairIndex = parentPairs.firstIndex(where: { p in
            let a = min(p.0, p.1)
            let b = max(p.0, p.1)
            return a == normalized.0 && b == normalized.1
        }) else { return nil }
        // Each pair has 2 hybrid entries; deterministic seed picks between them.
        var rng = SeededRNG(seed: deterministicSeed)
        let pick = (rng.rollDouble() < 0.6) ? 0 : 1   // weighted toward first
        return 80 + pairIndex * 2 + pick
    }

    // ---- Helpers ----
    private static func makeParentPairs() -> [(Int, Int)] {
        // 80 pairs hand-shaped to cover variety. Constructed by offsets.
        var pairs: [(Int, Int)] = []
        // Cross-family pairs (mosses x ferns, conifers x flowers, etc.)
        for i in 0..<16 { pairs.append((i, 16 + i)) }       // moss x fern : 16
        for i in 0..<16 { pairs.append((i, 32 + i)) }       // moss x conifer : 16
        for i in 0..<16 { pairs.append((16 + i, 48 + i)) }  // fern x angiosperma : 16
        for i in 0..<16 { pairs.append((32 + i, 48 + i)) }  // conifer x angiosperma : 16
        for i in 0..<16 { pairs.append((48 + i, 64 + i)) }  // angiosperma x carnivora : 16
        return pairs
    }

    private static func makeHybrids() -> [Species] {
        var result: [Species] = []
        let pairs = makeParentPairs()
        let base = SpeciesCatalog.baseSpecies

        // Pre-cached trait order arrays
        let leafOrd = TraitDominance.leafOrder
        let colorOrd = TraitDominance.colorOrder
        let scentOrd = TraitDominance.scentOrder
        let lifeOrd = TraitDominance.lifeOrder
        let frostOrd = TraitDominance.frostOrder
        let droughtOrd = TraitDominance.droughtOrder

        for (pairIdx, pair) in pairs.enumerated() {
            let a = base[pair.0]
            let b = base[pair.1]

            // ---- Primary hybrid (id offset 0): dominant traits ----
            let primaryTraits = TraitBundle(
                leaf: TraitDominance.dominant(a.traits.leaf, b.traits.leaf, order: leafOrd),
                color: TraitDominance.dominant(a.traits.color, b.traits.color, order: colorOrd),
                scent: TraitDominance.dominant(a.traits.scent, b.traits.scent, order: scentOrd),
                lifespan: TraitDominance.dominant(a.traits.lifespan, b.traits.lifespan, order: lifeOrd),
                frost: TraitDominance.dominant(a.traits.frost, b.traits.frost, order: frostOrd),
                drought: TraitDominance.dominant(a.traits.drought, b.traits.drought, order: droughtOrd)
            )

            // ---- Alternate hybrid (id offset 1): mix of recessive+dominant ----
            let altTraits = TraitBundle(
                leaf: TraitDominance.recessive(a.traits.leaf, b.traits.leaf, order: leafOrd),
                color: TraitDominance.recessive(a.traits.color, b.traits.color, order: colorOrd),
                scent: TraitDominance.dominant(a.traits.scent, b.traits.scent, order: scentOrd),
                lifespan: TraitDominance.dominant(a.traits.lifespan, b.traits.lifespan, order: lifeOrd),
                frost: TraitDominance.recessive(a.traits.frost, b.traits.frost, order: frostOrd),
                drought: TraitDominance.dominant(a.traits.drought, b.traits.drought, order: droughtOrd)
            )

            // Inherit family from "dominant" parent (higher rarity wins; tie-break by id).
            let dominantParent: Species = {
                if a.rarity.sortRank > b.rarity.sortRank { return a }
                if a.rarity.sortRank < b.rarity.sortRank { return b }
                return a.id < b.id ? a : b
            }()
            let family = dominantParent.family

            // Combined care preset (average light/humidity, prefer dominant substrate)
            let care = CarePreset(
                substrate: dominantParent.care.substrate,
                light: averageLight(a.care.light, b.care.light),
                humidity: averageHumidity(a.care.humidity, b.care.humidity)
            )

            // Rarity escalation: hybrids are at least uncommon
            let rarity: SpecimenRarity = {
                let parentRanks = max(a.rarity.sortRank, b.rarity.sortRank)
                let base: SpecimenRarity
                switch parentRanks {
                case 0: base = .uncommon
                case 1: base = .uncommon
                case 2: base = .rare
                default: base = .mythic
                }
                return base
            }()
            let altRarity: SpecimenRarity = {
                if rarity == .mythic { return .rare }
                if rarity == .rare { return .rare }
                return .uncommon
            }()

            let primaryName = makeHybridName(a: a, b: b, alt: false, pairIdx: pairIdx)
            let altName = makeHybridName(a: a, b: b, alt: true, pairIdx: pairIdx)
            let primaryHint = makeHybridHint(a: a, b: b, traits: primaryTraits, family: family, alt: false)
            let altHint = makeHybridHint(a: a, b: b, traits: altTraits, family: family, alt: true)

            let primaryId = 80 + pairIdx * 2
            let altId = primaryId + 1

            result.append(Species(
                id: primaryId, name: primaryName, family: family,
                traits: primaryTraits, care: care, rarity: rarity,
                isBase: false, parentSpeciesIds: [a.id, b.id], hint: primaryHint
            ))
            result.append(Species(
                id: altId, name: altName, family: family,
                traits: altTraits, care: care, rarity: altRarity,
                isBase: false, parentSpeciesIds: [a.id, b.id], hint: altHint
            ))
        }
        return result
    }

    private static func averageLight(_ a: LightLevel, _ b: LightLevel) -> LightLevel {
        let avg = (a.rawValue + b.rawValue) / 2
        return LightLevel(rawValue: avg) ?? .bright
    }
    private static func averageHumidity(_ a: HumidityLevel, _ b: HumidityLevel) -> HumidityLevel {
        let avg = (a.rawValue + b.rawValue) / 2
        return HumidityLevel(rawValue: avg) ?? .mild
    }

    /// Compose a name from parent prefixes/suffixes. Deterministic.
    private static func makeHybridName(a: Species, b: Species, alt: Bool, pairIdx: Int) -> String {
        let suffixOptions: [String] = [
            "Chimera", "Hybrid", "Cross", "Reliquia", "Codex", "Mantle",
            "Banner", "Choir", "Veil", "Litany", "Vespers", "Sanctus",
            "Codicil", "Pater", "Mater", "Lectern", "Crucible", "Antiphon"
        ]
        let prefixA = firstWord(of: a.name)
        let prefixB = firstWord(of: b.name)
        let suffix = suffixOptions[(pairIdx + (alt ? 7 : 0)) % suffixOptions.count]
        if alt {
            return "\(prefixB)-\(prefixA) \(suffix)"
        } else {
            return "\(prefixA)-\(prefixB) \(suffix)"
        }
    }
    private static func firstWord(of s: String) -> String {
        return s.split(separator: " ").first.map(String.init) ?? s
    }

    /// Build a riddle-style hint, leaking partial info about the cross.
    private static func makeHybridHint(a: Species, b: Species, traits: TraitBundle, family: CloisterFamily, alt: Bool) -> String {
        let famClue = "a \(family.shortName.lowercased())"
        let leafClue = "with \(traits.leaf.label.lowercased()) leaves"
        let colorClue = "in shades of \(traits.color.label.lowercased())"
        let scentClue: String
        switch traits.scent {
        case .none: scentClue = "carrying no fragrance"
        default: scentClue = "scented of \(traits.scent.label.lowercased())"
        }
        let hintIntro: String
        if alt {
            hintIntro = "Page mentions a child of \(firstWord(of: a.name)) and \(firstWord(of: b.name))"
        } else {
            hintIntro = "Marginalia describes a cross of \(firstWord(of: a.name)) and \(firstWord(of: b.name))"
        }
        return "\(hintIntro): \(famClue) \(leafClue), \(colorClue), \(scentClue)."
    }
}

// MARK: - Cross utility for the player flow
enum CrossEngine {
    /// Returns the discovered species id from the cross given the parents.
    /// Seed is fully commutative in A/B order, so a given pair always yields the same
    /// hybrid id — required for the Lost Herbarium hints to remain solvable.
    static func performCross(parentSpeciesAId: Int, parentSpeciesBId: Int) -> Int? {
        let lo = min(parentSpeciesAId, parentSpeciesBId)
        let hi = max(parentSpeciesAId, parentSpeciesBId)
        let seed = UInt32(truncatingIfNeeded: UInt(lo) &* 1000 &+ UInt(hi))
        return HybridCatalog.hybridResultId(parentA: parentSpeciesAId, parentB: parentSpeciesBId, deterministicSeed: seed)
    }

    /// Compute the "projected" offspring trait distribution for the UI.
    static func projectedOffspring(parentASpecies: Species, parentBSpecies: Species) -> CrossOutcomeProjection {
        return CrossOutcomeProjection(
            leafA: parentASpecies.traits.leaf, leafB: parentBSpecies.traits.leaf,
            colorA: parentASpecies.traits.color, colorB: parentBSpecies.traits.color,
            scentA: parentASpecies.traits.scent, scentB: parentBSpecies.traits.scent,
            lifeA: parentASpecies.traits.lifespan, lifeB: parentBSpecies.traits.lifespan,
            frostA: parentASpecies.traits.frost, frostB: parentBSpecies.traits.frost,
            droughtA: parentASpecies.traits.drought, droughtB: parentBSpecies.traits.drought
        )
    }
}
