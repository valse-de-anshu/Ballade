//!HOOK MAIN
//!BIND HOOKED
//!DESC Frosted Glass

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec4 blur = vec4(0.0); vec2 p = HOOKED_pt; for(float i=-2.0; i<=2.0; i+=1.0){ for(float j=-2.0; j<=2.0; j+=1.0){ blur += HOOKED_tex(HOOKED_pos + vec2(i,j)*p*2.0); } } blur /= 25.0;color.rgb = mix(color.rgb, blur.rgb, 0.9); float l = dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.6);
    color = clamp(color, 0.0, 1.0);
    return color;
}
