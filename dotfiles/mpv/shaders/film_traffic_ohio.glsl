//!HOOK MAIN
//!BIND HOOKED
//!DESC Traffic (Ohio)

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(0.4, 0.6, 1.3); color.rgb = pow(color.rgb, vec3(1.1));
    color = clamp(color, 0.0, 1.0);
    return color;
}
