import SwiftUI

struct CloisterLoadingScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            CloisterPageBackground()
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(CloisterPalette.divider, lineWidth: 2)
                        .frame(width: 140, height: 140)
                    Circle()
                        .stroke(CloisterPalette.moss, lineWidth: 4)
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 4.0).repeatForever(autoreverses: false), value: pulse)
                    CloisterFlower(petals: 7, petalColor: CloisterPalette.gilded, centerColor: CloisterPalette.reliquary)
                        .frame(width: 72, height: 72)
                        .opacity(pulse ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }
                Text("Cloister Curator")
                    .font(CloisterFont.display(24, weight: .black))
                    .foregroundColor(CloisterPalette.textPrimary)
                Text("Polishing the herbarium spines.")
                    .font(CloisterFont.body(14))
                    .foregroundColor(CloisterPalette.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(i.isMultiple(of: 2) ? CloisterPalette.moss : CloisterPalette.gilded)
                            .frame(width: 10, height: pulse ? 28 : 10)
                            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(Double(i) * 0.1), value: pulse)
                    }
                }
            }
            .padding(.horizontal, 28)
        }
        .onAppear { pulse = true }
    }
}
