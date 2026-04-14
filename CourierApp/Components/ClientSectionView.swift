import SwiftUI

// MARK: - Client Section

struct ClientSectionView: View {
    let order: Order
    let onCall: () -> Void
    var onCopy: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerRow
            if !order.clientComment.isEmpty {
                commentBubble(text: order.clientComment)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.stroke2, lineWidth: 1))
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Клиент")
                    .textStyle()
                    .foregroundStyle(Color.text2)
                Text(order.clientName)
                    .headline1Style()
                    .foregroundStyle(Color.text1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onCall()
            } label: {
                callButton
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Call Button

    private var callButton: some View {
        HStack(spacing: 6) {
            Image("Phone")
                .resizable()
                .frame(width: 16, height: 16)
            Text("Позвонить")
                .textStyle()
                .foregroundStyle(Color.text1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 48)
        .background(
            LinearGradient(
                colors: [
                    Color.fill1,
                    Color.fill3
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.stroke2, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }

    // MARK: - Comment Bubble

    @ViewBuilder
    private func commentBubble(text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(text)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 6)

                CommentTipShape()
                    .fill(Color.surface2)
                    .frame(width: 20, height: 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onCopy?(text) }
    }
}

// MARK: - Comment Tip Shape

private struct CommentTipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        ClientSectionView(order: Order.sampleOrders[0], onCall: {})
            .padding(.horizontal, 24)
    }
}
