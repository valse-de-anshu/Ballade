//!HOOK MAIN
//!BIND HOOKED
//!DESC Oppenheimer

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(color.rgb, vec3(1.0, 0.8, 0.6)*l, 0.6); color.rgb = pow(color.rgb, vec3(1.3));
    color = clamp(color, 0.0, 1.0);
    return color;
}
