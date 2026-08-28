//!HOOK MAIN
//!BIND HOOKED
//!DESC Morning Frost

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec4 blur = vec4(0.0); vec2 p = HOOKED_pt; for(float i=-2.0; i<=2.0; i+=1.0){ for(float j=-2.0; j<=2.0; j+=1.0){ blur += HOOKED_tex(HOOKED_pos + vec2(i,j)*p*2.0); } } blur /= 25.0;color.rgb = mix(color.rgb, blur.rgb, 0.5); color.rgb = color.rgb * 1.1 + vec3(0.05, 0.08, 0.1);
    color = clamp(color, 0.0, 1.0);
    return color;
}
