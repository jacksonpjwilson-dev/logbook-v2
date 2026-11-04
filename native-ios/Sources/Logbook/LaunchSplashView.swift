import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweepRotation = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.015, green: 0.02, blue: 0.03).ignoresSafeArea()

                Image("LogbookLaunchArt")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(proxy.size.width * 0.88, 500))
                    .overlay {
                        GeometryReader { imageProxy in
                            ZStack {
                                Ellipse()
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                                    .frame(width: imageProxy.size.width * 0.78, height: imageProxy.size.height * 0.52)

                                Ellipse()
                                    .trim(from: 0.04, to: 0.34)
                                    .stroke(
                                        AngularGradient(
                                            colors: [
                                                .clear,
                                                .white.opacity(0.06),
                                                .white.opacity(0.95),
                                                Color(red: 0.69, green: 0.86, blue: 1).opacity(0.78),
                                                .clear
                                            ],
                                            center: .center,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(360)
                                        ),
                                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                    )
                                    .frame(width: imageProxy.size.width * 0.78, height: imageProxy.size.height * 0.52)
                                    .rotationEffect(.degrees(sweepRotation))
                                    .blur(radius: 2)
                                    .shadow(color: .white.opacity(0.55), radius: 10)
                            }
                            .frame(width: imageProxy.size.width, height: imageProxy.size.height)
                            .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("Logbook")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    sweepRotation = 360
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Logbook is opening")
    }
}
