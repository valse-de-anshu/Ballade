import os
import re

SHADERS_DIR = os.path.expanduser("~/.config/mpv/shaders")
INPUT_CONF = os.path.expanduser("~/.config/mpv/input.conf")
os.makedirs(SHADERS_DIR, exist_ok=True)

GLSL_TEMPLATE = """//!HOOK MAIN
//!BIND HOOKED
//!DESC {desc}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    {logic}
    color = clamp(color, 0.0, 1.0);
    return color;
}
"""

new_shaders = [
    # The Keepers from previous
    ("cyberpunk", "Cyberpunk", "vec3 hsv = vec3(1.2, 1.5, 1.1) * color.rgb; color.rgb = mix(color.rgb, hsv, 0.5);", "Cool Shaders"),
    ("edgedetect", "Edge Detect", "vec2 p = HOOKED_pt; vec4 n=HOOKED_tex(HOOKED_pos+vec2(0,p.y)); vec4 s=HOOKED_tex(HOOKED_pos+vec2(0,-p.y)); vec4 e=HOOKED_tex(HOOKED_pos+vec2(p.x,0)); vec4 w=HOOKED_tex(HOOKED_pos+vec2(-p.x,0)); vec4 edges=abs(n-s)+abs(e-w); color = vec4(edges.rgb * 2.0, 1.0);", "Cool Shaders"),
    ("vibrant", "Ultra Vibrant", "color.rgb = mix(vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114))), color.rgb, 1.8);", "Cool Shaders"),
    ("crt", "Fake CRT", "float scanline = sin(HOOKED_pos.y * 800.0) * 0.04; color.rgb -= scanline;", "Cool Shaders"),
    ("deepblue", "Deep Blue Night", "color.rgb *= vec3(0.4, 0.6, 1.2); color.rgb = mix(color.rgb, vec3(0.0), 0.2);", "Ambient & Foggy"),
    ("coldnight", "Cold Ambient Night", "color.rgb = mix(color.rgb, vec3(0.5, 0.6, 0.9), 0.3); color.rgb -= 0.1;", "Ambient & Foggy"),

    # The chosen cinematic ones
    ("horror", "Horror Movie (Saw/Ring)", "color.rgb = mix(vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), color.rgb, 0.4); color.rgb *= vec3(0.6, 0.8, 0.5); color.rgb = pow(color.rgb, vec3(1.3));", "Cinematic"),
    ("bluehour", "Perfect Blue Hour", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(vec3(0.1, 0.2, 0.5) * lum, color.rgb, 0.4); color.rgb += vec3(0.0, 0.05, 0.15);", "Cinematic"),
    ("goldenhour", "Warm Golden Hour", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(color.rgb, vec3(1.0, 0.6, 0.2) * lum, 0.3); color.rgb += vec3(0.1, 0.05, 0.0);", "Cinematic"),
    ("bleachbypass", "Bleach Bypass (War Movie)", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); vec3 lum3 = vec3(lum); vec3 blend = vec3(1.0) - (vec3(1.0)-color.rgb)*(vec3(1.0)-lum3); color.rgb = mix(color.rgb, blend, 0.6); color.rgb = mix(vec3(lum), color.rgb, 0.4);", "Cinematic"),
]

menu_lines = ["\n# --- Custom Shaders Menu ---"]
for fid, title, logic, category in new_shaders:
    path = os.path.join(SHADERS_DIR, f"{fid}.glsl")
    with open(path, "w") as f:
        f.write(GLSL_TEMPLATE.replace("{desc}", title).replace("{logic}", logic))
    menu_lines.append(f'ctrl+x change-list glsl-shaders toggle "~~/shaders/{fid}.glsl" #! Shaders > {category} > {title}')
menu_lines.append('ctrl+x change-list glsl-shaders clr "" #! Shaders > ❌ Clear All Shaders\n')

with open(INPUT_CONF, "r") as f:
    content = f.read()

# Replace existing shaders menu
new_content = re.sub(r'# --- Custom Shaders Menu ---.*?# --- Default UOSC Menu Restore ---', 
                     '\\n'.join(menu_lines) + '\\n\\n# --- Default UOSC Menu Restore ---', 
                     content, flags=re.DOTALL)

with open(INPUT_CONF, "w") as f:
    f.write(new_content)

print("Generated new cinematic shaders.")
