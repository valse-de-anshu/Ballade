//!HOOK MAIN
//!BIND HOOKED
//!DESC Ultra Vibrant

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114))), color.rgb, 1.8);
    color = clamp(color, 0.0, 1.0);
    return color;
}
