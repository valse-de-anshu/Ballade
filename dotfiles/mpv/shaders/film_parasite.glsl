//!HOOK MAIN
//!BIND HOOKED
//!DESC Parasite

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(0.8, 1.0, 0.8); color.rgb = pow(color.rgb, vec3(1.2));
    color = clamp(color, 0.0, 1.0);
    return color;
}
