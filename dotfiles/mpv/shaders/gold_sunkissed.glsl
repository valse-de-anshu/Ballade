//!HOOK MAIN
//!BIND HOOKED
//!DESC Sun-kissed

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(color.rgb, vec3(1.0,0.9,0.7), 0.15); color.rgb *= vec3(1.05, 1.0, 0.95);
    color = clamp(color, 0.0, 1.0);
    return color;
}
