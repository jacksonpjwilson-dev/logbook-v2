import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweepRotation = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("LogbookLaunchArt")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                Ellipse()
                    .trim(from: 0.04, to: 0.34)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.06),
                                .white.opacity(0.9),
                                Color(red: 0.69, green: 0.86, blue: 1).opacity(0.8),
                                .clear
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: proxy.size.width * 1.15, height: proxy.size.height * 0.46)
                    .rotationEffect(.degrees(sweepRotation))
                    .blur(radius: 2)
                    .shadow(color: .white.opacity(0.5), radius: 10)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.46)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .task {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    sweepRotation = 360
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Logbook is opening")
    }
}
