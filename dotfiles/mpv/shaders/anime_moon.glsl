//!HOOK MAIN
//!BIND HOOKED
//!DESC Moonlight Anime

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(0.4, 0.6, 0.9), 0.2); color.rgb = pow(color.rgb, vec3(1.1));
    color = clamp(color, 0.0, 1.0);
    return color;
}
