//!HOOK MAIN
//!BIND HOOKED
//!DESC Bleach Bypass (War Movie)

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); vec3 lum3 = vec3(lum); vec3 blend = vec3(1.0) - (vec3(1.0)-color.rgb)*(vec3(1.0)-lum3); color.rgb = mix(color.rgb, blend, 0.6); color.rgb = mix(vec3(lum), color.rgb, 0.4);
    color = clamp(color, 0.0, 1.0);
    return color;
}
