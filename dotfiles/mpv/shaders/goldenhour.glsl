//!HOOK MAIN
//!BIND HOOKED
//!DESC Warm Golden Hour

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(color.rgb, vec3(1.0, 0.6, 0.2) * lum, 0.3); color.rgb += vec3(0.1, 0.05, 0.0);
    color = clamp(color, 0.0, 1.0);
    return color;
}
