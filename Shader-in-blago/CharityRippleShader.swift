//
// CharityRippleShader.swift
// Shader-in-blago
//

import SwiftUI
import UIKit

struct RippleCenterPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint?

    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        if let nextValue = nextValue() {
            value = nextValue
        }
    }
}

struct CharityRipplePalette {
    let base: SIMD3<Float>
    let glow: SIMD3<Float>
    let edge: SIMD3<Float>

    func interpolated(to target: CharityRipplePalette, progress: Float) -> CharityRipplePalette {
        let t = min(max(progress, 0.0), 1.0)
        return CharityRipplePalette(
            base: Self.mix(base, target.base, t),
            glow: Self.mix(glow, target.glow, t),
            edge: Self.mix(edge, target.edge, t)
        )
    }

    static func colors(for value: Int) -> CharityRipplePalette {
        let value = min(max(value, 0), 100)
        return CharityRipplePalette(
            base: baseColor(for: value),
            glow: glowColor(for: value),
            edge: edgeColor(for: value)
        )
    }

    private static func baseColor(for value: Int) -> SIMD3<Float> {
        switch value {
        case 55:
            return adjustColor(SIMD3<Float>(0.5373, 0.4039, 0.8745), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 60:
            return adjustColor(SIMD3<Float>(0.6157, 0.4039, 0.8745), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 65:
            return adjustColor(SIMD3<Float>(0.6941, 0.4039, 0.8745), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 70:
            return adjustColor(SIMD3<Float>(0.7725, 0.4039, 0.8745), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 75:
            return adjustColor(SIMD3<Float>(0.8510, 0.4039, 0.8745), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 80:
            return adjustColor(SIMD3<Float>(0.8745, 0.4039, 0.8196), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 85:
            return adjustColor(SIMD3<Float>(0.8549, 0.4392, 0.7176), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 90:
            return adjustColor(SIMD3<Float>(0.8588, 0.4392, 0.7098), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 95:
            return adjustColor(SIMD3<Float>(0.8588, 0.4431, 0.7059), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 100:
            return adjustColor(SIMD3<Float>(0.8549, 0.4471, 0.7020), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 50:
            return adjustColor(baseColor(at: 0.7), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        default:
            let progress = Float(value) / 100.0
            return hueShifted(boostSaturationIfNeeded(baseColor(at: progress), value: value), progress: progress)
        }
    }

    private static func glowColor(for value: Int) -> SIMD3<Float> {
        switch value {
        case 55:
            return adjustColor(SIMD3<Float>(0.6667, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 60:
            return adjustColor(SIMD3<Float>(0.7255, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 65:
            return adjustColor(SIMD3<Float>(0.7882, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 70:
            return adjustColor(SIMD3<Float>(0.8471, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 75:
            return adjustColor(SIMD3<Float>(0.9098, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 80:
            return adjustColor(SIMD3<Float>(0.9686, 0.6353, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 85:
            return adjustColor(SIMD3<Float>(0.9608, 0.6824, 0.9098), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 90:
            return adjustColor(SIMD3<Float>(0.9647, 0.6824, 0.9059), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 95:
            return adjustColor(SIMD3<Float>(0.9647, 0.6863, 0.9020), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 100:
            return adjustColor(SIMD3<Float>(0.9608, 0.6902, 0.8980), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 50:
            return adjustColor(SIMD3<Float>(0.6353, 0.6667, 1.0), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        default:
            let progress = Float(value) / 100.0
            return hueShifted(boostSaturationIfNeeded(glowColor(at: progress), value: value), progress: progress)
        }
    }

    private static func edgeColor(for value: Int) -> SIMD3<Float> {
        switch value {
        case 55:
            return adjustColor(SIMD3<Float>(0.4353, 0.1922, 0.6471), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 60:
            return adjustColor(SIMD3<Float>(0.5098, 0.1922, 0.6471), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 65:
            return adjustColor(SIMD3<Float>(0.5882, 0.1922, 0.6471), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 70:
            return adjustColor(SIMD3<Float>(0.6471, 0.1922, 0.6314), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 75:
            return adjustColor(SIMD3<Float>(0.6471, 0.1922, 0.5569), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 80:
            return adjustColor(SIMD3<Float>(0.6471, 0.1922, 0.4784), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 85:
            return adjustColor(SIMD3<Float>(0.6078, 0.2471, 0.4196), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 90:
            return adjustColor(SIMD3<Float>(0.6118, 0.2471, 0.4118), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        case 95:
            return adjustColor(SIMD3<Float>(0.6078, 0.2510, 0.4078), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 100:
            return adjustColor(SIMD3<Float>(0.6039, 0.2549, 0.4039), saturationMultiplier: satMultiplier(for: 90), brightnessMultiplier: 1.0)
        case 50:
            return adjustColor(edgeColor(at: 0.7), saturationMultiplier: satMultiplier(for: value), brightnessMultiplier: 1.0)
        default:
            let progress = Float(value) / 100.0
            return hueShifted(boostSaturationIfNeeded(edgeColor(at: progress), value: value), progress: progress)
        }
    }

    private static func baseColor(at progress: Float) -> SIMD3<Float> {
        symmetricColor(
            progress: progress,
            center: baseColorAtZero(),
            lowA: SIMD3<Float>(0.76, 0.24, 1.0),
            lowB: SIMD3<Float>(0.0, 0.68, 1.0),
            highA: SIMD3<Float>(0.88, 0.42, 0.64),
            highB: SIMD3<Float>(0.96, 0.35, 0.66)
        )
    }

    private static func glowColor(at progress: Float) -> SIMD3<Float> {
        symmetricColor(
            progress: progress,
            center: glowColorAtZero(),
            lowA: SIMD3<Float>(0.70, 0.38, 0.88),
            lowB: SIMD3<Float>(0.15, 0.84, 1.0),
            highA: SIMD3<Float>(0.92, 0.50, 0.70),
            highB: SIMD3<Float>(0.98, 0.44, 0.74)
        )
    }

    private static func edgeColor(at progress: Float) -> SIMD3<Float> {
        symmetricColor(
            progress: progress,
            center: edgeColorAtZero(),
            lowA: SIMD3<Float>(0.46, 0.14, 0.72),
            lowB: SIMD3<Float>(0.0, 0.36, 0.74),
            highA: SIMD3<Float>(0.72, 0.18, 0.45),
            highB: SIMD3<Float>(0.9, 0.28, 0.58)
        )
    }

    private static func symmetricColor(
        progress: Float,
        center: SIMD3<Float>,
        lowA: SIMD3<Float>,
        lowB: SIMD3<Float>,
        highA: SIMD3<Float>,
        highB: SIMD3<Float>
    ) -> SIMD3<Float> {
        let p = min(max(progress, 0.0), 1.0)
        if p <= 0.5 {
            let t = ((0.5 - p) / 0.5) * 0.6
            let eased = smoothstep(t)
            let lowTarget = mix(lowA, lowB, eased)
            return mix(center, lowTarget, eased)
        }

        let t = (p - 0.5) / 0.5
        let eased = smoothstep(t)
        let highTarget = mix(highA, highB, eased)
        return mix(center, highTarget, eased)
    }

    private static func baseColorAtZero() -> SIMD3<Float> {
        mix(SIMD3<Float>(0.0, 0.68, 1.0), SIMD3<Float>(0.76, 0.24, 1.0), 0.4)
    }

    private static func glowColorAtZero() -> SIMD3<Float> {
        mix(SIMD3<Float>(0.15, 0.84, 1.0), SIMD3<Float>(0.70, 0.38, 0.88), 0.4)
    }

    private static func edgeColorAtZero() -> SIMD3<Float> {
        mix(SIMD3<Float>(0.0, 0.36, 0.74), SIMD3<Float>(0.46, 0.14, 0.72), 0.4)
    }

    private static func adjustColor(_ rgb: SIMD3<Float>, saturationMultiplier: CGFloat, brightnessMultiplier: CGFloat) -> SIMD3<Float> {
        let uiColor = UIColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1.0)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return rgb
        }

        let adjusted = UIColor(
            hue: hue,
            saturation: min(max(saturation * saturationMultiplier, 0.0), 1.0),
            brightness: min(max(brightness * brightnessMultiplier, 0.0), 1.0),
            alpha: 1.0
        )
        return simdColor(from: adjusted)
    }

    private static func hueShifted(_ rgb: SIMD3<Float>, progress: Float) -> SIMD3<Float> {
        let uiColor = UIColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1.0)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return rgb
        }

        let p = min(max(progress, 0.0), 1.0)
        let delta = (p - 0.5) / 0.5
        let maxShift: CGFloat = 0.06
        var effectiveShift = maxShift * CGFloat(delta)
        if p > 0.5 && p < 0.65 {
            effectiveShift = maxShift * CGFloat((p - 0.5) / 0.15) * 0.25
        }

        var newHue = hue + effectiveShift
        if newHue < 0 { newHue += 1 }
        if newHue > 1 { newHue -= 1 }

        var out = simdColor(from: UIColor(hue: newHue, saturation: saturation, brightness: brightness, alpha: 1.0))
        if p > 0.5 && p < 0.65 {
            out = mix(out, SIMD3<Float>(0.72, 0.46, 0.90), 0.08)
        }
        return out
    }

    private static func simdColor(from color: UIColor) -> SIMD3<Float> {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }

    private static func satMultiplier(for value: Int) -> CGFloat {
        if value == 50 {
            return 0.9
        }

        let clamped = max(50, min(value, 100))
        let steps = (clamped - 50) / 5
        return 0.9 + CGFloat(steps) * 0.01
    }

    private static func boostSaturationIfNeeded(_ rgb: SIMD3<Float>, value: Int) -> SIMD3<Float> {
        guard value > 50 && value < 100 else { return rgb }
        return adjustColor(rgb, saturationMultiplier: 1.02, brightnessMultiplier: 0.98)
    }

    private static func smoothstep(_ x: Float) -> Float {
        let t = min(max(x, 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }

    private static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
        a + (b - a) * t
    }
}

struct CharityRippleShaderSettings {
    var baseEnergy: Float = 0.84
    var energyCurve: Float = 1.0
    var climaxStart: Float = 0.92
    var climaxStrength: Float = 0.2
    var pulseStrength: Float = 0.08
    var pulseDecay: Float = 0.8
    var pulseDelay: Float = 0.08
    var waveSpeed: Float = 0.09
    var waveAmp: Float = 0.112
    var brightnessBase: Float = 1.19
    var glowSize: Float = 0.25
    var glowIntensity: Float = 0.77
    var blurAmount: Float = 0.10
    var coreWidth: Float = 0.216
    var coreHeight: Float = 0.27
    var coreRoundness: Float = 2.1
    var noiseStrength: Float = 0.25
    var noiseSize: Float = 0.2
    var distortion: Float = 0.3
    var distortionAnimation: Float = 0.5
    var rayIntensity: Float = 0.15
    var rayCount: Float = 10.0
    var raySpeed: Float = 0.12
    var raySharpness: Float = 4.2
    var ovalColor: SIMD3<Float> = .init(0.109, 0.109, 0.118)
    var backgroundColor: SIMD3<Float> = .init(0.109, 0.109, 0.118)
}

@available(iOS 17.0, *)
struct CharityRippleShaderBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let percentCenter: CGPoint
    let hasPercentCenter: Bool
    let progress: Float
    let pulseBoost: Float
    let breatheBoost: Float
    let shockStartDate: Date?
    let shockDuration: Float
    let shockWidth: Float
    let shockIntensity: Float
    let transitionStartDate: Date?
    let transitionDuration: Float
    let donationValue: Int
    let settings: CharityRippleShaderSettings
    let paletteStart: CharityRipplePalette
    let paletteEnd: CharityRipplePalette
    let paletteTransitionStartDate: Date?
    let paletteTransitionDuration: Float

    @State private var startDate = Date()

    private var shaderOvalColor: SIMD3<Float> {
        colorScheme == .dark ? settings.ovalColor : SIMD3<Float>(0.98, 0.98, 0.99)
    }

    private var shaderNoiseStrength: Float {
        colorScheme == .dark ? settings.noiseStrength : settings.noiseStrength * 0.12
    }

    private var highValueGlowScale: Float {
        guard donationValue >= 80 else { return 1.0 }
        let t = Float(donationValue - 80) / 20.0
        return mix(1.0, 0.78, smoothstep(t))
    }

    private var intensityScale: Float {
        let p = min(max(progress, 0.0), 1.0)
        let base: Float = 0.8
        if p <= 0.35 {
            return cappedOpacity(mix(0.0, base, smoothstep(p / 0.35)))
        }

        if p <= 0.5 {
            return cappedOpacity(base)
        }

        return cappedOpacity(mix(base, 1.0, smoothstep((p - 0.5) / 0.5)))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let frame = proxy.frame(in: .global)
                let center = shaderCenter(in: frame, size: size)
                let time = Float(timeline.date.timeIntervalSince(startDate))
                let shockElapsed = shockStartDate.map { Float(timeline.date.timeIntervalSince($0)) } ?? -1.0
                let transitionElapsed = transitionStartDate.map { Float(timeline.date.timeIntervalSince($0)) } ?? -1.0
                let palette = currentPalette(at: timeline.date)
                let backgroundColor = shaderBackgroundColor(from: palette.base)
                let rayIntensity = settings.rayIntensity * rayBoost * highValueGlowScale

                Rectangle()
                    .fill(Color.black)
                    .colorEffect(
                        ShaderLibrary.charityRipple(
                            .float2(size),
                            .float(time),
                            .float2(center.x, center.y),
                            .float4(progress, pulseBoost, settings.baseEnergy, settings.energyCurve),
                            .float4(settings.waveSpeed, settings.waveAmp, settings.brightnessBase, settings.climaxStart),
                            .float4(settings.glowSize, settings.glowIntensity * highValueGlowScale, settings.climaxStrength, settings.pulseStrength),
                            .float4(settings.blurAmount, settings.coreWidth, settings.coreHeight, settings.coreRoundness),
                            .float4(shaderNoiseStrength, settings.noiseSize, 0.0, 0.0),
                            .float4(rayIntensity, settings.rayCount, settings.raySpeed, settings.raySharpness),
                            .float3(palette.base.x, palette.base.y, palette.base.z),
                            .float3(palette.glow.x, palette.glow.y, palette.glow.z),
                            .float3(palette.edge.x, palette.edge.y, palette.edge.z),
                            .float3(shaderOvalColor.x, shaderOvalColor.y, shaderOvalColor.z),
                            .float3(backgroundColor.x, backgroundColor.y, backgroundColor.z),
                            .float(breatheBoost),
                            .float(colorScheme == .dark ? 0.0 : 1.0),
                            .float(settings.distortion),
                            .float(settings.distortionAnimation),
                            .float4(shockElapsed, shockDuration, shockWidth, shockIntensity),
                            .float4(transitionElapsed, transitionDuration, 1.0, 0.0)
                        )
                    )
                    .opacity(Double(intensityScale))
                    .frame(width: size.width, height: size.height)
                    .drawingGroup()
            }
        }
    }

    private var rayBoost: Float {
        if progress < 0.6 {
            return 0.8
        }

        if progress < 0.85 {
            return 0.8 + 0.5 * smoothstep((progress - 0.6) / 0.25)
        }

        return 1.3 + 0.2 * smoothstep((progress - 0.85) / 0.15)
    }

    private func shaderCenter(in frame: CGRect, size: CGSize) -> CGPoint {
        guard hasPercentCenter else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        let x = (percentCenter.x - frame.minX) / max(size.width, 1)
        let y = (percentCenter.y - frame.minY) / max(size.height, 1)
        return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }

    private func currentPalette(at date: Date) -> CharityRipplePalette {
        guard let startDate = paletteTransitionStartDate else {
            return paletteEnd
        }

        let duration = max(paletteTransitionDuration, 0.001)
        let rawProgress = Float(date.timeIntervalSince(startDate)) / duration
        return paletteStart.interpolated(to: paletteEnd, progress: smoothstep(rawProgress))
    }

    private func shaderBackgroundColor(from baseColor: SIMD3<Float>) -> SIMD3<Float> {
        colorScheme == .dark ? settings.backgroundColor : tintedBackground(from: baseColor, saturationMultiplier: 0.2)
    }

    private func tintedBackground(from rgb: SIMD3<Float>, saturationMultiplier: CGFloat) -> SIMD3<Float> {
        let uiColor = UIColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1.0)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let tint = UIColor(
                hue: hue,
                saturation: min(max(saturation * saturationMultiplier, 0.0), 1.0),
                brightness: 1.0,
                alpha: 1.0
            )
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            tint.getRed(&r, green: &g, blue: &b, alpha: &a)
            return SIMD3<Float>(Float(r), Float(g), Float(b))
        }

        return SIMD3<Float>(1.0, 1.0, 1.0)
    }

    private func cappedOpacity(_ value: Float) -> Float {
        colorScheme == .dark ? min(value, 0.85) : value
    }

    private func smoothstep(_ x: Float) -> Float {
        let t = min(max(x, 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }
}
