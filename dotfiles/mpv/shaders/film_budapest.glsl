//!HOOK MAIN
//!BIND HOOKED
//!DESC Grand Budapest

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(1.1, 0.8, 0.9), 0.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
