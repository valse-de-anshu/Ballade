//!HOOK MAIN
//!BIND HOOKED
//!DESC Vibrant Cel-Shade

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = pow(color.rgb, vec3(1.4)); color.rgb *= vec3(1.3, 1.3, 1.3);
    color = clamp(color, 0.0, 1.0);
    return color;
}
