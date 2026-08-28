//!HOOK MAIN
//!BIND HOOKED
//!DESC Horror Movie (Saw/Ring)

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = mix(vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), color.rgb, 0.4); color.rgb *= vec3(0.6, 0.8, 0.5); color.rgb = pow(color.rgb, vec3(1.3));
    color = clamp(color, 0.0, 1.0);
    return color;
}
