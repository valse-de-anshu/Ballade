//!HOOK MAIN
//!BIND HOOKED
//!DESC Perfect Deep Color (Sweet Spot)

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)); vec3 chroma = color.rgb - l; float l_deep = mix(l, l*l*(3.0 - 2.0*l), 0.5); color.rgb = l_deep + chroma * 1.35;
    color = clamp(color, 0.0, 1.0);
    return color;
}
