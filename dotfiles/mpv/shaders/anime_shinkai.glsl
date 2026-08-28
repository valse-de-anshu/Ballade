//!HOOK MAIN
//!BIND HOOKED
//!DESC Shinkai Skies

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(0.5, 0.8, 1.1), 0.15); color.rgb = pow(color.rgb, vec3(0.9));
    color = clamp(color, 0.0, 1.0);
    return color;
}
