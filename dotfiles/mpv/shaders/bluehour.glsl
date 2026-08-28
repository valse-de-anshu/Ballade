//!HOOK MAIN
//!BIND HOOKED
//!DESC Perfect Blue Hour

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(vec3(0.1, 0.2, 0.5) * lum, color.rgb, 0.4); color.rgb += vec3(0.0, 0.05, 0.15);
    color = clamp(color, 0.0, 1.0);
    return color;
}
