//!HOOK MAIN
//!BIND HOOKED
//!DESC Golden Hour Anime

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(1.2, 0.7, 0.3), 0.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
