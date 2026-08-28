//!HOOK MAIN
//!BIND HOOKED
//!DESC Amelie

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(1.2, 1.1, 0.6); color.rgb = mix(color.rgb, vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), 0.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
