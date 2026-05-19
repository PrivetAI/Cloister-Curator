import SwiftUI
import Foundation

// MARK: - Family
enum CloisterFamily: String, Codable, CaseIterable, Hashable {
    case bryophyta = "Bryophyta"
    case pteridophyta = "Pteridophyta"
    case coniferae = "Coniferae"
    case angiosperma = "Angiosperma"
    case carnivora = "Carnivora"

    var displayName: String { rawValue }
    var shortName: String {
        switch self {
        case .bryophyta: return "Moss"
        case .pteridophyta: return "Fern"
        case .coniferae: return "Conifer"
        case .angiosperma: return "Bloom"
        case .carnivora: return "Carnivor"
        }
    }
    var accentColor: Color {
        switch self {
        case .bryophyta: return CloisterPalette.mossLight
        case .pteridophyta: return CloisterPalette.moss
        case .coniferae: return CloisterPalette.mossDark
        case .angiosperma: return CloisterPalette.reliquaryLight
        case .carnivora: return CloisterPalette.reliquary
        }
    }
}

// MARK: - Rarity
enum SpecimenRarity: String, Codable, CaseIterable, Comparable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case mythic = "Mythic"

    var sortRank: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .mythic: return 3
        }
    }
    static func < (lhs: SpecimenRarity, rhs: SpecimenRarity) -> Bool {
        return lhs.sortRank < rhs.sortRank
    }
    var basePrice: Int {
        switch self {
        case .common: return 8
        case .uncommon: return 22
        case .rare: return 60
        case .mythic: return 180
        }
    }
    var color: Color {
        switch self {
        case .common: return CloisterPalette.stone
        case .uncommon: return CloisterPalette.mossLight
        case .rare: return CloisterPalette.gilded
        case .mythic: return CloisterPalette.reliquary
        }
    }
}

// MARK: - Six trait categories
enum LeafShape: String, Codable, CaseIterable {
    case lance, ovate, palmate, needle, lobed, ribbon, cordate, trifid
    var label: String { rawValue.capitalized }
}
enum ColorSpectrum: String, Codable, CaseIterable {
    case red, yellow, green, white, violet, azure, amber, rose
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .red: return Color(red: 0.76, green: 0.25, blue: 0.22)
        case .yellow: return Color(red: 0.92, green: 0.78, blue: 0.28)
        case .green: return Color(red: 0.40, green: 0.60, blue: 0.30)
        case .white: return Color(red: 0.95, green: 0.94, blue: 0.88)
        case .violet: return Color(red: 0.50, green: 0.30, blue: 0.62)
        case .azure: return Color(red: 0.36, green: 0.55, blue: 0.72)
        case .amber: return Color(red: 0.85, green: 0.55, blue: 0.22)
        case .rose: return Color(red: 0.88, green: 0.55, blue: 0.62)
        }
    }
}
enum ScentTrait: String, Codable, CaseIterable {
    case citrus, balsam, earthy, honey, smoke, mint, none, musk
    var label: String { rawValue.capitalized }
}
enum LifespanTrait: String, Codable, CaseIterable {
    case ephemeral, seasonal, biennial, perennial, ancient
    var label: String { rawValue.capitalized }
}
enum FrostTolerance: String, Codable, CaseIterable {
    case tender, hardy, glacial
    var label: String { rawValue.capitalized }
}
enum DroughtTolerance: String, Codable, CaseIterable {
    case thirsty, balanced, arid
    var label: String { rawValue.capitalized }
}

// MARK: - Care preset
enum SubstrateType: String, Codable, CaseIterable {
    case loam, peat, sand, clay, gravel, sphagnum, charcoal, leafMold
    var label: String {
        switch self {
        case .loam: return "Loam"
        case .peat: return "Peat"
        case .sand: return "Sand"
        case .clay: return "Clay"
        case .gravel: return "Gravel"
        case .sphagnum: return "Sphagnum"
        case .charcoal: return "Charcoal"
        case .leafMold: return "Leaf Mold"
        }
    }
    var color: Color {
        switch self {
        case .loam: return Color(red: 0.43, green: 0.32, blue: 0.20)
        case .peat: return Color(red: 0.31, green: 0.22, blue: 0.16)
        case .sand: return Color(red: 0.80, green: 0.72, blue: 0.52)
        case .clay: return Color(red: 0.62, green: 0.40, blue: 0.30)
        case .gravel: return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .sphagnum: return Color(red: 0.50, green: 0.62, blue: 0.40)
        case .charcoal: return Color(red: 0.20, green: 0.20, blue: 0.20)
        case .leafMold: return Color(red: 0.55, green: 0.38, blue: 0.20)
        }
    }
}
enum LightLevel: Int, Codable, CaseIterable {
    case deepShade = 0, dappled = 1, bright = 2, fullSun = 3
    var label: String {
        switch self {
        case .deepShade: return "Deep Shade"
        case .dappled: return "Dappled"
        case .bright: return "Bright"
        case .fullSun: return "Full Sun"
        }
    }
}
enum HumidityLevel: Int, Codable, CaseIterable {
    case dry = 0, mild = 1, damp = 2, saturated = 3
    var label: String {
        switch self {
        case .dry: return "Dry"
        case .mild: return "Mild"
        case .damp: return "Damp"
        case .saturated: return "Saturated"
        }
    }
}

