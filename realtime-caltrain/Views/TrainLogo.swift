import SwiftUI

struct TrainLogo: View {
    var size: CGFloat = 60
    var color: Color = .red

    var body: some View {
        GeometryReader { geometry in
            let s = geometry.size.width

            ZStack {
                // Main train body - front view
                RoundedRectangle(cornerRadius: s * 0.12)
                    .fill(color)
                    .frame(width: s * 0.75, height: s * 0.85)

                // Top rounded roof
                Circle()
                    .fill(color)
                    .frame(width: s * 0.75, height: s * 0.3)
                    .offset(y: -s * 0.35)
                    .clipShape(
                        Rectangle()
                            .offset(y: -s * 0.15)
                    )

                // Large front windshield
                RoundedRectangle(cornerRadius: s * 0.08)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: s * 0.55, height: s * 0.35)
                    .offset(y: -s * 0.15)

                // Side windows
                HStack(spacing: s * 0.35) {
                    RoundedRectangle(cornerRadius: s * 0.04)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.2)

                    RoundedRectangle(cornerRadius: s * 0.04)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.2)
                }
                .offset(y: s * 0.15)

                // Bottom bumper/cowcatcher
                Path { path in
                    path.move(to: CGPoint(x: s * 0.125, y: s * 0.5))
                    path.addLine(to: CGPoint(x: s * 0.2, y: s * 0.48))
                    path.addLine(to: CGPoint(x: s * 0.8, y: s * 0.48))
                    path.addLine(to: CGPoint(x: s * 0.875, y: s * 0.5))
                }
                .fill(color.opacity(0.8))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: size, height: size)
    }
}

// Preview
struct TrainLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            TrainLogo(size: 120, color: .red)
            TrainLogo(size: 100, color: .red)
            TrainLogo(size: 80, color: .red)
            TrainLogo(size: 60, color: .red)
            TrainLogo(size: 40, color: .red)
        }
        .padding()
    }
}
