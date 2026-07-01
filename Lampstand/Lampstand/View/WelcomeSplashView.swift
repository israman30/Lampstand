//
//  WelcomeSplashView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/20/26.
//

import SwiftUI

struct WelcomeSplashView: View {
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .lampstandDecorativeImage()

                VStack(spacing: 12) {
                    Text("Welcome to Lampstand")
                        .font(LampstandTheme.Typography.title)
                        .foregroundStyle(LampstandTheme.Palette.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("A quiet place to read and search the Bible.")
                        .font(LampstandTheme.Typography.body)
                        .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .accessibilityElement(children: .combine)

                Spacer()

                GetStartedButton(isFadingOut: $isFadingOut) {
                    fadeOutAndContinue()
                }
            }
        }
        .opacity(isFadingOut ? 0 : 1)
        .accessibilityAddTraits(.isModal)
    }

    private func fadeOutAndContinue() {
        if reduceMotion {
            isFadingOut = true
            onContinue()
            return
        }

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

struct GetStartedButton: View {
    @Binding var isFadingOut: Bool
    var action: () -> Void
    
    init(isFadingOut: Binding<Bool>, action: @escaping () -> Void) {
        self.action = action
        self._isFadingOut = isFadingOut
    }
    
    var body: some View {
        Button(action: action) {
            Text("Get Started")
                .font(LampstandTheme.Typography.bodyEmphasis)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(LampstandTheme.Palette.accent)
        .disabled(isFadingOut)
        .accessibilityHint("Dismisses welcome screen and opens the Bible reader")
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
    }
}
