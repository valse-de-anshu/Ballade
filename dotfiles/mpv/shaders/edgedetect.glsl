//!HOOK MAIN
//!BIND HOOKED
//!DESC Edge Detect

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec2 p = HOOKED_pt; vec4 n=HOOKED_tex(HOOKED_pos+vec2(0,p.y)); vec4 s=HOOKED_tex(HOOKED_pos+vec2(0,-p.y)); vec4 e=HOOKED_tex(HOOKED_pos+vec2(p.x,0)); vec4 w=HOOKED_tex(HOOKED_pos+vec2(-p.x,0)); vec4 edges=abs(n-s)+abs(e-w); color = vec4(edges.rgb * 2.0, 1.0);
    color = clamp(color, 0.0, 1.0);
    return color;
}
