import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.45), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: geo.size.width * phase)
                    .blendMode(.plusLighter)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmering() -> some View { modifier(ShimmerModifier()) }
}

struct SkeletonBlock: View {
    var height: CGFloat = 16
    var width: CGFloat? = nil
    var corner: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.secondary.opacity(0.18))
            .frame(width: width, height: height)
            .shimmering()
    }
}

struct WeatherSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SkeletonBlock(height: 48, width: 48, corner: 12)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBlock(height: 14, width: 140)
                    SkeletonBlock(height: 12, width: 90)
                }
                Spacer()
            }
            SkeletonBlock(height: 80, corner: 14)
            HStack(spacing: 12) {
                SkeletonBlock(height: 64, corner: 12)
                SkeletonBlock(height: 64, corner: 12)
                SkeletonBlock(height: 64, corner: 12)
            }
            SkeletonBlock(height: 18, width: 120)
            VStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonBlock(height: 44, corner: 10)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    WeatherSkeletonView()
}
