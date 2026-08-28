//!HOOK MAIN
//!BIND HOOKED
//!DESC Late Sunset

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(color.rgb*0.8, vec3(1.2,0.6,0.2)*l, 0.4);
    color = clamp(color, 0.0, 1.0);
    return color;
}
