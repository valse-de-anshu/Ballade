//!HOOK MAIN
//!BIND HOOKED
//!DESC Lucid

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec2 p2=HOOKED_pt*3.0; vec3 c; c.r = HOOKED_tex(HOOKED_pos+vec2(p2.x,0)).r; c.g = HOOKED_tex(HOOKED_pos).g; c.b = HOOKED_tex(HOOKED_pos+vec2(-p2.x,0)).b; color.rgb=c; vec4 blur = vec4(0.0); vec2 p = HOOKED_pt; for(float i=-2.0; i<=2.0; i+=1.0){ for(float j=-2.0; j<=2.0; j+=1.0){ blur += HOOKED_tex(HOOKED_pos + vec2(i,j)*p*2.0); } } blur /= 25.0;color.rgb=mix(color.rgb, blur.rgb, 0.4);
    color = clamp(color, 0.0, 1.0);
    return color;
}
