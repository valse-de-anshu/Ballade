//!HOOK MAIN
//!BIND HOOKED
//!DESC Cyberpunk

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec3 hsv = vec3(1.2, 1.5, 1.1) * color.rgb; color.rgb = mix(color.rgb, hsv, 0.5);
    color = clamp(color, 0.0, 1.0);
    return color;
}