struct CarePreset: Codable, Hashable {
    var substrate: SubstrateType
    var light: LightLevel
    var humidity: HumidityLevel
}

// MARK: - Trait bundle
struct TraitBundle: Codable, Hashable {
    var leaf: LeafShape
    var color: ColorSpectrum
    var scent: ScentTrait
    var lifespan: LifespanTrait
    var frost: FrostTolerance
    var drought: DroughtTolerance
}

// MARK: - Species (a record from the herbarium / catalog)
struct Species: Codable, Identifiable, Hashable {
    var id: Int        // 0-79 base, 80-239 hybrids
    var name: String
    var family: CloisterFamily
    var traits: TraitBundle
    var care: CarePreset
    var rarity: SpecimenRarity
    var isBase: Bool   // true for 0-79, false for hybrids
    // For hybrids: which parent ids fit. nil for base species.
    var parentSpeciesIds: [Int]?
    // Hint text (for Lost Herbarium riddles)
    var hint: String
}

// MARK: - Growth stages
enum GrowthStage: Int, Codable, CaseIterable {
    case seed = 0, sprout = 1, sapling = 2, mature = 3, flowering = 4, seeding = 5

    var label: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .sapling: return "Sapling"
        case .mature: return "Mature"
        case .flowering: return "Flowering"
        case .seeding: return "Seeding"
        }
    }
    /// Ticks needed at this stage to advance.
    /// Scaled by 10 so growth/surface multipliers (e.g. +15%) produce fractional gains that
    /// don't get truncated to zero in `endDay`.
    var ticksToAdvance: Int {
        switch self {
        case .seed: return 20
        case .sprout: return 20
        case .sapling: return 30
        case .mature: return 30
        case .flowering: return 20
        case .seeding: return Int.max
        }
    }
    func next() -> GrowthStage {
        let n = min(self.rawValue + 1, GrowthStage.seeding.rawValue)
        return GrowthStage(rawValue: n) ?? .seeding
    }
}

// MARK: - Cultivation surface
enum CultivationSurface: String, Codable, CaseIterable {
    case pot, bed, terrarium
    var label: String { rawValue.capitalized }
    /// Slots per surface instance.
    var slotCount: Int {
        switch self {
        case .pot: return 1
        case .bed: return 3
        case .terrarium: return 1
        }
    }
    var growthMultiplier: Double {
        switch self {
        case .pot: return 1.0
        case .bed: return 1.2
        case .terrarium: return 1.4
        }
    }
}

// MARK: - Plant (a planted instance in the cloister)
struct PlantedSpecimen: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var speciesId: Int
    var stage: GrowthStage = .seed
    var ticksAtStage: Int = 0
    var traits: TraitBundle // copy of species traits, may diverge later for hybrids
    var planted: Bool = true
    var surface: CultivationSurface = .pot
    var careOverride: CarePreset?  // if nil, use species preset
}

// MARK: - Cultivation slots
struct CultivationSlot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var surface: CultivationSurface
    var plant: PlantedSpecimen?
    var unlocked: Bool = true
    var careCorrect: Bool = true
}

// MARK: - Card preview value (used in Punnett-style UI)
struct CrossOutcomeProjection: Hashable {
    var leafA: LeafShape
    var leafB: LeafShape
    var colorA: ColorSpectrum
    var colorB: ColorSpectrum
    var scentA: ScentTrait
    var scentB: ScentTrait
    var lifeA: LifespanTrait
    var lifeB: LifespanTrait
    var frostA: FrostTolerance
    var frostB: FrostTolerance
    var droughtA: DroughtTolerance
    var droughtB: DroughtTolerance
}

// MARK: - Trait dominance utility
enum TraitDominance {
    static let leafOrder: [LeafShape] = [.lance, .needle, .palmate, .lobed, .trifid, .ribbon, .ovate, .cordate]
    static let colorOrder: [ColorSpectrum] = [.red, .violet, .azure, .amber, .yellow, .green, .rose, .white]
    static let scentOrder: [ScentTrait] = [.smoke, .musk, .balsam, .citrus, .mint, .honey, .earthy, .none]
    static let lifeOrder: [LifespanTrait] = [.ancient, .perennial, .biennial, .seasonal, .ephemeral]
    static let frostOrder: [FrostTolerance] = [.glacial, .hardy, .tender]
    static let droughtOrder: [DroughtTolerance] = [.arid, .balanced, .thirsty]

