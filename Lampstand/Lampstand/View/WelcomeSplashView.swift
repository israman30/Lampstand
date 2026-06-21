//
//  WelcomeSplashView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/20/26.
//

import SwiftUI

struct WelcomeSplashView: View {
    var onContinue: () -> Void

    @State private var isFadingOut = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LampstandTheme.Palette.parchment,
                    LampstandTheme.Palette.parchmentTint
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "lamp.desk.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(LampstandTheme.Palette.accent)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text("Welcome to Lampstand")
                        .font(LampstandTheme.Typography.title)
                        .foregroundStyle(LampstandTheme.Palette.ink)
                        .multilineTextAlignment(.center)

                    Text("A quiet place to read and search the Bible.")
                        .font(LampstandTheme.Typography.body)
                        .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: fadeOutAndContinue) {
                    Text("Get Started")
                        .font(LampstandTheme.Typography.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(LampstandTheme.Palette.accent)
                .disabled(isFadingOut)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .opacity(isFadingOut ? 0 : 1)
    }

    private func fadeOutAndContinue() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isFadingOut = true
        } completion: {
            onContinue()
        }
    }
}

#if DEBUG
struct WelcomeSplashView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeSplashView(onContinue: {})
    }
}
#endif
