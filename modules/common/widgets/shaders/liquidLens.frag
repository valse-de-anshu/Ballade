#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 radii;
    vec4 wash;
    float qt_Opacity;
    vec2 size;
    float rimWidth;
    float pull;
    float split;
    float haze;
    float vividness;
    float sheen;
    vec2 flares;
    vec2 hangs;
    float edge;
};

layout(binding = 1) uniform sampler2D backdrop;

float roundedDist(vec2 p, vec2 half_, vec4 radii) {
    float r = p.x > 0.0 ? (p.y > 0.0 ? radii.z : radii.y) : (p.y > 0.0 ? radii.w : radii.x);
    r = min(r, min(half_.x, half_.y));
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float boxDist(vec2 p, vec2 half_) {
    vec2 q = abs(p) - half_;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0)));
}

float filletDist(vec2 p, float s, vec2 center, vec2 boxCenter, vec2 boxHalf) {
    return max(boxDist(p - boxCenter, boxHalf), -(length(p - center) - s));
}

float shapeDist(vec2 p) {
    vec2 q = p + size * 0.5;
    float hang = max(hangs.x, hangs.y);
    bool vert = edge > 1.5;
    float along = vert ? size.y : size.x;
    float depth = (vert ? size.x : size.y) - hang;

    float u = vert ? q.y : q.x;
    float v = edge < 0.5 ? q.y : edge < 1.5 ? size.y - q.y : edge < 2.5 ? q.x : size.x - q.x;

    vec2 lo = edge < 0.5 ? vec2(flares.x, 0.0)
        : edge < 1.5 ? vec2(flares.x, size.y - depth)
        : edge < 2.5 ? vec2(0.0, flares.x)
        : vec2(size.x - depth, flares.x);
    vec2 hi = edge < 0.5 ? vec2(along - flares.y, depth)
        : edge < 1.5 ? vec2(along - flares.y, size.y)
        : edge < 2.5 ? vec2(depth, along - flares.y)
        : vec2(size.x, along - flares.y);
    float d = roundedDist(q - (lo + hi) * 0.5, (hi - lo) * 0.5, radii);

    if (flares.x > 0.0) d = min(d, filletDist(vec2(u, v), flares.x, vec2(0.0, flares.x), vec2(flares.x, flares.x * 0.5), vec2(flares.x, flares.x * 0.5)));
    if (flares.y > 0.0) d = min(d, filletDist(vec2(along - u, v), flares.y, vec2(0.0, flares.y), vec2(flares.y, flares.y * 0.5), vec2(flares.y, flares.y * 0.5)));
    if (hangs.x > 0.0) d = min(d, filletDist(vec2(u, v - depth), hangs.x, vec2(hangs.x), vec2(hangs.x * 0.5, 0.0), vec2(hangs.x * 0.5, hangs.x)));
    if (hangs.y > 0.0) d = min(d, filletDist(vec2(along - u, v - depth), hangs.y, vec2(hangs.y), vec2(hangs.y * 0.5, 0.0), vec2(hangs.y * 0.5, hangs.y)));
    return d;
}

const float GLASS_IOR = 1.5;
const vec2 LIGHT = vec2(-0.6, -0.8);

vec3 backdropAt(vec2 px, float lod) {
    vec2 uv = clamp((px + size * 0.5) / size, vec2(0.002), vec2(0.998));
    return textureLod(backdrop, uv, lod).rgb;
}

vec3 diffuseAt(vec2 px, float lod, float reach) {
    vec3 acc = backdropAt(px, lod) * 2.0;
    for (int i = 0; i < 6; ++i) {
        float a = 1.0471976 * float(i) + 0.3;
        acc += backdropAt(px + vec2(cos(a), sin(a)) * reach, lod);
    }
    return acc / 8.0;
}

float domeSlope(float u) {
    float v = 1.0 - u;
    return min(v / max(sqrt(max(1.0 - v * v, 0.0)), 0.12), 5.0);
}

vec2 bendRay(vec2 outward, float slope, float ior, float travel) {
    vec3 normal = normalize(vec3(outward * slope, 1.0));
    vec3 ray = refract(vec3(0.0, 0.0, -1.0), normal, 1.0 / ior);
    return ray.xy / max(-ray.z, 0.25) * travel;
}

vec3 spectralRainbow(float t) {
    vec3 w = vec3(0.0, 0.333, 0.667);
    return clamp(0.5 + 0.5 * cos(6.2831853 * (t + w)), 0.0, 1.0);
}

