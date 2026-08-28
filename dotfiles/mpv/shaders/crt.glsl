//!HOOK MAIN
//!BIND HOOKED
//!DESC Fake CRT

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float scanline = sin(HOOKED_pos.y * 800.0) * 0.04; color.rgb -= scanline;
    color = clamp(color, 0.0, 1.0);
    return color;
}
