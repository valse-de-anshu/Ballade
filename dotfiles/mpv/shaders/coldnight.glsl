//!HOOK MAIN
//!BIND HOOKED
//!DESC Cold Ambient Night

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(0.5, 0.6, 0.9), 0.3); color.rgb -= 0.1;
    color = clamp(color, 0.0, 1.0);
    return color;
}
