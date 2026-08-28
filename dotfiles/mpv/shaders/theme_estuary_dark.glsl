//!HOOK MAIN
//!BIND HOOKED
//!DESC Atelier Estuary Dark

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)); float ld = pow(l, 1.58); vec3 abyss = vec3(0.055, 0.082, 0.070); vec3 jungle = vec3(0.096, 0.152, 0.128); vec3 alpine = vec3(0.165, 0.280, 0.218); vec3 moss = vec3(0.300, 0.445, 0.350); vec3 canopy = vec3(0.480, 0.565, 0.510); vec3 ramp = mix(abyss, mix(jungle, mix(alpine, mix(moss, canopy, clamp((ld - 0.48) / 0.52, 0.0, 1.0)), clamp((ld - 0.18) / 0.30, 0.0, 1.0)), clamp(ld / 0.18, 0.0, 1.0)), ld); vec3 warm = vec3(0.58, 0.30, 0.16); vec3 cool = vec3(0.14, 0.38, 0.30); vec3 chroma = color.rgb - vec3(l); vec3 themed = ramp + (chroma.r * warm + chroma.g * alpine * 1.5 + chroma.b * cool) * 0.38; color.rgb = clamp(themed, vec3(0.04, 0.07, 0.06), vec3(0.60, 0.68, 0.63));
    color = clamp(color, 0.0, 1.0);
    return color;
}
