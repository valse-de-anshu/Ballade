//!HOOK MAIN
//!BIND HOOKED
//!DESC 1917

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.4); color.rgb *= vec3(0.9, 0.8, 0.7);
    color = clamp(color, 0.0, 1.0);
    return color;
}