void main() {
    vec2 p = qt_TexCoord0 * size - size * 0.5;
    float d = shapeDist(p);
    float cover = clamp(0.5 - d, 0.0, 1.0);
    if (cover <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float depth = max(-d, 0.0);
    vec2 e = vec2(0.8, 0.0);
    vec2 outward = vec2(
        shapeDist(p + e.xy) - shapeDist(p - e.xy),
        shapeDist(p + e.yx) - shapeDist(p - e.yx));
    outward = length(outward) > 1e-4 ? normalize(outward) : vec2(0.0, -1.0);

    float bezel = max(rimWidth, 1.0);
    float u = clamp(depth / bezel, 0.0, 1.0);
    float edgeSlope = domeSlope(u);
    float fall = (1.0 - u) * (1.0 - u);

    // Multi-harmonic gentle liquid ripples across the interior
    vec2 waveP = (p + size * 0.5) * 0.018;
    vec2 fluidRipples = vec2(
        sin(waveP.x * 2.1 + waveP.y * 1.4) * 0.65 + sin(waveP.x * 4.3 - waveP.y * 2.7) * 0.35,
        cos(waveP.x * 1.6 - waveP.y * 2.3) * 0.65 + cos(waveP.x * 3.1 + waveP.y * 3.8) * 0.35
    );

    // Gentle broad meniscus sag across the body
    vec2 normP = p / (max(size, vec2(1.0)) * 0.5);
    vec2 meniscus = -normP * exp(-dot(normP, normP) * 0.6) * 0.25;

    // Body fluid slope smoothly kicks in throughout the glass interior
    vec2 bodySlope = (meniscus + fluidRipples * 0.4) * (pull * 0.045);
    float rimWeight = 1.0 - smoothstep(0.0, bezel, depth);
    vec2 surfaceSlope = outward * edgeSlope + bodySlope * (1.0 - rimWeight * 0.5);

    float slopeMag = length(surfaceSlope);
    vec2 slopeDir = slopeMag > 1e-4 ? surfaceSlope / slopeMag : vec2(0.0, -1.0);

    // Chromatic dispersion spread - active both at the rim and across interior fluid ripples
    float spreadK = split * (0.6 + 2.0 * fall + length(bodySlope) * 3.5);
    vec2 shiftG = bendRay(slopeDir, slopeMag, GLASS_IOR, pull);
    vec2 shiftR = bendRay(slopeDir, slopeMag, GLASS_IOR - spreadK, pull);
    vec2 shiftB = bendRay(slopeDir, slopeMag, GLASS_IOR + spreadK, pull);

    float lod = log2(max(haze, 1.0));
    float reach = haze * 0.6;
    vec3 col;
    col.r = diffuseAt(p + shiftR, lod, reach).r;
    col.g = diffuseAt(p + shiftG, lod, reach).g;
    col.b = diffuseAt(p + shiftB, lod, reach).b;

    // Intermediate spectral taps (Yellow and Cyan) for rich dispersion spectrum
    vec2 shiftY = mix(shiftR, shiftG, 0.5);
    vec2 shiftC = mix(shiftG, shiftB, 0.5);
    vec3 colY = diffuseAt(p + shiftY, lod, reach);
    vec3 colC = diffuseAt(p + shiftC, lod, reach);
    col.r = mix(col.r, colY.r, 0.3);
    col.g = mix(col.g, (colY.g + colC.g) * 0.5, 0.35);
    col.b = mix(col.b, colC.b, 0.3);

    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, vividness);

    // Lighting & specular reflection
    vec2 L = normalize(LIGHT);
    float facing = dot(slopeDir, L);
    float lit = pow(max(facing, 0.0), 1.6);
    float away = pow(max(-facing, 0.0), 2.2);

    float hair = exp(-depth / 1.0);
    float wide = exp(-depth / (bezel * 0.5));
    float rimLight = (hair * (0.2 + 0.75 * lit + 0.25 * away) + wide * 0.14 * lit) * sheen;

    float rimEnv = pow(1.0 - clamp(u, 0.0, 1.0), 2.0);
    vec3 env = backdropAt(p + outward * bezel * 1.2, min(lod + 2.0, 6.0));
    col = mix(col, env * 1.1 + 0.03, clamp(rimEnv * 0.35 * (0.4 + 0.6 * lit), 0.0, 0.5));

    col *= 1.0 - 0.14 * wide * away;

    // Optical rainbow caustics & iridescent water sheen
    float rayDeflect = length(shiftR - shiftB);
    float phase = (depth * 0.05) + dot(p, vec2(0.012, 0.018)) + rayDeflect * 0.15;
    vec3 rainbow = spectralRainbow(phase);

    float rainbowRim = smoothstep(0.0, bezel * 1.5, depth) * (1.0 - smoothstep(bezel * 0.2, bezel * 3.5, depth));
    float rainbowIntensity = (fall * 1.8 + rainbowRim * 1.4 + length(bodySlope) * 1.6) * (split * 4.5) * sheen;
    col += rainbow * rainbowIntensity;

    // Specular highlight with rainbow sheen
    vec3 rimHighlightColor = mix(vec3(1.0), rainbow, clamp(split * 3.5, 0.0, 0.9));
    col += rimHighlightColor * rimLight;

    float top = 1.0 - smoothstep(0.0, size.y * 0.55, p.y + size.y * 0.5);
    col += vec3(0.03 * top * sheen);

    col = mix(col, wash.rgb, wash.a);

    fragColor = vec4(clamp(col, 0.0, 1.0) * cover, cover) * qt_Opacity;
}
