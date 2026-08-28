//!HOOK MAIN
//!BIND HOOKED
//!DESC Moonlight

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(0.5, 0.6, 1.3); color.rgb = pow(color.rgb, vec3(1.2));
    color = clamp(color, 0.0, 1.0);
    return color;
}
