//!HOOK MAIN
//!BIND HOOKED
//!DESC John Wick

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.0,0.1,0.3), vec3(0.8,0.1,0.6), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.6);
    color = clamp(color, 0.0, 1.0);
    return color;
}
