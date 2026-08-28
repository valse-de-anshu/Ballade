//!HOOK MAIN
//!BIND HOOKED
//!DESC Midsommar

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(1.2, 1.1, 0.9); color.rgb = pow(color.rgb, vec3(0.85));
    color = clamp(color, 0.0, 1.0);
    return color;
}
