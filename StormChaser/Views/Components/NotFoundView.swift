import SwiftUI

struct NotFoundView: View {
    let title: String
    let message: String
    var symbolName: String = "cloud.slash"
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let retry {
                Button {
                    retry()
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NotFoundView(
        title: "Weather not found",
        message: "We couldn't reach the weather service. Check your connection and try again.",
        retry: {}
    )
}