    static func dominant<T: Hashable>(_ a: T, _ b: T, order: [T]) -> T {
        let ai = order.firstIndex(of: a) ?? Int.max
        let bi = order.firstIndex(of: b) ?? Int.max
        return ai <= bi ? a : b
    }
    static func recessive<T: Hashable>(_ a: T, _ b: T, order: [T]) -> T {
        let ai = order.firstIndex(of: a) ?? Int.min
        let bi = order.firstIndex(of: b) ?? Int.min
        return ai <= bi ? b : a
    }
}

// MARK: - Seeded RNG (mulberry32)
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt32
    init(seed: UInt32) { self.state = seed &+ 0x9E3779B9 }
    mutating func next() -> UInt64 {
        let lo = UInt64(nextU32())
        let hi = UInt64(nextU32()) << 32
        return hi | lo
    }
    private mutating func nextU32() -> UInt32 {
        state = state &+ 0x6D2B79F5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= (t &+ ((t ^ (t >> 7)) &* (t | 61)))
        return t ^ (t >> 14)
    }
    mutating func rollDouble() -> Double {
        return Double(nextU32()) / Double(UInt32.max)
    }
}

// MARK: - Visitor
struct VisitorArchetype: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
    var title: String
    var preferenceText: String
    var trait: PreferredTrait
    var bonusCoins: Int
    var avatarSeed: Int
    var description: String
}

// Defines what a visitor wants
enum PreferredTrait: Codable, Hashable {
    case family(CloisterFamily)
    case rarity(SpecimenRarity)
    case color(ColorSpectrum)
    case scent(ScentTrait)
    case leaf(LeafShape)
    case anyMature

    var displayName: String {
        switch self {
        case .family(let f): return "\(f.shortName) family"
        case .rarity(let r): return "\(r.rawValue) tier"
        case .color(let c): return "\(c.label) color"
        case .scent(let s): return "\(s.label) scent"
        case .leaf(let l): return "\(l.label) leaf"
        case .anyMature: return "any mature plant"
        }
    }

    func matches(species: Species) -> Bool {
        switch self {
        case .family(let f): return species.family == f
        case .rarity(let r): return species.rarity == r
        case .color(let c): return species.traits.color == c
        case .scent(let s): return species.traits.scent == s
        case .leaf(let l): return species.traits.leaf == l
        case .anyMature: return true
        }
    }
}

// MARK: - A visitor instance in queue
struct QueuedVisitor: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var archetypeId: Int
    var fulfilled: Bool = false
    var paidCoins: Int = 0
}

// MARK: - Quest
struct Quest: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var brief: String
    var goalText: String
    var requirement: QuestRequirement
    var reward: QuestReward
}
enum QuestRequirement: Codable, Hashable {
    case discoverHybrids(count: Int)
    case discoverFamily(CloisterFamily, count: Int)
    case satisfyVisitors(count: Int)
    case sellRarity(SpecimenRarity, count: Int)
    case accumulateCoins(Int)
    case ownPlantsOfStage(GrowthStage, count: Int)
    case discoverSpecies(speciesId: Int)
}
struct QuestReward: Codable, Hashable {
    var coins: Int
    var favor: Int
    var seeds: [SeedReward]?
}
struct SeedReward: Codable, Hashable {
    var speciesId: Int
    var quantity: Int
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var brief: String
    var requirement: AchievementRequirement
}
enum AchievementRequirement: Codable, Hashable {
    case discoverHybrids(Int)
    case discoverFamily(CloisterFamily, Int)
    case satisfyVisitors(Int)
    case satisfyArchetype(Int)
    case accumulateCoins(Int)
    case ownPlantsOfStage(GrowthStage, Int)
    case completeQuest(Int)
    case ownUpgrade(Int)
}

// MARK: - Monastery upgrade
struct MonasteryUpgrade: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
    var description: String
    var costCoins: Int
    var costFavor: Int
    var effect: UpgradeEffect
}
enum UpgradeEffect: Codable, Hashable {
    case addSlots(surface: CultivationSurface, slots: Int)
    case extraDailyAction
    case unlockSubstrate(SubstrateType)
    case unlockSeed(speciesId: Int)
    case extraJournalSlot
    case visitorBonus(percent: Int)
    case fasterGrowth(percent: Int)
    case favorGain(Int)
    case grantCoins(Int)
}

// MARK: - Compact convenience init for CarePreset
extension CarePreset {
    static let mossy = CarePreset(substrate: .sphagnum, light: .deepShade, humidity: .saturated)
    static let fernShade = CarePreset(substrate: .leafMold, light: .dappled, humidity: .damp)
    static let conifer = CarePreset(substrate: .loam, light: .bright, humidity: .mild)
    static let bloomBright = CarePreset(substrate: .loam, light: .fullSun, humidity: .mild)
    static let arid = CarePreset(substrate: .sand, light: .fullSun, humidity: .dry)
    static let bog = CarePreset(substrate: .peat, light: .bright, humidity: .saturated)
}
