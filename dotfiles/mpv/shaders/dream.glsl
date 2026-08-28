//!HOOK MAIN
//!BIND HOOKED
//!DESC Dreamy Glow Effect

vec4 hook() {
    vec4 c = vec4(0.0);
    vec2 p = HOOKED_pos;
    
    // Spread for the glow (3 pixels)
    vec2 offset = vec2(4.0 / HOOKED_size.x, 4.0 / HOOKED_size.y);
    
    // Sample surrounding pixels
    c += HOOKED_tex(p + vec2(-offset.x, -offset.y));
    c += HOOKED_tex(p + vec2(0.0, -offset.y));
    c += HOOKED_tex(p + vec2(offset.x, -offset.y));
    c += HOOKED_tex(p + vec2(-offset.x, 0.0));
    c += HOOKED_tex(p + vec2(offset.x, 0.0));
    c += HOOKED_tex(p + vec2(-offset.x, offset.y));
    c += HOOKED_tex(p + vec2(0.0, offset.y));
    c += HOOKED_tex(p + vec2(offset.x, offset.y));
    
    // Average the samples
    c /= 8.0;
    
    vec4 orig = HOOKED_tex(p);
    
    // Add the blurred background on top of the original with a soft multiplier
    // This creates that "foggy", "bloom" dream-like aesthetic
    return orig + (c * 0.45);
}
