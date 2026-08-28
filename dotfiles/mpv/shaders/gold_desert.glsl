//!HOOK MAIN
//!BIND HOOKED
//!DESC Desert Heat

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = pow(color.rgb, vec3(1.2)); color.rgb *= vec3(1.2, 1.0, 0.6);
    color = clamp(color, 0.0, 1.0);
    return color;
}
