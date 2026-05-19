import Foundation
import SwiftUI
import Combine

// MARK: - Player save state (persisted)
struct CloisterSaveState: Codable {
    var version: Int = 1
    var day: Int = 1
    var actionsLeft: Int = 5
    var maxActionsPerDay: Int = 5
    var coins: Int = 60
    var favor: Int = 0
    var seedInventory: [Int: Int] = [:]   // speciesId -> count
    var substrateInventory: [SubstrateType: Int] = [:]
    var discoveredSpeciesIds: Set<Int> = []
    var slots: [CultivationSlot] = []
    var visitorQueue: [QueuedVisitor] = []
    var visitorsSatisfied: Int = 0
    var visitorsByArchetype: [Int: Int] = [:]
    var sellsByRarity: [String: Int] = [:]
    var ownedUpgradeIds: Set<Int> = []
    var unlockedSubstrates: Set<SubstrateType> = [.loam, .peat, .sand]
    var visitorBonusPercent: Int = 0
    var growthBonusPercent: Int = 0
    var perDayFavorBonus: Int = 0
    var pinnedHintPageId: Int? = nil
    var completedQuestIds: Set<Int> = []
    var unlockedAchievementIds: Set<Int> = []

    static var initial: CloisterSaveState {
        var state = CloisterSaveState()
        // 4 starting pots, with no plants
        state.slots = (0..<4).map { _ in CultivationSlot(surface: .pot, plant: nil) }
        // Starter seed inventory: every base species gets 1, plus 3 extras for commons
        for s in SpeciesCatalog.baseSpecies {
            state.seedInventory[s.id] = (s.rarity == .common) ? 2 : 1
        }
        // Mark all base species as discovered automatically (player starts with the herbarium's base entries)
        state.discoveredSpeciesIds = Set(SpeciesCatalog.baseSpecies.map { $0.id })
        // Starter substrate inventory
        state.substrateInventory[.loam] = 8
        state.substrateInventory[.peat] = 6
        state.substrateInventory[.sand] = 5
        // First-day visitor queue
        state.visitorQueue = VisitorQueueBuilder.buildQueue(forDay: 1)
        return state
    }
}

// MARK: - Backward-compatible decoding
extension CloisterSaveState {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? 1
        self.day = (try? c.decodeIfPresent(Int.self, forKey: .day)) ?? 1
        self.actionsLeft = (try? c.decodeIfPresent(Int.self, forKey: .actionsLeft)) ?? 5
        self.maxActionsPerDay = (try? c.decodeIfPresent(Int.self, forKey: .maxActionsPerDay)) ?? 5
        self.coins = (try? c.decodeIfPresent(Int.self, forKey: .coins)) ?? 60
        self.favor = (try? c.decodeIfPresent(Int.self, forKey: .favor)) ?? 0
        self.seedInventory = (try? c.decodeIfPresent([Int: Int].self, forKey: .seedInventory)) ?? [:]
        self.substrateInventory = (try? c.decodeIfPresent([SubstrateType: Int].self, forKey: .substrateInventory)) ?? [:]
        self.discoveredSpeciesIds = (try? c.decodeIfPresent(Set<Int>.self, forKey: .discoveredSpeciesIds)) ?? []
        self.slots = (try? c.decodeIfPresent([CultivationSlot].self, forKey: .slots)) ?? []
        self.visitorQueue = (try? c.decodeIfPresent([QueuedVisitor].self, forKey: .visitorQueue)) ?? []
        self.visitorsSatisfied = (try? c.decodeIfPresent(Int.self, forKey: .visitorsSatisfied)) ?? 0
        self.visitorsByArchetype = (try? c.decodeIfPresent([Int: Int].self, forKey: .visitorsByArchetype)) ?? [:]
        self.sellsByRarity = (try? c.decodeIfPresent([String: Int].self, forKey: .sellsByRarity)) ?? [:]
        self.ownedUpgradeIds = (try? c.decodeIfPresent(Set<Int>.self, forKey: .ownedUpgradeIds)) ?? []
        self.unlockedSubstrates = (try? c.decodeIfPresent(Set<SubstrateType>.self, forKey: .unlockedSubstrates)) ?? [.loam, .peat, .sand]
        self.visitorBonusPercent = (try? c.decodeIfPresent(Int.self, forKey: .visitorBonusPercent)) ?? 0
        self.growthBonusPercent = (try? c.decodeIfPresent(Int.self, forKey: .growthBonusPercent)) ?? 0
        self.perDayFavorBonus = (try? c.decodeIfPresent(Int.self, forKey: .perDayFavorBonus)) ?? 0
        self.pinnedHintPageId = (try? c.decodeIfPresent(Int.self, forKey: .pinnedHintPageId)) ?? nil
        self.completedQuestIds = (try? c.decodeIfPresent(Set<Int>.self, forKey: .completedQuestIds)) ?? []
        self.unlockedAchievementIds = (try? c.decodeIfPresent(Set<Int>.self, forKey: .unlockedAchievementIds)) ?? []
    }
}

