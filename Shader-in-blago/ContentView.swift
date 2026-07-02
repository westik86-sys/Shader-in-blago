//
//  ContentView.swift
//  Shader-in-blago
//
//  Created by Pavel Korostelev on 02.07.2026.
//

import SwiftUI
import UIKit

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
                TUIColors.background
                    .ignoresSafeArea()

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
        .background(TUIColors.background)
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
        .buttonStyle(CardPressButtonStyle())
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

                Text("₽")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

        case .charity:
            CharityIcon()

        case .savings:
            ZStack {
                Circle()
                    .fill(TUIColors.baseAlt)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(TUIColors.blue)
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
            TUIColors.background
                .ignoresSafeArea()

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
    let fund: CharityFund
    @Binding var selectedFund: String
    @Binding var charityShare: Double
    @Binding var blackShare: Double
    let finishFlow: () -> Void

    @State private var isFavorite = true

    private var percentText: String {
        "\(Int(charityShare))%"
    }

    private var estimatedMonthlyText: String {
        "Примерно \(Int(charityShare * 3)) ₽ в месяц"
    }

    var body: some View {
        ZStack {
            TUIColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Сколько кэшбэка переводить\nежемесячно?")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(0.38)
                    .foregroundStyle(TUIColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 36)

                Spacer(minLength: 72)

                Text(percentText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(TUIColors.primaryText)
                    .shadow(color: Color.white.opacity(0.45), radius: 22, x: 0, y: 1)

                Spacer(minLength: 132)

                VStack(spacing: 24) {
                    Text(estimatedMonthlyText)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.08)
                        .foregroundStyle(TUIColors.primaryText)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(TUIColors.neutralFill, in: Capsule())

                    TUILabsScaleSelector(
                        value: $charityShare,
                        minValue: 0,
                        maxValue: 100,
                        step: 5,
                        showsTrailEffect: true
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .padding(.bottom, 36)
            }
            .padding(.bottom, 104)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                selectedFund = fund.title
                blackShare = max(0, 100 - charityShare)
                finishFlow()
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
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(TUIColors.background)
        }
        .navigationTitle(fund.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FundFavoriteButton(
                    imageName: fund.imageName,
                    fundTitle: fund.title,
                    isFavorite: isFavorite
                ) {
                    isFavorite.toggle()
                }
            }
        }
        .tint(TUIColors.primaryText)
        .preferredColorScheme(.dark)
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

    private let tickCount = 31
    private let selectableTickOffset = 5
    private let selectableTickCount = 21
    private let tickWidth: CGFloat = 2
    private let tickSpacing: CGFloat = 10
    private let scaleHeight: CGFloat = 40
    private let labelHeight: CGFloat = 16
    private let labelSpacing: CGFloat = 4
    private let trailLifetime: TimeInterval = 0.25
    private let edgeFadeWidth: CGFloat = 120

    private var range: Double {
        max(maxValue - minValue, step)
    }

    private var selectedValueIndex: Int {
        let normalized = (clampedValue - minValue) / step
        return min(max(Int(round(normalized)), 0), selectableTickCount - 1)
    }

    private var selectedTickIndex: Int {
        selectableTickOffset + selectedValueIndex
    }

    private var clampedValue: Double {
        min(max(value, minValue), maxValue)
    }

    private var tickGroupWidth: CGFloat {
        CGFloat(tickCount) * tickWidth + CGFloat(tickCount - 1) * tickSpacing
    }

    private var defaultSelectableSpan: CGFloat {
        CGFloat(selectableTickCount - 1) * (tickWidth + tickSpacing)
    }

    var body: some View {
        GeometryReader { proxy in
            let selectableSpan = selectableSpan(for: proxy.size.width)

            VStack(spacing: labelSpacing) {
                tickScale
                    .frame(width: proxy.size.width, height: scaleHeight)
                    .mask(edgeFadeMask(width: proxy.size.width))
                    .clipped()

                labels(selectableSpan: selectableSpan)
                    .frame(width: proxy.size.width, height: labelHeight)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(locationX: gesture.location.x, width: proxy.size.width)
                    }
            )
        }
        .frame(height: scaleHeight + labelSpacing + labelHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Доля кэшбэка")
        .accessibilityValue("\(Int(value)) процентов")
        .onChange(of: selectedValueIndex) { oldIndex, newIndex in
            guard oldIndex != newIndex else {
                return
            }

            addTrail(from: oldIndex, to: newIndex)
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

    private var tickScale: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: tickSpacing) {
                ForEach(0..<tickCount, id: \.self) { index in
                    Capsule()
                        .fill(tickColor(at: index))
                        .frame(width: tickWidth, height: tickHeight(at: index))
                }
            }

            if showsTrailEffect {
                TimelineView(.animation) { timeline in
                    trailLayer(at: timeline.date)
                }
            }
        }
        .frame(width: tickGroupWidth, height: scaleHeight, alignment: .bottom)
    }

    private func labels(selectableSpan: CGFloat) -> some View {
        ZStack {
            scaleLabel(minValue.formattedPercentValue)
                .offset(x: -selectableSpan / 2)

            scaleLabel(((minValue + maxValue) / 2).formattedPercentValue)

            scaleLabel(maxValue.formattedPercentValue)
                .offset(x: selectableSpan / 2)
        }
    }

    private func scaleLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .tracking(-0.08)
            .foregroundStyle(TUIColors.secondaryText)
            .lineLimit(1)
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
        index <= selectedTickIndex ? TUIColors.blue : Color.white.opacity(0.12)
    }

    private func tickHeight(at index: Int) -> CGFloat {
        if index == selectedTickIndex {
            return 36
        }

        if index == selectableTickOffset
            || index == selectableTickOffset + (selectableTickCount - 1) / 2
            || index == selectableTickOffset + selectableTickCount - 1 {
            return 28
        }

        return 20
    }

    private func selectableSpan(for width: CGFloat) -> CGFloat {
        min(defaultSelectableSpan, max(tickWidth, width - 32))
    }

    private func updateValue(locationX: CGFloat, width: CGFloat) {
        let selectableSpan = selectableSpan(for: width)
        let startX = (width - selectableSpan) / 2
        let progress = min(max((locationX - startX) / selectableSpan, 0), 1)
        let rawValue = minValue + Double(progress) * range
        let steppedValue = minValue + ((rawValue - minValue) / step).rounded() * step
        value = min(max(steppedValue, minValue), maxValue)
    }

    private func trailLayer(at date: Date) -> some View {
        HStack(alignment: .bottom, spacing: tickSpacing) {
            ForEach(0..<tickCount, id: \.self) { index in
                if let height = trailHeight(at: index, date: date) {
                    Capsule()
                        .fill(TUIColors.blue)
                        .frame(width: tickWidth, height: height)
                } else {
                    Color.clear
                        .frame(width: tickWidth, height: 1)
                }
            }
        }
    }

    private func trailHeight(at index: Int, date: Date) -> CGFloat? {
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
                index: selectableTickOffset + index,
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

private extension Double {
    var formattedPercentValue: String {
        let rounded = Int(self.rounded())
        return "\(rounded)"
    }
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

private struct CharityIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TUIColors.accentYellow)
                .frame(width: 24, height: 31)
                .rotationEffect(.degrees(-35))
                .offset(x: -5, y: -3)

            Circle()
                .fill(TUIColors.magenta)
                .frame(width: 23, height: 23)
                .offset(x: 6, y: 8)
        }
        .frame(width: 40, height: 40)
    }
}

private struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
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
    static let card = Color(hex: 0x1C1C1E)
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
