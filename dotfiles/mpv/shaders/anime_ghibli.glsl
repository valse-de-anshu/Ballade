//!HOOK MAIN
//!BIND HOOKED
//!DESC Ghibli Greens

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(color.rgb, vec3(1.1, 1.0, 0.8)*l, 0.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