// MARK: - Save handle (UserDefaults-backed)
final class CloisterGameStore: ObservableObject {
    @Published var state: CloisterSaveState
    private let defaults: UserDefaults
    static let stateKey = "cc.state.v1"
    private var saveDebounce: AnyCancellable?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.stateKey),
           let decoded = try? JSONDecoder().decode(CloisterSaveState.self, from: data) {
            self.state = decoded
        } else {
            self.state = .initial
        }
        // Auto-save when state changes (debounced)
        self.saveDebounce = $state
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.persist() }
    }

    func persist() {
        if let encoded = try? JSONEncoder().encode(state) {
            defaults.set(encoded, forKey: Self.stateKey)
        }
    }

    func resetAll() {
        state = .initial
        persist()
    }

    // MARK: - Hint pinning
    func setPinnedHint(pageId: Int?) {
        state.pinnedHintPageId = pageId
    }

    // MARK: - Read derived values
    var availableSlots: [CultivationSlot] { state.slots }
    var totalCapacity: Int { state.slots.count }
    var seedsListSorted: [(Int, Int)] {
        state.seedInventory
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
    }
    var matureSeedingPlants: [(slotIndex: Int, plant: PlantedSpecimen)] {
        var result: [(Int, PlantedSpecimen)] = []
        for (idx, slot) in state.slots.enumerated() {
            if let p = slot.plant, p.stage == .seeding {
                result.append((idx, p))
            }
        }
        return result
    }

    // MARK: - Action economy
    func consumeAction() -> Bool {
        guard state.actionsLeft > 0 else { return false }
        state.actionsLeft -= 1
        return true
    }
    func endDay() {
        // Grow all plants. baseTicks is scaled (10) so growth/surface multipliers
        // produce visible per-stage differences (otherwise +10/15% rounds to zero).
        for i in state.slots.indices {
            guard var plant = state.slots[i].plant else { continue }
            if plant.stage == .seeding { continue }
            let baseTicks = 10
            let growthBonusFactor = 1.0 + Double(state.growthBonusPercent) / 100.0
            let surfaceFactor = state.slots[i].surface.growthMultiplier
            // Apply mismatched-care growth penalty: half-speed when the plant's effective
            // care preset doesn't match the species' preferred preset.
            let careFactor: Double = careMismatchPenalty(for: plant)
            let effectiveTicks = max(1, Int(Double(baseTicks) * growthBonusFactor * surfaceFactor * careFactor))
            plant.ticksAtStage += effectiveTicks
            if plant.ticksAtStage >= plant.stage.ticksToAdvance && plant.stage != .seeding {
                plant.stage = plant.stage.next()
                plant.ticksAtStage = 0
            }
            state.slots[i].plant = plant
        }
        state.day += 1
        state.actionsLeft = state.maxActionsPerDay
        state.favor += state.perDayFavorBonus
        state.visitorQueue = VisitorQueueBuilder.buildQueue(forDay: state.day)
        evaluateQuestsAndAchievements()
    }

    // MARK: - Plant from inventory
    @discardableResult
    func plantSeed(slotIndex: Int, speciesId: Int) -> Bool {
        guard slotIndex >= 0, slotIndex < state.slots.count else { return false }
        guard state.slots[slotIndex].plant == nil else { return false }
        let count = state.seedInventory[speciesId] ?? 0
        guard count > 0 else { return false }
        guard let species = HybridCatalog.species(forId: speciesId) else { return false }
        guard consumeAction() else { return false }
        state.seedInventory[speciesId] = count - 1
        let plant = PlantedSpecimen(
            speciesId: speciesId, stage: .seed, ticksAtStage: 0,
            traits: species.traits, planted: true, surface: state.slots[slotIndex].surface,
            careOverride: nil
        )
        state.slots[slotIndex].plant = plant
        return true
    }

    // MARK: - Cross
    @discardableResult
    func performCross(slotIndexA: Int, slotIndexB: Int) -> Int? {
        guard slotIndexA != slotIndexB else { return nil }
        guard slotIndexA >= 0, slotIndexA < state.slots.count else { return nil }
        guard slotIndexB >= 0, slotIndexB < state.slots.count else { return nil }
        guard let plantA = state.slots[slotIndexA].plant, plantA.stage == .seeding else { return nil }
        guard let plantB = state.slots[slotIndexB].plant, plantB.stage == .seeding else { return nil }
        guard consumeAction() else { return nil }
        let resultId = CrossEngine.performCross(
            parentSpeciesAId: plantA.speciesId,
            parentSpeciesBId: plantB.speciesId
        )
        if let hybridId = resultId {
            // Add a seed to inventory
            state.seedInventory[hybridId, default: 0] += 1
            // Discover
            if !state.discoveredSpeciesIds.contains(hybridId) {
                state.discoveredSpeciesIds.insert(hybridId)
            }
            // Mark both parents as having seeded — convert them back to mature stage (recycle)
            if var pa = state.slots[slotIndexA].plant {
                pa.stage = .mature
                pa.ticksAtStage = 0
                state.slots[slotIndexA].plant = pa
            }
            if var pb = state.slots[slotIndexB].plant {
                pb.stage = .mature
                pb.ticksAtStage = 0
                state.slots[slotIndexB].plant = pb
            }
            evaluateQuestsAndAchievements()
            return hybridId
        }
        return nil
    }

    // MARK: - Harvest (clear slot, return seed)
    @discardableResult
    func harvest(slotIndex: Int) -> Bool {
        guard slotIndex >= 0, slotIndex < state.slots.count else { return false }
        guard let plant = state.slots[slotIndex].plant else { return false }
        guard plant.stage == .seeding else { return false }
        guard consumeAction() else { return false }
        state.seedInventory[plant.speciesId, default: 0] += 2
        state.slots[slotIndex].plant = nil
        return true
    }

    // MARK: - Care (refresh growth)
    @discardableResult
    func careForSlot(slotIndex: Int) -> Bool {
        guard slotIndex >= 0, slotIndex < state.slots.count else { return false }
        guard let plant = state.slots[slotIndex].plant else { return false }
        // Seeding-stage plants gain nothing from care: don't waste the action.
        guard plant.stage != .seeding else { return false }
        guard consumeAction() else { return false }
        if var p = state.slots[slotIndex].plant {
            // Scaled with new tick system; one care action ~= one extra day at base growth.
            p.ticksAtStage += 10
            if p.ticksAtStage >= p.stage.ticksToAdvance && p.stage != .seeding {
                p.stage = p.stage.next()
                p.ticksAtStage = 0
            }
            state.slots[slotIndex].plant = p
        }
        return true
    }

    // MARK: - Care mismatch penalty (H-2)
    /// Returns 1.0 when the plant's effective care matches the species preset, else 0.5
    /// (half-speed growth). Care is "mismatched" when a `careOverride` exists and any of
    /// substrate/light/humidity differs from the species' preferred preset.
    private func careMismatchPenalty(for plant: PlantedSpecimen) -> Double {
        guard let override = plant.careOverride,
              let species = HybridCatalog.species(forId: plant.speciesId) else {
            return 1.0
        }
        if override.substrate == species.care.substrate
            && override.light == species.care.light
            && override.humidity == species.care.humidity {
            return 1.0
        }
        return 0.5
    }

    // MARK: - Selling to visitors
    @discardableResult
    func sellTo(visitorId: UUID, speciesId: Int) -> Int? {
        guard let visitorIndex = state.visitorQueue.firstIndex(where: { $0.id == visitorId }) else { return nil }
        let visitor = state.visitorQueue[visitorIndex]
        guard !visitor.fulfilled else { return nil }
        guard let archetype = VisitorCatalog.archetype(id: visitor.archetypeId) else { return nil }
        guard let species = HybridCatalog.species(forId: speciesId) else { return nil }
        // Pre-validate: locate seed-stock source OR a seeding-stage plant — but DO NOT mutate yet.
        let hasSeedStock = (state.seedInventory[speciesId] ?? 0) > 0
        let seedingSlotIndex: Int? = state.slots.firstIndex(where: {
            $0.plant?.speciesId == speciesId && $0.plant?.stage == .seeding
        })
        guard hasSeedStock || seedingSlotIndex != nil else { return nil }
        // Consume action FIRST so we never destroy inventory when no action is available.
        guard consumeAction() else { return nil }
        // Now perform mutations.
        if hasSeedStock {
            state.seedInventory[speciesId] = (state.seedInventory[speciesId] ?? 0) - 1
        } else if let idx = seedingSlotIndex {
            state.slots[idx].plant = nil
        }
        // Compute price
        var price = species.rarity.basePrice
        if archetype.trait.matches(species: species) {
            price += archetype.bonusCoins
        }
        // Bonus from upgrades
        if state.visitorBonusPercent > 0 {
            price = price * (100 + state.visitorBonusPercent) / 100
        }
        // Apply
        state.coins += price
        var fulfilled = state.visitorQueue[visitorIndex]
        fulfilled.fulfilled = true
        fulfilled.paidCoins = price
        state.visitorQueue[visitorIndex] = fulfilled
        state.visitorsSatisfied += 1
        state.visitorsByArchetype[archetype.id, default: 0] += 1
        state.sellsByRarity[species.rarity.rawValue, default: 0] += 1
        evaluateQuestsAndAchievements()
        return price
    }

    // MARK: - Upgrades
    @discardableResult
    func purchaseUpgrade(_ upgrade: MonasteryUpgrade) -> Bool {
        guard !state.ownedUpgradeIds.contains(upgrade.id) else { return false }
        guard state.coins >= upgrade.costCoins else { return false }
        guard state.favor >= upgrade.costFavor else { return false }
        state.coins -= upgrade.costCoins
        state.favor -= upgrade.costFavor
        state.ownedUpgradeIds.insert(upgrade.id)
        switch upgrade.effect {
        case .addSlots(let surface, let n):
            for _ in 0..<n {
                state.slots.append(CultivationSlot(surface: surface, plant: nil))
            }
        case .extraDailyAction:
            state.maxActionsPerDay += 1
            state.actionsLeft += 1
        case .unlockSubstrate(let s):
            state.unlockedSubstrates.insert(s)
            state.substrateInventory[s, default: 0] += 4
        case .unlockSeed(let speciesId):
            state.seedInventory[speciesId, default: 0] += 2
        case .extraJournalSlot:
            break
        case .visitorBonus(let pct):
            state.visitorBonusPercent += pct
        case .fasterGrowth(let pct):
            state.growthBonusPercent += pct
        case .favorGain(let f):
            state.perDayFavorBonus += f
        case .grantCoins(let c):
            state.coins += c
        }
        evaluateQuestsAndAchievements()
        return true
    }

    // MARK: - Quest/Achievement evaluation
    func evaluateQuestsAndAchievements() {
        // Quests
        for quest in QuestCatalog.quests where !state.completedQuestIds.contains(quest.id) {
            if questSatisfied(quest.requirement) {
                state.completedQuestIds.insert(quest.id)
                state.coins += quest.reward.coins
                state.favor += quest.reward.favor
                if let seeds = quest.reward.seeds {
                    for s in seeds {
                        state.seedInventory[s.speciesId, default: 0] += s.quantity
                    }
                }
            }
        }
        // Achievements
        for ach in AchievementCatalog.achievements where !state.unlockedAchievementIds.contains(ach.id) {
            if achievementSatisfied(ach.requirement) {
                state.unlockedAchievementIds.insert(ach.id)
            }
        }
    }
    private func questSatisfied(_ req: QuestRequirement) -> Bool {
        switch req {
        case .discoverHybrids(let n):
            return state.discoveredSpeciesIds.filter { $0 >= 80 }.count >= n
        case .discoverFamily(let f, let n):
            // Count only HYBRID discoveries (id >= 80). Base species are pre-discovered, so
            // counting them would auto-complete these goals at game start.
            return state.discoveredSpeciesIds.filter { id in
                guard id >= 80 else { return false }
                if let s = HybridCatalog.species(forId: id) { return s.family == f }
                return false
            }.count >= n
        case .satisfyVisitors(let n):
            return state.visitorsSatisfied >= n
        case .sellRarity(let r, let n):
            return (state.sellsByRarity[r.rawValue] ?? 0) >= n
        case .accumulateCoins(let n):
            return state.coins >= n
        case .ownPlantsOfStage(let stg, let n):
            return state.slots.compactMap { $0.plant }.filter { $0.stage == stg }.count >= n
        case .discoverSpecies(let id):
            return state.discoveredSpeciesIds.contains(id)
        }
    }
    private func achievementSatisfied(_ req: AchievementRequirement) -> Bool {
        switch req {
        case .discoverHybrids(let n):
            return state.discoveredSpeciesIds.filter { $0 >= 80 }.count >= n
        case .discoverFamily(let f, let n):
            // Same rationale as questSatisfied: only HYBRID discoveries count.
            return state.discoveredSpeciesIds.filter { id in
                guard id >= 80 else { return false }
                if let s = HybridCatalog.species(forId: id) { return s.family == f }
                return false
            }.count >= n
        case .satisfyVisitors(let n):
            return state.visitorsSatisfied >= n
        case .satisfyArchetype(let id):
            return (state.visitorsByArchetype[id] ?? 0) >= 1
        case .accumulateCoins(let n):
            return state.coins >= n
        case .ownPlantsOfStage(let stg, let n):
            return state.slots.compactMap { $0.plant }.filter { $0.stage == stg }.count >= n
        case .completeQuest(let n):
            return state.completedQuestIds.count >= n
        case .ownUpgrade(let n):
            return state.ownedUpgradeIds.count >= n
        }
    }
}
