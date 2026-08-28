//!HOOK MAIN
//!BIND HOOKED
//!DESC Mecha Grit

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), 0.4); color.rgb *= vec3(0.9, 1.0, 0.9);
    color = clamp(color, 0.0, 1.0);
    return color;
}
