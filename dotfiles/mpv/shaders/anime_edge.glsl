//!HOOK MAIN
//!BIND HOOKED
//!DESC Edgerunners Neon

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(1.0, 0.2, 0.6), 0.1); color.rgb *= vec3(1.2, 0.9, 1.1);
    color = clamp(color, 0.0, 1.0);
    return color;
}
