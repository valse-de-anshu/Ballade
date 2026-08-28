//!HOOK MAIN
//!BIND HOOKED
//!DESC Ufotable Night

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = pow(color.rgb, vec3(1.3)); color.rgb *= vec3(1.1, 1.0, 1.2);
    color = clamp(color, 0.0, 1.0);
    return color;
}
