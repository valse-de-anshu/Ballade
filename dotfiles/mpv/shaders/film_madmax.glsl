//!HOOK MAIN
//!BIND HOOKED
//!DESC Mad Max

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.1,0.3,0.5), vec3(1.2,0.6,0.1), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.7);
    color = clamp(color, 0.0, 1.0);
    return color;
}
