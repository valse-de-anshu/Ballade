//!HOOK MAIN
//!BIND HOOKED
//!DESC Soft Sunset

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(color.rgb, vec3(1.0,0.7,0.6)*l, 0.3) + vec3(0.05,0.02,0.0);
    color = clamp(color, 0.0, 1.0);
    return color;
}
