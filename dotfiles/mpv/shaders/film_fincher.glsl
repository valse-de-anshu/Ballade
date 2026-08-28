//!HOOK MAIN
//!BIND HOOKED
//!DESC Fincher Noir

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb *= vec3(0.8, 0.9, 0.6); color.rgb = pow(color.rgb, vec3(1.2)); float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.5);
    color = clamp(color, 0.0, 1.0);
    return color;
}
