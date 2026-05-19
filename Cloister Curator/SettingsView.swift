import SwiftUI

struct CloisterSettingsView: View {
    @EnvironmentObject var store: CloisterGameStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            CloisterPageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Settings")
                            .font(CloisterFont.display(28, weight: .black))
                            .foregroundColor(CloisterPalette.textPrimary)
                        Spacer()
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Done")
                                .cloisterSecondary()
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16)

                    SettingsCard(title: "About") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cloister Curator")
                                .font(CloisterFont.display(18, weight: .black))
                                .foregroundColor(CloisterPalette.textPrimary)
                            Text("Cultivate, cross-pollinate, and catalog 240 specimens to restore the Lost Herbarium of the monastery.")
                                .font(CloisterFont.body(14))
                                .foregroundColor(CloisterPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SettingsCard(title: "Statistics") {
                        VStack(alignment: .leading, spacing: 6) {
                            statRow("Current day", "\(store.state.day)")
                            statRow("Coins on hand", "\(store.state.coins)")
                            statRow("Cloister favor", "\(store.state.favor)")
                            statRow("Plants in care", "\(store.state.slots.compactMap { $0.plant }.count) / \(store.state.slots.count)")
                            statRow("Species discovered", "\(store.state.discoveredSpeciesIds.count) / \(HybridCatalog.allSpecies.count)")
                            statRow("Hybrids discovered", "\(store.state.discoveredSpeciesIds.filter { $0 >= 80 }.count) / 160")
                            statRow("Visitors satisfied", "\(store.state.visitorsSatisfied)")
                            statRow("Quests completed", "\(store.state.completedQuestIds.count) / \(QuestCatalog.quests.count)")
                            statRow("Achievements", "\(store.state.unlockedAchievementIds.count) / \(AchievementCatalog.achievements.count)")
                            statRow("Upgrades", "\(store.state.ownedUpgradeIds.count) / \(UpgradeCatalog.upgrades.count)")
                        }
                    }

                    SettingsCard(title: "Storage") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Game data is stored locally on your device. No accounts, no networks.")
                                .font(CloisterFont.body(13))
                                .foregroundColor(CloisterPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                showResetConfirm = true
                            } label: {
                                Text("Reset Cloister")
                                    .font(CloisterFont.ui(14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(CloisterPalette.reliquary)
                                    )
                            }
                            if showResetConfirm {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("This will erase all progress. Continue?")
                                        .font(CloisterFont.body(13))
                                        .foregroundColor(CloisterPalette.textSecondary)
                                    HStack(spacing: 8) {
                                        Button {
                                            store.resetAll()
                                            showResetConfirm = false
                                        } label: {
                                            Text("Erase")
                                                .font(CloisterFont.ui(13, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12).padding(.vertical, 8)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(CloisterPalette.reliquary))
                                        }
                                        Button {
                                            showResetConfirm = false
                                        } label: {
                                            Text("Cancel").cloisterSecondary()
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }

                    SettingsCard(title: "Privacy") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This application uses no external services and stores nothing off-device.")
                                .font(CloisterFont.body(13))
                                .foregroundColor(CloisterPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                showPrivacy = true
                            } label: {
                                Text("Privacy Policy").cloisterSecondary()
                            }
                        }
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationView {
                CloisterWebPanel(urlString: "https://cloistercurator.org/click.php")
                    .navigationBarTitle("Privacy Policy", displayMode: .inline)
                    .navigationBarItems(trailing: Button("Done") {
                        showPrivacy = false
                    })
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func statRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(CloisterFont.body(13))
                .foregroundColor(CloisterPalette.textSecondary)
            Spacer()
            Text(v)
                .font(CloisterFont.ui(13, weight: .bold))
                .foregroundColor(CloisterPalette.textPrimary)
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CloisterSectionHeader(title)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cloisterCard()
        .padding(.horizontal, 18)
    }
}
