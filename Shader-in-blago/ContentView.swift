//
//  ContentView.swift
//  Shader-in-blago
//
//  Created by Pavel Korostelev on 02.07.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var activeSheet: CashbackRoute?
    @State private var showingFundSelection = false
    @State private var showingDoneSummary = false
    @State private var showingBackHint = false
    @State private var blackShare = 100.0
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
        NavigationStack {
            ZStack {
                TUIColors.background
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        header
                            .padding(.horizontal, 16)
                            .padding(.top, 36)

                        cards
                            .padding(.top, 36)
                    }
                    .padding(.bottom, 144)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                floatingAction
            }
            .navigationDestination(isPresented: $showingFundSelection) {
                FundSelectionView(selectedFund: $selectedFund)
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
            .alert("Прототип", isPresented: $showingBackHint) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text("В продукте эта кнопка закрывает экран выбора кэшбэка.")
            }
            .alert("Готово", isPresented: $showingDoneSummary) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(doneSummary)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button {
                showingBackHint = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(TUIColors.primaryText)
            }
            .buttonStyle(GlassCircleButtonStyle())
            .accessibilityLabel("Назад")

            Spacer()
        }
        .frame(height: 44)
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
                showingFundSelection = true
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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TUIColors.background
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Text("В какой фонд?")
                        .font(.system(size: 30, weight: .bold))
                        .tracking(0.36)
                        .foregroundStyle(TUIColors.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)

                    LazyVStack(spacing: 4) {
                        ForEach(CharityFund.all) { fund in
                            CharityFundRow(fund: fund) {
                                selectedFund = fund.title
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(TUIColors.primaryText)
            }
            .buttonStyle(GlassCircleButtonStyle())
            .accessibilityLabel("Назад")

            Spacer()
        }
        .frame(height: 44)
    }
}

private struct CharityFundRow: View {
    let fund: CharityFund
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(CardPressButtonStyle())
        .accessibilityHint("Выбрать фонд")
    }
}

private struct CharityFund: Identifiable {
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
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.sheetTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(TUIColors.primaryText)

                    Text(route.sheetSubtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(TUIColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TUIColors.primaryText)
                }
                .buttonStyle(GlassCircleButtonStyle(size: 36))
                .accessibilityLabel("Закрыть")
            }

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

private struct GlassCircleButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
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
