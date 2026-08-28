//!HOOK MAIN
//!BIND HOOKED
//!DESC Deep Blue Night

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(0.4, 0.6, 1.2); color.rgb = mix(color.rgb, vec3(0.0), 0.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
