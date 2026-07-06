//
//  ContentView.swift
//  Shader-in-blago
//
//  Created by Pavel Korostelev on 02.07.2026.
//

import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @State private var activeSheet: CashbackRoute?
    @State private var showingDoneSummary = false
    @State private var navigationPath: [CashbackNavigationRoute] = []
    @State private var blackShare = 100.0
    @State private var charityShare = 50.0
    @State private var selectedFund = ""
    @State private var selectedAccount = "Накопительный счет"

    private var blackTitle: String {
        "\(Int(blackShare))% на Black"
    }

    private var doneSummary: String {
        if blackShare == 100 {
            return "Кэшбэк будет зачисляться на Black."
        }

        let charityShare = max(0, 100 - Int(blackShare))
        let fundName = selectedFund.isEmpty ? "выбранный фонд" : selectedFund.lowercased()
        return "\(Int(blackShare))% на Black, \(charityShare)% — в \(fundName)."
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                TUIScreenBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 16)
                            .padding(.top, 36)

                        cards
                            .padding(.top, 36)
                    }
                    .padding(.bottom, 144)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {} label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Назад")
                    .accessibilityHint("Демонстрационный элемент навигации")
                }
            }
            .tint(TUIColors.primaryText)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                floatingAction
            }
            .navigationDestination(for: CashbackNavigationRoute.self) { route in
                switch route {
                case .fundSelection:
                    FundSelectionView(
                        selectedFund: $selectedFund,
                        charityShare: $charityShare,
                        blackShare: $blackShare
                    ) { fund in
                        navigationPath = [.fundSelection, .fundContribution(fund)]
                    }

                case let .fundContribution(fund):
                    FundContributionView(
                        fund: fund,
                        selectedFund: $selectedFund,
                        charityShare: $charityShare,
                        blackShare: $blackShare
                    ) {
                        navigationPath.removeAll()
                    }
                }
            }
            .sheet(item: $activeSheet) { route in
                CashbackRouteSheet(
                    route: route,
                    blackShare: $blackShare,
                    selectedFund: $selectedFund,
                    selectedAccount: $selectedAccount
                )
                .presentationDetents([.height(route.sheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationBackground(TUIColors.card)
                .preferredColorScheme(.dark)
            }
            .alert("Готово", isPresented: $showingDoneSummary) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(doneSummary)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Куда зачислять кэшбэк?")
                .font(.system(size: 30, weight: .bold))
                .tracking(0.36)
                .foregroundStyle(TUIColors.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Можно переводить часть в фонд,\nа остальное — на выбранный счет")
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.41)
                .foregroundStyle(TUIColors.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var cards: some View {
        VStack(spacing: 20) {
            CashbackCard(
                route: .black,
                title: blackTitle,
                subtitle: nil,
                showsDisclosure: true
            ) {
                activeSheet = .black
            }

            CashbackCard(
                route: .charity,
                title: "Благотворительность",
                subtitle: selectedFund.isEmpty ? "Можно выбрать фонд" : selectedFund,
                showsDisclosure: true
            ) {
                navigationPath = [.fundSelection]
            }

            CashbackCard(
                route: .savings,
                title: selectedAccount,
                subtitle: "11% годовых",
                showsDisclosure: false
            ) {
                activeSheet = .savings
            }
        }
    }

    private var floatingAction: some View {
        VStack(spacing: 0) {
            Button {
                showingDoneSummary = true
            } label: {
                Text("Готово")
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundStyle(TUIColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(TUIColors.accentYellow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityHint(doneSummary)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
        }
        .background(TUIColors.screenUnderlay)
    }
}

private enum CashbackNavigationRoute: Hashable {
    case fundSelection
    case fundContribution(CharityFund)
}

private enum CashbackRoute: String, Identifiable {
    case black
    case charity
    case savings

    var id: String { rawValue }

    var sheetTitle: String {
        switch self {
        case .black:
            return "Black"
        case .charity:
            return "Благотворительность"
        case .savings:
            return "Накопительный счет"
        }
    }

    var sheetSubtitle: String {
        switch self {
        case .black:
            return "Укажите, какую часть кэшбэка оставить на карте."
        case .charity:
            return "Выберите фонд, куда будет уходить часть кэшбэка."
        case .savings:
            return "Выберите счет для зачисления остатка."
        }
    }

    var sheetHeight: CGFloat {
        switch self {
        case .black:
            return 360
        case .charity:
            return 430
        case .savings:
            return 380
        }
    }
}

private struct CashbackCard: View {
    let route: CashbackRoute
    let title: String
    let subtitle: String?
    let showsDisclosure: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                icon
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                        .foregroundStyle(TUIColors.primaryText)
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .tracking(-0.08)
                            .foregroundStyle(TUIColors.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(TUIColors.tertiaryText)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            .padding(.horizontal, 20)
            .background(TUIColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(CardPressButtonStyle(pressedScale: 0.95))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var icon: some View {
        switch route {
        case .black:
            ZStack {
                Circle()
                    .fill(TUIColors.blue)

                Image("TuiCurrencyRub")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
            }

        case .charity:
            Image("TuiLogoSquareRyadom")
                .resizable()
                .scaledToFit()

        case .savings:
            ZStack {
                Circle()
                    .fill(TUIColors.baseAlt)

                Image("TuiIcMediumPlus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        }
    }
}

private struct FundSelectionView: View {
    @Binding var selectedFund: String
    @Binding var charityShare: Double
    @Binding var blackShare: Double
    let openFund: (CharityFund) -> Void

    var body: some View {
        ZStack {
            TUIScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("В какой фонд?")
                        .font(.system(size: 30, weight: .bold))
                        .tracking(0.36)
                        .foregroundStyle(TUIColors.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)

                    LazyVStack(spacing: 4) {
                        ForEach(CharityFund.all) { fund in
                            Button {
                                openFund(fund)
                            } label: {
                                CharityFundRow(fund: fund)
                            }
                            .buttonStyle(CardPressButtonStyle())
                            .accessibilityHint("Открыть настройку кэшбэка")
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TUIColors.primaryText)
        .preferredColorScheme(.dark)
    }
}

private struct CharityFundRow: View {
    let fund: CharityFund

    var body: some View {
        HStack(spacing: 16) {
            Image(fund.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(fund.title)
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundStyle(TUIColors.primaryText)
                    .lineLimit(1)

                Text(fund.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundStyle(TUIColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

private struct CharityFund: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageName: String

    init(title: String, subtitle: String, imageName: String) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
    }

    static let all = [
        CharityFund(
            title: "Вера: Т-Банк удвоит вашу помощь",
            subtitle: "Помощь тяжелобольным взрослым и детям по всей России",
            imageName: "FundVera"
        ),
        CharityFund(
            title: "Фонд Лапа Дружбы",
            subtitle: "Фонд помощи бездомным животным",
            imageName: "FundLapaDruzhby"
        ),
        CharityFund(
            title: "БФ Котодетки",
            subtitle: "Помощь бездомным животным",
            imageName: "FundKotodetki"
        ),
        CharityFund(
            title: "Собаки, Которые Любят",
            subtitle: "Помощь бездомным животным (собаки и . коты)",
            imageName: "FundSobaki"
        ),
        CharityFund(
            title: "Помощь бездомным беспородным животным",
            subtitle: "Помощь бездомным беспородным животным",
            imageName: "FundHomelessAnimals"
        ),
        CharityFund(
            title: "Фонд Защиты Городских Животных",
            subtitle: "Помощь животным",
            imageName: "FundCityAnimals"
        ),
        CharityFund(
            title: "АНО Центр помощи Заступник",
            subtitle: "Помощь детям в критических ситуациях",
            imageName: "FundZastupnik"
        ),
        CharityFund(
            title: "БФ Дальше",
            subtitle: "Помощь женщинам с раком груди",
            imageName: "FundDalshe"
        )
    ]
}

private struct FundContributionView: View {
    @Environment(\.dismiss) private var dismiss

    let fund: CharityFund
    @Binding var selectedFund: String
    @Binding var charityShare: Double
    @Binding var blackShare: Double
    let finishFlow: () -> Void

    @State private var isFavorite = true
    @State private var percentCenter: CGPoint = .zero
    @State private var hasPercentCenter = false
    @State private var displayProgress: Float = 0.0
    @State private var lastPulseTick: Int = -1
    @State private var pulseBoost: Float = 0.0
    @State private var breatheBoost: Float = 0.0
    @State private var shockStartDate: Date?
    @State private var shockBreatheBoost: Float = 0.0
    @State private var isShowingSuccess = false
    @State private var isCompletionTransitionActive = false
    @State private var isCompletionDimOverlayVisible = false
    @State private var completionTransitionStartDate: Date?
    @State private var completionDimOverlayOpacity = 0.0
    @State private var successScreenOpacity = 0.0
    @State private var contributionControlsOpacity = 1.0

    private var estimatedMonthlyText: String {
        "Примерно \(Int(charityShare * 3)) ₽ в месяц"
    }

    private var charityPercent: Int {
        min(max(Int(charityShare.rounded()), 0), 100)
    }

    private var palette: CharityRipplePalette {
        CharityRipplePalette.colors(for: charityPercent)
    }

    private let shaderSettings = CharityRippleShaderSettings()
    private let shockDuration: TimeInterval = 1.1
    private let shockWidth: Float = 0.4025
    private let shockIntensity: Float = 0.48
    private let shockBreatheBoostValue: Float = 0.35
    private let completionTransitionDuration: TimeInterval = 0.95
    private let completionSuccessRevealDelay: TimeInterval = 0.84
    private let completionSuccessFadeDuration: TimeInterval = 0.32
    private let completionDimFadeDuration: TimeInterval = 0.32
    private let completionDimFadeInDelay: TimeInterval = 0.46
    private let completionDimFadeInDuration: TimeInterval = 0.38
    private let completionControlsFadeDelay: TimeInterval = 0.36
    private let completionControlsFadeDuration: TimeInterval = 0.28
    private let sliderHorizontalInset: CGFloat = 20

    var body: some View {
        ZStack {
            if isShowingSuccess {
                FundSuccessView(
                    fund: fund,
                    charityShare: charityShare,
                    close: finishFlow
                )
                .opacity(successScreenOpacity)
                .transition(.opacity)
            } else {
                contributionSelectionContent
                    .transition(.opacity)
            }

            if isCompletionDimOverlayVisible {
                completionTransitionDimOverlay
                    .opacity(completionDimOverlayOpacity)
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isShowingSuccess {
                doneButton
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .tint(TUIColors.primaryText)
        .preferredColorScheme(.dark)
        .onPreferenceChange(RippleCenterPreferenceKey.self) { point in
            if let point {
                percentCenter = point
                hasPercentCenter = true
            }
        }
        .onChange(of: charityShare) { _, newValue in
            syncShaderState(for: Int(newValue.rounded()), animated: true, allowsPulse: true)
        }
        .onAppear {
            syncShaderState(for: charityPercent, animated: false, allowsPulse: false)
            lastPulseTick = (charityPercent / 5) * 5
        }
    }

    private var contributionSelectionContent: some View {
        ZStack {
            TUIScreenBackground()

            shaderBackground

            VStack(spacing: 0) {
                contributionTopBar

                Text("Сколько кэшбэка переводить\nежемесячно?")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(0.38)
                    .foregroundStyle(TUIColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 36)

                Spacer(minLength: 72)

                PercentValueText(value: charityPercent)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: RippleCenterPreferenceKey.self,
                                value: CGPoint(
                                    x: proxy.frame(in: .global).midX,
                                    y: proxy.frame(in: .global).midY
                                )
                            )
                        }
                    }
                    .onTapGesture {
                        triggerShaderShock()
                    }

                Spacer(minLength: 132)

                VStack(spacing: 24) {
                    estimatedMonthlyChip

                    TUILabsScaleSelector(
                        value: $charityShare,
                        minValue: 0,
                        maxValue: 100,
                        step: 5,
                        showsTrailEffect: true
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .padding(.horizontal, sliderHorizontalInset)
                }
                .padding(.bottom, 36)
            }
            .padding(.bottom, 24)
            .opacity(contributionControlsOpacity)
        }
    }

    private var contributionTopBar: some View {
        ZStack {
            Text(fund.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(TUIColors.primaryText)
                .lineLimit(1)
                .padding(.horizontal, 72)

            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(TUIColors.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isCompletionTransitionActive)
                .accessibilityLabel("Назад")

                Spacer()

                FundFavoriteButton(
                    imageName: fund.imageName,
                    fundTitle: fund.title,
                    isFavorite: isFavorite
                ) {
                    isFavorite.toggle()
                }
                .disabled(isCompletionTransitionActive)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
    }

    private var doneButton: some View {
        Button {
            selectedFund = fund.title
            blackShare = max(0, 100 - charityShare)
            startCompletionTransition()
        } label: {
            Text("Готово")
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.41)
                .foregroundStyle(TUIColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(TUIColors.neutralFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isCompletionTransitionActive)
        .opacity(contributionControlsOpacity)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var completionTransitionDimOverlay: some View {
        TUIColors.screenUnderlay
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var estimatedMonthlyChip: some View {
        HStack(spacing: 4) {
            if charityPercent == 0 {
                Text("Главное — начать")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.08)
                    .foregroundStyle(TUIColors.primaryText)

                Text("🌟")
                    .font(.custom("AppleColorEmoji", size: 13))
                    .accessibilityHidden(true)
            } else {
                Text(estimatedMonthlyText)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.08)
                    .foregroundStyle(TUIColors.primaryText)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .fixedSize(horizontal: true, vertical: false)
        .background(TUIColors.neutralFill, in: Capsule())
    }

    @ViewBuilder
    private var shaderBackground: some View {
        if #available(iOS 17.0, *) {
            CharityRippleShaderBackground(
                percentCenter: percentCenter,
                hasPercentCenter: hasPercentCenter,
                progress: displayProgress,
                pulseBoost: pulseBoost,
                breatheBoost: breatheBoost + shockBreatheBoost,
                shockStartDate: shockStartDate,
                shockDuration: Float(shockDuration),
                shockWidth: shockWidth,
                shockIntensity: shockIntensity,
                transitionStartDate: completionTransitionStartDate,
                transitionDuration: Float(completionTransitionDuration),
                donationValue: charityPercent,
                settings: shaderSettings,
                baseColor: palette.base,
                glowColor: palette.glow,
                edgeColor: palette.edge
            )
            .ignoresSafeArea()
        }
    }

    private func startCompletionTransition() {
        guard !isCompletionTransitionActive, !isShowingSuccess else {
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        completionTransitionStartDate = Date()
        isCompletionTransitionActive = true
        isCompletionDimOverlayVisible = true
        completionDimOverlayOpacity = 0.0
        successScreenOpacity = 0.0
        contributionControlsOpacity = 1.0
        pulseBoost = 0.0
        breatheBoost = 0.0

        withAnimation(.easeInOut(duration: 0.46)) {
            displayProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + completionDimFadeInDelay) {
            guard isCompletionTransitionActive, !isShowingSuccess else {
                return
            }

            withAnimation(.easeInOut(duration: completionDimFadeInDuration)) {
                completionDimOverlayOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + completionControlsFadeDelay) {
            guard isCompletionTransitionActive else {
                return
            }

            withAnimation(.easeOut(duration: completionControlsFadeDuration)) {
                contributionControlsOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + completionSuccessRevealDelay) {
            revealSuccessAfterCompletionTransition()
        }
    }

    private func revealSuccessAfterCompletionTransition() {
        guard isCompletionTransitionActive else {
            return
        }

        isCompletionDimOverlayVisible = true
        if completionDimOverlayOpacity < 1.0 {
            completionDimOverlayOpacity = 1.0
        }
        successScreenOpacity = 0.0
        isShowingSuccess = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(.easeInOut(duration: completionSuccessFadeDuration)) {
            successScreenOpacity = 1.0
        }

        withAnimation(.easeOut(duration: completionDimFadeDuration).delay(0.02)) {
            completionDimOverlayOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + max(completionSuccessFadeDuration, completionDimFadeDuration) + 0.1) {
            isCompletionDimOverlayVisible = false
            isCompletionTransitionActive = false
            completionTransitionStartDate = nil
            pulseBoost = 0.0
            breatheBoost = 0.0
            contributionControlsOpacity = 1.0
        }
    }

    private func syncShaderState(for rawValue: Int, animated: Bool, allowsPulse: Bool) {
        let value = min(max(rawValue, 0), 100)
        let progress = shaderProgress(for: value)

        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                displayProgress = progress
            }
        } else {
            displayProgress = progress
        }

        if allowsPulse {
            triggerPulseIfNeeded(for: value)
            triggerBreatheBoostIfNeeded(for: value)
        }
    }

    private func shaderProgress(for value: Int) -> Float {
        if value < 10 {
            return Float(value) / 100.0
        }

        let normalizedValue = Float(value - 10) / 90.0
        return 0.1 + normalizedValue * 0.9
    }

    private func triggerPulseIfNeeded(for value: Int) {
        let tick = (value / 5) * 5
        guard tick != lastPulseTick else {
            return
        }

        lastPulseTick = tick
        let maxBoost = shaderSettings.pulseStrength * 2.5
        pulseBoost = min(pulseBoost + shaderSettings.pulseStrength, maxBoost)
        withAnimation(.easeOut(duration: Double(shaderSettings.pulseDecay)).delay(Double(shaderSettings.pulseDelay))) {
            pulseBoost = 0.0
        }
    }

    private func triggerBreatheBoostIfNeeded(for value: Int) {
        guard value >= 90 else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            breatheBoost = value == 100 ? 0.1 : 0.05
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                breatheBoost = 0.0
            }
        }
    }

    private func triggerShaderShock() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        shockStartDate = Date()
        shockBreatheBoost = shockBreatheBoostValue

        withAnimation(.easeOut(duration: shockDuration)) {
            shockBreatheBoost = 0.0
        }
    }
}

private struct FundSuccessView: View {
    let fund: CharityFund
    let charityShare: Double
    let close: () -> Void

    @State private var successTextHeight: CGFloat = SuccessTextHeightPreferenceKey.defaultValue

    private let buttonHeight: CGFloat = 56
    private let buttonHorizontalPadding: CGFloat = 16
    private let buttonTopPadding: CGFloat = 14
    private let buttonBottomPadding: CGFloat = 8
    private let textToButtonSpacing: CGFloat = 64
    private let navigationBarHeight: CGFloat = 44

    private var charityPercent: Int {
        min(max(Int(charityShare.rounded()), 0), 100)
    }

    private var fundDisplayName: String {
        var title = fund.title
        for prefix in ["БФ ", "Фонд ", "АНО "] {
            if title.hasPrefix(prefix) {
                title.removeFirst(prefix.count)
            }
        }
        return title
    }

    private var successMessage: String {
        switch charityPercent {
        case 100:
            return "Весь кэшбэк будет переводиться\nв фонд «\(fundDisplayName)»"
        case 0:
            return "Кэшбэк пока не будет\nпереводиться в фонд"
        default:
            return "\(charityPercent)% кэшбэка будет переводиться\nв фонд «\(fundDisplayName)»"
        }
    }

    var body: some View {
        ZStack {
            TUIScreenBackground()

            GeometryReader { proxy in
                let videoSide = min(proxy.size.width, 550)
                let textBottomInset = max(0, textToButtonSpacing - buttonTopPadding)
                let textTopY = proxy.size.height - textBottomInset - successTextHeight
                let navigationBarBottomY = proxy.safeAreaInsets.top + navigationBarHeight
                let videoCenterY = max(videoSide / 2, (navigationBarBottomY + textTopY) / 2)

                OneShotVideoView(resourceName: "SuccessHearts", fileExtension: "mp4")
                    .frame(width: videoSide, height: videoSide)
                    .clipped()
                    .position(
                        x: proxy.size.width / 2,
                        y: videoCenterY
                    )

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    Text(successMessage)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.41)
                        .foregroundStyle(TUIColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: min(338, max(0, proxy.size.width - 64)))
                        .background {
                            GeometryReader { textProxy in
                                Color.clear.preference(
                                    key: SuccessTextHeightPreferenceKey.self,
                                    value: textProxy.size.height
                                )
                            }
                        }
                }
                .padding(.bottom, textBottomInset)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            successBottomAction
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .tint(TUIColors.primaryText)
        .preferredColorScheme(.dark)
        .onPreferenceChange(SuccessTextHeightPreferenceKey.self) { height in
            guard height > 0, abs(successTextHeight - height) > 0.5 else {
                return
            }

            successTextHeight = height
        }
    }

    private var successBottomAction: some View {
        VStack(spacing: 0) {
            Button(action: close) {
                Text("Хорошо")
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundStyle(TUIColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(TUIColors.accentYellow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, buttonHorizontalPadding)
            .padding(.top, buttonTopPadding)
            .padding(.bottom, buttonBottomPadding)
        }
        .background(TUIColors.screenUnderlay)
    }
}

private struct SuccessTextHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 44

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct OneShotVideoView: UIViewRepresentable {
    let resourceName: String
    let fileExtension: String

    func makeUIView(context: Context) -> OneShotVideoUIView {
        let view = OneShotVideoUIView()
        view.configure(resourceName: resourceName, fileExtension: fileExtension)
        return view
    }

    func updateUIView(_ uiView: OneShotVideoUIView, context: Context) {
        uiView.configure(resourceName: resourceName, fileExtension: fileExtension)
    }
}

private final class OneShotVideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var currentURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            player?.pause()
        } else {
            player?.play()
        }
    }

    func configure(resourceName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            playerLayer.player = nil
            player = nil
            currentURL = nil
            return
        }

        guard url != currentURL else {
            if window != nil {
                player?.play()
            }
            return
        }

        currentURL = url
        let playerItem = AVPlayerItem(url: url)
        let videoPlayer = AVPlayer(playerItem: playerItem)

        videoPlayer.isMuted = true
        videoPlayer.actionAtItemEnd = .pause

        player = videoPlayer
        playerLayer.player = videoPlayer
        videoPlayer.play()
    }
}

private struct PercentValueText: View {
    let value: Int

    private let font = Font.system(size: 48, weight: .bold, design: .rounded)

    var body: some View {
        Text("100%")
            .font(font)
            .tracking(-1)
            .monospacedDigit()
            .hidden()
            .overlay {
                Text("\(value)%")
                    .font(font)
                    .tracking(-1)
                    .monospacedDigit()
                    .foregroundStyle(TUIColors.primaryText)
            }
            .shadow(color: Color.white.opacity(0.55), radius: 22, x: 0, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(value) процентов")
    }
}

private struct FundFavoriteButton: View {
    private let avatarSize: CGFloat = 44

    let imageName: String
    let fundTitle: String
    let isFavorite: Bool
    let action: () -> Void

    private var avatar: UIImage? {
        UIImage(named: imageName)
    }

    var body: some View {
        Button(action: action) {
            if let avatar {
                avatarIcon(avatar)
            } else {
                fallbackIcon
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Убрать \(fundTitle) из избранного" : "Добавить \(fundTitle) в избранное")
    }

    private func avatarIcon(_ avatar: UIImage) -> some View {
        Image(uiImage: avatar)
            .resizable()
            .scaledToFill()
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
            .contentShape(Circle())
    }

    private var fallbackIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)

            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(TUIColors.primaryText)
        }
        .frame(width: avatarSize, height: avatarSize)
        .contentShape(Circle())
    }
}

private struct TUILabsScaleSelector: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let step: Double
    let showsTrailEffect: Bool

    @State private var trailTicks: [ScaleTrailTick] = []
    @State private var dragStartValue: Double?

    private let edgePaddingTickCount = 5
    private let rangeTickCount = 35
    private let tickWidth: CGFloat = 2
    private let minimumTickStride: CGFloat = 12
    private let selectableScaleHorizontalInset: CGFloat = 20
    private let scaleHeight: CGFloat = 40
    private let trailLifetime: TimeInterval = 0.25
    private let edgeFadeWidth: CGFloat = 120

    private var tickCount: Int {
        rangeTickCount + edgePaddingTickCount * 2
    }

    private var valueStepCount: Int {
        max(Int(round((maxValue - minValue) / step)) + 1, 1)
    }

    private var selectedValueIndex: Int {
        let normalized = (clampedValue - minValue) / step
        return min(max(Int(round(normalized)), 0), valueStepCount - 1)
    }

    private var selectedTickIndex: Int {
        tickIndex(forValueIndex: selectedValueIndex)
    }

    private var firstSelectableTickIndex: Int {
        edgePaddingTickCount
    }

    private var lastSelectableTickIndex: Int {
        edgePaddingTickCount + rangeTickCount - 1
    }

    private var clampedValue: Double {
        min(max(value, minValue), maxValue)
    }

    var body: some View {
        GeometryReader { proxy in
            tickScale(width: proxy.size.width)
                .mask(edgeFadeMask(width: proxy.size.width))
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            updateValue(translationX: gesture.translation.width, width: proxy.size.width)
                        }
                        .onEnded { _ in
                            dragStartValue = nil
                        }
                )
        }
        .frame(height: scaleHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Доля кэшбэка")
        .accessibilityValue("\(Int(value)) процентов")
        .onChange(of: selectedValueIndex) { oldIndex, newIndex in
            guard oldIndex != newIndex else {
                return
            }

            addTrail(
                from: tickIndex(forValueIndex: oldIndex),
                to: tickIndex(forValueIndex: newIndex)
            )
        }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(clampedValue + step, maxValue)
            case .decrement:
                value = max(clampedValue - step, minValue)
            @unknown default:
                break
            }
        }
    }

    private func tickScale(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: tickSpacing(for: width)) {
                ForEach(0..<tickCount, id: \.self) { index in
                    Capsule()
                        .fill(tickColor(at: index))
                        .frame(width: tickWidth, height: tickHeight(at: index))
                }
            }

            if showsTrailEffect {
                TimelineView(.animation) { timeline in
                    trailLayer(at: timeline.date, width: width)
                }
            }
        }
        .frame(width: tickGroupWidth(for: width), height: scaleHeight, alignment: .bottom)
        .offset(x: tapeOffset(for: width))
        .frame(width: width, height: scaleHeight)
    }

    private func edgeFadeMask(width: CGFloat) -> some View {
        let fadeLocation = min(edgeFadeWidth / max(width, 1), 0.5)

        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: fadeLocation),
                .init(color: .white, location: 1 - fadeLocation),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func tickColor(at index: Int) -> Color {
        guard isSelectableTick(index) else {
            return .clear
        }

        return index <= selectedTickIndex ? TUIColors.blue : Color.white.opacity(0.12)
    }

    private func tickHeight(at index: Int) -> CGFloat {
        guard isSelectableTick(index) else {
            return 1
        }

        if index == selectedTickIndex {
            return 36
        }

        let distanceFromSelected = abs(index - selectedTickIndex)
        if distanceFromSelected > 0 && distanceFromSelected.isMultiple(of: 12) {
            return 28
        }

        return 20
    }

    private func isSelectableTick(_ index: Int) -> Bool {
        firstSelectableTickIndex...lastSelectableTickIndex ~= index
    }

    private func updateValue(translationX: CGFloat, width: CGFloat) {
        let startValue = dragStartValue ?? clampedValue

        if dragStartValue == nil {
            dragStartValue = startValue
        }

        let stepDelta = -translationX / pointsPerValueStep(for: width)
        let rawValue = startValue + Double(stepDelta) * step
        let steppedValue = minValue + ((rawValue - minValue) / step).rounded() * step
        value = min(max(steppedValue, minValue), maxValue)
    }

    private func tickSpacing(for width: CGFloat) -> CGFloat {
        max(0, tickStride(for: width) - tickWidth)
    }

    private func tickStride(for width: CGFloat) -> CGFloat {
        let fittedStride = (width - selectableScaleHorizontalInset * 2) / CGFloat(rangeTickCount - 1)
        return max(minimumTickStride, fittedStride)
    }

    private func pointsPerValueStep(for width: CGFloat) -> CGFloat {
        tickStride(for: width) * visualTicksPerValueStep
    }

    private var visualTicksPerValueStep: CGFloat {
        CGFloat(max(rangeTickCount - 1, 1)) / CGFloat(max(valueStepCount - 1, 1))
    }

    private func tickIndex(forValueIndex valueIndex: Int) -> Int {
        let progress = CGFloat(valueIndex) / CGFloat(max(valueStepCount - 1, 1))
        let rangeTickIndex = Int(round(progress * CGFloat(rangeTickCount - 1)))
        return firstSelectableTickIndex + rangeTickIndex
    }

    private func tickGroupWidth(for width: CGFloat) -> CGFloat {
        tickWidth + CGFloat(tickCount - 1) * tickStride(for: width)
    }

    private func tickCenterX(at index: Int, width: CGFloat) -> CGFloat {
        CGFloat(index) * tickStride(for: width) + tickWidth / 2
    }

    private func tapeOffset(for width: CGFloat) -> CGFloat {
        tickGroupWidth(for: width) / 2 - tickCenterX(at: selectedTickIndex, width: width)
    }

    private func trailLayer(at date: Date, width: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: tickSpacing(for: width)) {
            ForEach(0..<tickCount, id: \.self) { index in
                if let height = trailHeight(at: index, date: date) {
                    Capsule()
                        .fill(tickColor(at: index))
                        .frame(width: tickWidth, height: height)
                } else {
                    Color.clear
                        .frame(width: tickWidth, height: 1)
                }
            }
        }
    }

    private func trailHeight(at index: Int, date: Date) -> CGFloat? {
        guard isSelectableTick(index) else {
            return nil
        }

        let heights = trailTicks
            .filter { $0.index == index }
            .compactMap { trailTick -> CGFloat? in
                let progress = min(max(date.timeIntervalSince(trailTick.createdAt) / trailLifetime, 0), 1)

                guard progress < 1 else {
                    return nil
                }

                let endHeight = tickHeight(at: index)
                return 36 + (endHeight - 36) * CGFloat(progress)
            }

        return heights.max()
    }

    private func addTrail(from oldIndex: Int, to newIndex: Int) {
        guard showsTrailEffect else {
            return
        }

        let direction = newIndex > oldIndex ? 1 : -1
        let crossedIndices = Array(stride(from: oldIndex, to: newIndex, by: direction))
        let now = Date()
        let newTrailTicks = crossedIndices.map { index in
            ScaleTrailTick(
                index: index,
                createdAt: now
            )
        }

        trailTicks.append(contentsOf: newTrailTicks)

        for trailTick in newTrailTicks {
            let remainingLifetime = max(0, trailLifetime - Date().timeIntervalSince(trailTick.createdAt))

            DispatchQueue.main.asyncAfter(deadline: .now() + remainingLifetime) {
                trailTicks.removeAll { $0.id == trailTick.id }
            }
        }
    }
}

private struct ScaleTrailTick: Identifiable {
    let id = UUID()
    let index: Int
    let createdAt: Date
}

private struct CashbackRouteSheet: View {
    let route: CashbackRoute
    @Binding var blackShare: Double
    @Binding var selectedFund: String
    @Binding var selectedAccount: String

    @Environment(\.dismiss) private var dismiss

    private let funds = [
        "Фонд помощи детям",
        "Фонд поддержки больниц",
        "Фонд локальных инициатив"
    ]

    private let accounts = [
        "Накопительный счет",
        "Black",
        "Счет для целей"
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(route.sheetSubtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(TUIColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                content

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text("Выбрать")
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.41)
                        .foregroundStyle(TUIColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(TUIColors.accentYellow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
            .background(TUIColors.card)
            .navigationTitle(route.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Закрыть")
                }
            }
            .tint(TUIColors.primaryText)
        }
        .background(TUIColors.card)
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .black:
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Доля на Black")
                        .font(.headline)
                        .foregroundStyle(TUIColors.primaryText)

                    Spacer()

                    Text("\(Int(blackShare))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(TUIColors.primaryText)
                }

                Slider(value: $blackShare, in: 0...100, step: 5)
                    .tint(TUIColors.accentYellow)

                Text("Оставшаяся часть автоматически уйдет в выбранный фонд.")
                    .font(.footnote)
                    .foregroundStyle(TUIColors.secondaryText)
            }

        case .charity:
            VStack(spacing: 10) {
                ForEach(funds, id: \.self) { fund in
                    PrototypeChoiceRow(
                        title: fund,
                        subtitle: fund == "Фонд помощи детям" ? "По умолчанию" : nil,
                        isSelected: selectedFund == fund
                    ) {
                        selectedFund = fund
                    }
                }
            }

        case .savings:
            VStack(spacing: 10) {
                ForEach(accounts, id: \.self) { account in
                    PrototypeChoiceRow(
                        title: account,
                        subtitle: account == "Накопительный счет" ? "11% годовых" : nil,
                        isSelected: selectedAccount == account
                    ) {
                        selectedAccount = account
                    }
                }
            }
        }
    }
}

private struct PrototypeChoiceRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(TUIColors.primaryText)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(TUIColors.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? TUIColors.accentYellow : TUIColors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(TUIColors.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(CardPressButtonStyle())
    }
}

private struct CardPressButtonStyle: ButtonStyle {
    let pressedScale: CGFloat

    init(pressedScale: CGFloat = 0.985) {
        self.pressedScale = pressedScale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

private enum TUIColors {
    static let background = Color.black
    static let screenUnderlay = Color(hex: 0x1C1C1E)
    static let card = Color(hex: 0x2C2C2E)
    static let baseAlt = Color(hex: 0x333333)
    static let primaryText = Color(hex: 0xF6F7F8)
    static let secondaryText = Color(hex: 0x9299A2)
    static let tertiaryText = Color.white.opacity(0.3)
    static let textOnAccent = Color(hex: 0x333333)
    static let neutralFill = Color.white.opacity(0.1)
    static let accentYellow = Color(hex: 0xFFDD2D)
    static let blue = Color(hex: 0x428BF9)
    static let magenta = Color(hex: 0xF83DAD)
}

private struct TUIScreenBackground: View {
    var body: some View {
        ZStack {
            TUIColors.background
            TUIColors.screenUnderlay
        }
        .ignoresSafeArea()
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

#Preview {
    ContentView()
}
