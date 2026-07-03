//
// CharityRipple.metal
// Shader-in-blago
//
// Adapted from:
// https://github.com/jackjack970602/charity-last-shader/tree/march-31
//

#include <metal_stdlib>
using namespace metal;

static float sdSuperellipse(float2 p, float2 size, float n) {
    float2 q = abs(p) / size;
    float d = pow(pow(q.x, n) + pow(q.y, n), 1.0 / n);
    return (d - 1.0) * min(size.x, size.y);
}

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float3 desaturateColor(float3 color, float amount) {
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    return mix(color, float3(luma), clamp(amount, 0.0, 1.0));
}

[[ stitchable ]] half4 charityRipple(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float2 center,
    float4 phase,
    float4 wave,
    float4 glow,
    float4 shape,
    float4 noise,
    float4 rays,
    float3 baseColor,
    float3 glowColor,
    float3 edgeColor,
    float3 ovalColor,
    float3 backgroundColor,
    float breatheBoost,
    float isLightModeParam,
    float distortion,
    float distortionAnimation,
    float4 shock
) {
    if (color.a <= 0.0h) {
        return color;
    }

    float progress = phase.x;
    float pulse = phase.y;
    float baseEnergy = phase.z;
    float energyCurve = phase.w;

    float waveSpeedParam = wave.x;
    float waveAmpParam = wave.y;
    float brightnessBase = wave.z;
    float climaxStart = wave.w;

    float glowSizeParam = glow.x;
    float glowIntensityParam = glow.y;
    float climaxStrength = glow.z;
    float pulseStrength = glow.w;

    float blurAmount = shape.x;
    float coreWidth = shape.y;
    float coreHeight = shape.z;
    float coreRoundness = shape.w;

    float noiseStrengthParam = noise.x;
    float noiseSizeParam = noise.y;
    float rayIntensityParam = rays.x;
    float rayCountParam = rays.y;
    float raySpeedParam = rays.z;
    float raySharpnessParam = rays.w;

    float2 uv = position / size;
    float2 uvOriginal = uv;
    float invAr = size.y / size.x;

    float progressClamped = clamp(progress, 0.0, 1.0);
    float energy = smoothstep(0.0, 1.0, progressClamped);
    energy = pow(energy, max(0.01, energyCurve));
    energy = mix(baseEnergy, 1.0, energy);
    float tension = smoothstep(0.15, 0.85, progressClamped);
    float climax = smoothstep(clamp(climaxStart, 0.5, 0.99), 1.0, progressClamped);

    float breatheAmp = mix(0.015, 0.045, energy);
    float breathe = 1.0 + breatheAmp * sin(time * 1.5) + breatheBoost;

    float2 p = float2(center.x - uv.x, (center.y - uv.y) * invAr);
    float angle = atan2(p.y, p.x);
    float distortionNoise1 = sin(angle * 3.0 + time * 0.5) * 0.5 + 0.5;
    float distortionNoise2 = sin(angle * 5.0 - time * 0.3) * 0.5 + 0.5;
    float distortionNoise3 = sin(angle * 7.0 + time * 0.7) * 0.5 + 0.5;
    float combinedDistortion = (distortionNoise1 * 0.5 + distortionNoise2 * 0.3 + distortionNoise3 * 0.2);

    float breathePhase = sin(time * 1.5);
    float animatedDistortion1 = sin(angle * 4.0 + breathePhase * 3.14159) * 0.5 + 0.5;
    float animatedDistortion2 = sin(angle * 6.0 - breathePhase * 3.14159 * 0.7) * 0.5 + 0.5;
    float combinedAnimatedDistortion = (animatedDistortion1 * 0.6 + animatedDistortion2 * 0.4);

    float totalDistortion = combinedDistortion * distortion + (combinedAnimatedDistortion - 0.5) * distortionAnimation;

    float2 animPhase = float2(uv.x * 6.0 + time * 0.9, uv.y * 6.0 - time * 0.7);
    float animX = sin(animPhase.x) * 0.5 + 0.5;
    float animY = sin(animPhase.y) * 0.5 + 0.5;
    float animField = (animX * 0.6 + animY * 0.4 - 0.5) * distortionAnimation;
    float distortionField = 1.0 + (totalDistortion + animField) * 0.06;
    uv = center + (uv - center) * distortionField;
    p = float2(center.x - uv.x, (center.y - uv.y) * invAr);
    angle = atan2(p.y, p.x);

    float distortionFactor = 1.0 + totalDistortion * 0.195;
    float2 superellipseSize = float2(coreWidth, coreHeight) * breathe * distortionFactor;

    float distToOval = sdSuperellipse(p, superellipseSize, coreRoundness);
    float dist = length(p);

    float r = -max(distToOval, 0.0);
    float waveSpeedScaled = waveSpeedParam * mix(0.8, 1.05, energy);
    float waveSignal = sin((r + time * waveSpeedScaled) / 0.067);
    float waveNorm = max(0.0, waveSignal);
    waveNorm = smoothstep(0.0, 1.0, waveNorm);
    waveNorm = pow(waveNorm, 1.5);
    float brightness = (brightnessBase * energy) + waveNorm * (waveAmpParam * energy);

    float isLightMode = clamp(isLightModeParam, 0.0, 1.0);
    float topZone = 1.0 - smoothstep(0.04, 0.62, uvOriginal.y);
    float rimProximity = 1.0 - smoothstep(0.0, 0.18, abs(distToOval));
    float darkBaseMix = pow(topZone, 0.55) * mix(0.45, 1.0, rimProximity) * 0.9;
    float baseTopMix = darkBaseMix * (1.0 - isLightMode);
    baseTopMix = clamp(baseTopMix, 0.0, 1.0);
    float3 lightModeTopColor = desaturateColor(baseColor, 0.1);
    float3 baseTopColor = mix(float3(1.0), lightModeTopColor, isLightMode);
    float3 verticalBaseColor = mix(baseColor, baseTopColor, baseTopMix);
    float3 rippleColor = verticalBaseColor * brightness;

    float blurScaled = mix(blurAmount * 1.15, blurAmount * 0.85, tension);
    float ovalMask = smoothstep(blurScaled, -blurScaled, distToOval);

    float glowSizeScaled = mix(glowSizeParam * 1.2, glowSizeParam * 0.9, tension);
    float glowIntensityScaled = glowIntensityParam * energy;
    glowIntensityScaled += pulse * pulseStrength;
    glowIntensityScaled += climax * climaxStrength;
    glowIntensityScaled *= breathe;
    float glowField = smoothstep(glowSizeScaled, 0.0, max(distToOval, 0.0));
    glowField = pow(glowField, 1.5) * glowIntensityScaled;

    float edgeFactor = smoothstep(0.0, 0.4, dist);
    float3 warmGlow = mix(glowColor, float3(1.0, 0.45, 0.15), 0.25);
    float3 finalGlowColor = mix(warmGlow, edgeColor, edgeFactor);

    float rayCountSafe = max(rayCountParam, 1.0);
    float raySharpnessSafe = max(raySharpnessParam, 1.0);
    float rayPhase = angle * rayCountSafe + time * raySpeedParam;
    float rayPattern = abs(sin(rayPhase));
    rayPattern = pow(rayPattern, raySharpnessSafe);
    float rayRadial = smoothstep(0.18, 0.32, dist) * (1.0 - smoothstep(0.55, 0.9, dist));
    float rayBreath = 0.92 + 0.08 * sin(time * 1.2);
    float rayEnergy = rayIntensityParam * 0.4 * (0.6 + 0.4 * energy) * (1.0 + pulse * 0.25) * rayBreath;
    float rayField = rayPattern * rayRadial * rayEnergy;
    float3 rayColor = mix(glowColor, edgeColor, 0.6);

    float3 colorWithGlow = rippleColor * breathe + finalGlowColor * glowField + rayColor * rayField;
    float3 colorBeforeFade = mix(colorWithGlow, ovalColor, ovalMask);

    float fadeToBackground = smoothstep(0.35, 0.7, dist);
    float3 darkTopBackground = float3(28.0 / 255.0, 28.0 / 255.0, 30.0 / 255.0);
    float3 darkModeBackground = darkTopBackground;
    float3 lightModeBackground = backgroundColor;
    float3 resolvedBackground = mix(darkModeBackground, lightModeBackground, isLightMode);
    float3 finalColor = mix(colorBeforeFade, resolvedBackground, fadeToBackground);

    float shockElapsed = shock.x;
    float shockDuration = max(shock.y, 0.001);
    float shockWidth = shock.z;
    float shockIntensity = shock.w;
    if (shockElapsed >= 0.0 && shockElapsed <= shockDuration) {
        float shockT = clamp(shockElapsed / shockDuration, 0.0, 1.0);
        shockT = pow(shockT, 0.6);
        float coreRadius = max(coreWidth, coreHeight) * 1.1;
        float shockPos = mix(0.0, coreRadius * 1.95, shockT);
        float shockWidthScaled = max(shockWidth, 0.01) * coreRadius;
        float edgeDist = max(distToOval, 0.0);
        float band = 1.0 - smoothstep(0.0, shockWidthScaled, abs(edgeDist - shockPos));
        band = smoothstep(0.0, 1.0, band);
        float edgeFade = 1.0 - smoothstep(0.35, 0.86, dist);
        band *= edgeFade;
        float3 shockColor = mix(glowColor, edgeColor, 0.5);
        finalColor += shockColor * band * shockIntensity;
    }

    float noiseScale = 1.0 / max(noiseSizeParam, 0.001);
    float noiseField = hash21(position * noiseScale);
    float noiseStrengthScaled = noiseStrengthParam * (0.4 + 0.6 * energy);
    float3 noiseColor = float3(0.0);
    finalColor = mix(finalColor, noiseColor, noiseField * noiseStrengthScaled);

    return half4(half3(finalColor), half(1.0)) * color.a;
}
