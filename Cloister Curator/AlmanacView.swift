import SwiftUI

// MARK: - Almanac tab — meta progression (quests / achievements / upgrades / hints)
struct AlmanacView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var selectedPage: AlmanacPage = .quests

    enum AlmanacPage: String, CaseIterable, Identifiable {
        case quests = "Quests"
        case achievements = "Honors"
        case upgrades = "Upgrades"
        case hints = "Lost Pages"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            CloisterPageBackground()
            VStack(spacing: 0) {
                CloisterHeader(
                    eyebrow: "ALMANAC",
                    title: "The Prior's Almanac",
                    subtitle: "Track quests, monastery upgrades, honors, and the riddling pages of the Lost Herbarium."
                )
                .padding(.horizontal, 14)
                .padding(.top, 14)

                pageSelector
                    .padding(.horizontal, 14).padding(.vertical, 10)

                ScrollView {
                    Group {
                        switch selectedPage {
                        case .quests: questsPage
                        case .achievements: achievementsPage
                        case .upgrades: upgradesPage
                        case .hints: hintsPage
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 30)
                }
            }
        }
    }

    private var pageSelector: some View {
        HStack(spacing: 6) {
            ForEach(AlmanacPage.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    Text(page.rawValue)
                        .font(CloisterFont.ui(12, weight: .heavy))
                        .foregroundColor(selectedPage == page ? .white : CloisterPalette.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(
                            Capsule().fill(selectedPage == page ? CloisterPalette.moss : CloisterPalette.surfaceRaised)
                        )
                        .overlay(
                            Capsule().stroke(CloisterPalette.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Quests
    private var questsPage: some View {
        VStack(spacing: 12) {
            ForEach(QuestCatalog.quests, id: \.id) { quest in
                questCard(quest: quest)
            }
        }
    }
    private func questCard(quest: Quest) -> some View {
        let completed = store.state.completedQuestIds.contains(quest.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(quest.title)
                    .font(CloisterFont.display(15, weight: .black))
                    .foregroundColor(CloisterPalette.textPrimary)
                Spacer()
                if completed {
                    CloisterBadge(text: "DONE", color: CloisterPalette.moss)
                } else {
                    CloisterBadge(text: "ACTIVE", color: CloisterPalette.gilded)
                }
            }
            Text(quest.brief)
                .font(CloisterFont.body(13))
                .foregroundColor(CloisterPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                CloisterBadge(text: "GOAL", color: CloisterPalette.stoneDark)
                Text(quest.goalText)
                    .font(CloisterFont.body(12))
                    .foregroundColor(CloisterPalette.textPrimary)
            }
            HStack(spacing: 8) {
                CloisterBadge(text: "REWARD", color: CloisterPalette.gilded)
                HStack(spacing: 4) {
                    CloisterCoinView(size: 12)
                    Text("+\(quest.reward.coins)")
                        .font(CloisterFont.ui(12, weight: .bold))
                        .foregroundColor(CloisterPalette.textPrimary)
                }
                HStack(spacing: 4) {
                    CloisterFlower(petals: 5, petalColor: CloisterPalette.reliquaryLight, centerColor: CloisterPalette.reliquary)
                        .frame(width: 12, height: 12)
                    Text("+\(quest.reward.favor)")
                        .font(CloisterFont.ui(12, weight: .bold))
                        .foregroundColor(CloisterPalette.textPrimary)
                }
                if let seeds = quest.reward.seeds {
                    Text("+\(seeds.reduce(0) { $0 + $1.quantity }) seeds")
                        .font(CloisterFont.ui(12, weight: .bold))
                        .foregroundColor(CloisterPalette.textPrimary)
                }
            }
        }
        .cloisterCard()
    }

    // MARK: - Achievements
    private var achievementsPage: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(AchievementCatalog.achievements, id: \.id) { ach in
                achievementCard(ach: ach)
            }
        }
    }
    private func achievementCard(ach: Achievement) -> some View {
        let unlocked = store.state.unlockedAchievementIds.contains(ach.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle().fill(unlocked ? CloisterPalette.gilded : CloisterPalette.stoneLight)
                    CloisterCornerOrnament()
                        .stroke(unlocked ? CloisterPalette.parchmentDeep : CloisterPalette.textMuted, lineWidth: 1)
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(-45))
                }
                .frame(width: 26, height: 26)
                Spacer()
                if unlocked {
                    CloisterBadge(text: "EARNED", color: CloisterPalette.moss)
                } else {
                    CloisterBadge(text: "LOCKED", color: CloisterPalette.stone)
                }
            }
            Text(ach.title)
                .font(CloisterFont.display(13, weight: .bold))
                .foregroundColor(CloisterPalette.textPrimary)
                .lineLimit(2)
            Text(ach.brief)
                .font(CloisterFont.body(11))
                .foregroundColor(CloisterPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cloisterCard(padding: 10, corner: 12)
    }

    // MARK: - Upgrades
    private var upgradesPage: some View {
        VStack(spacing: 12) {
            ForEach(UpgradeCatalog.upgrades, id: \.id) { up in
                upgradeCard(upgrade: up)
            }
        }
    }
    private func upgradeCard(upgrade: MonasteryUpgrade) -> some View {
        let owned = store.state.ownedUpgradeIds.contains(upgrade.id)
        let canAfford = store.state.coins >= upgrade.costCoins && store.state.favor >= upgrade.costFavor
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(upgrade.name)
                    .font(CloisterFont.display(15, weight: .black))
                    .foregroundColor(CloisterPalette.textPrimary)
                Spacer()
                if owned {
                    CloisterBadge(text: "OWNED", color: CloisterPalette.moss)
                }
            }
            Text(upgrade.description)
                .font(CloisterFont.body(13))
                .foregroundColor(CloisterPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    CloisterCoinView(size: 12)
                    Text("\(upgrade.costCoins)")
                        .font(CloisterFont.ui(12, weight: .bold))
                        .foregroundColor(canAfford ? CloisterPalette.textPrimary : CloisterPalette.danger)
                }
                HStack(spacing: 4) {
                    CloisterFlower(petals: 5, petalColor: CloisterPalette.reliquaryLight, centerColor: CloisterPalette.reliquary)
                        .frame(width: 12, height: 12)
                    Text("\(upgrade.costFavor)")
                        .font(CloisterFont.ui(12, weight: .bold))
                        .foregroundColor(canAfford ? CloisterPalette.textPrimary : CloisterPalette.danger)
                }
                Spacer()
                if !owned {
                    Button {
                        _ = store.purchaseUpgrade(upgrade)
                    } label: {
                        Text("Purchase").cloisterPrimary(enabled: canAfford)
                    }
                    .disabled(!canAfford)
                }
            }
        }
        .cloisterCard()
    }

    // MARK: - Hints (Lost Herbarium pages)
    private var hintsPage: some View {
        VStack(spacing: 12) {
            Text("Riddling pages from the Lost Herbarium. Pin a page; the cross to discover the referenced species will be remembered.")
                .font(CloisterFont.body(13))
                .foregroundColor(CloisterPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .cloisterCard()

            ForEach(HintCatalog.pages, id: \.id) { page in
                hintCard(page: page)
            }
        }
    }
    private func hintCard(page: HintPage) -> some View {
        let isPinned = store.state.pinnedHintPageId == page.id
        let discovered = store.state.discoveredSpeciesIds.contains(page.referencedHybridId)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Page \(page.pageNumber)")
                    .font(CloisterFont.ui(10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(CloisterPalette.textMuted)
                Spacer()
                if discovered {
                    CloisterBadge(text: "FOUND", color: CloisterPalette.moss)
                } else if isPinned {
                    CloisterBadge(text: "PINNED", color: CloisterPalette.gilded)
                }
            }
            Text(page.text)
                .font(CloisterFont.body(14))
                .foregroundColor(CloisterPalette.textPrimary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button {
                    if isPinned {
                        store.setPinnedHint(pageId: nil)
                    } else {
                        store.setPinnedHint(pageId: page.id)
                    }
                } label: {
                    Text(isPinned ? "Unpin" : "Pin").cloisterSecondary()
                }
                Spacer()
            }
        }
        .cloisterCard()
    }
}
