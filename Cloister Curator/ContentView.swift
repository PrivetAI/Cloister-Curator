import SwiftUI

// MARK: - Root view with custom HStack tab bar
struct ContentView: View {
    @EnvironmentObject var store: CloisterGameStore
    @State private var selectedTab: Int = 0
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Status bar (coins, favor, day, actions)
                CloisterStatusBar(showSettings: $showSettings)
                Divider().background(CloisterPalette.divider)

                // Tab content
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView {
                            CloisterYardView()
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView {
                            CrossingChamberView()
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView {
                            HerbariumView()
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView {
                            VisitorsView()
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 4:
                        NavigationView {
                            AlmanacView()
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CloisterPageBackground().ignoresSafeArea())

                // Custom tab bar
                CloisterTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showSettings) {
            CloisterSettingsView()
                .environmentObject(store)
        }
    }
}

// MARK: - Status bar at top of root
struct CloisterStatusBar: View {
    @EnvironmentObject var store: CloisterGameStore
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 14) {
            CloisterStatPill(icon: AnyView(
                CloisterCoinView(size: 14)
            ), value: "\(store.state.coins)", color: CloisterPalette.gilded)
            CloisterStatPill(icon: AnyView(
                CloisterFlower(petals: 5, petalColor: CloisterPalette.reliquaryLight, centerColor: CloisterPalette.reliquary)
                    .frame(width: 14, height: 14)
            ), value: "\(store.state.favor)", color: CloisterPalette.reliquary)
            CloisterStatPill(icon: AnyView(
                CloisterHourglassShape().stroke(CloisterPalette.parchment, lineWidth: 1.5).frame(width: 14, height: 14)
            ), value: "\(store.state.actionsLeft)/\(store.state.maxActionsPerDay)", color: CloisterPalette.moss)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("DAY")
                    .font(CloisterFont.ui(9, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(CloisterPalette.textMuted)
                Text("\(store.state.day)")
                    .font(CloisterFont.display(18, weight: .heavy))
                    .foregroundColor(CloisterPalette.textPrimary)
            }
            Button {
                showSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(CloisterPalette.surfaceRaised)
                    Circle()
                        .stroke(CloisterPalette.divider, lineWidth: 1)
                    CloisterCornerOrnament()
                        .stroke(CloisterPalette.stoneDark, lineWidth: 1)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-45))
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(CloisterPalette.surface)
    }
}

struct CloisterStatPill: View {
    let icon: AnyView
    let value: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(value)
                .font(CloisterFont.ui(13, weight: .heavy))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color))
    }
}

// MARK: - Custom tab bar
struct CloisterTabBar: View {
    @Binding var selectedTab: Int
    var body: some View {
        HStack(spacing: 0) {
            tabButton(0, label: "Cloister", kind: .cloister)
            tabButton(1, label: "Cross", kind: .cross)
            tabButton(2, label: "Herbarium", kind: .herbarium)
            tabButton(3, label: "Visitors", kind: .visitors)
            tabButton(4, label: "Almanac", kind: .almanac)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            CloisterPalette.surface
                .overlay(Rectangle().fill(CloisterPalette.divider).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    private func tabButton(_ idx: Int, label: String, kind: CloisterTabIcon.Kind) -> some View {
        Button {
            selectedTab = idx
        } label: {
            VStack(spacing: 4) {
                CloisterTabIcon(kind: kind, size: 22,
                                color: selectedTab == idx ? CloisterPalette.moss : CloisterPalette.textMuted)
                Text(label)
                    .font(CloisterFont.ui(10, weight: .semibold))
                    .foregroundColor(selectedTab == idx ? CloisterPalette.textPrimary : CloisterPalette.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
