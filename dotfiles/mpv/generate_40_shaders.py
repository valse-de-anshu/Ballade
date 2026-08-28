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

shaders = [
    # The Original 10 Keepers
    ("cyberpunk", "Cyberpunk", "vec3 hsv = vec3(1.2, 1.5, 1.1) * color.rgb; color.rgb = mix(color.rgb, hsv, 0.5);", "Original Keepers"),
    ("edgedetect", "Edge Detect", "vec2 p = HOOKED_pt; vec4 n=HOOKED_tex(HOOKED_pos+vec2(0,p.y)); vec4 s=HOOKED_tex(HOOKED_pos+vec2(0,-p.y)); vec4 e=HOOKED_tex(HOOKED_pos+vec2(p.x,0)); vec4 w=HOOKED_tex(HOOKED_pos+vec2(-p.x,0)); vec4 edges=abs(n-s)+abs(e-w); color = vec4(edges.rgb * 2.0, 1.0);", "Original Keepers"),
    ("vibrant", "Ultra Vibrant", "color.rgb = mix(vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114))), color.rgb, 1.8);", "Original Keepers"),
    ("crt", "Fake CRT", "float scanline = sin(HOOKED_pos.y * 800.0) * 0.04; color.rgb -= scanline;", "Original Keepers"),
    ("deepblue", "Deep Blue Night", "color.rgb *= vec3(0.4, 0.6, 1.2); color.rgb = mix(color.rgb, vec3(0.0), 0.2);", "Original Keepers"),
    ("coldnight", "Cold Ambient Night", "color.rgb = mix(color.rgb, vec3(0.5, 0.6, 0.9), 0.3); color.rgb -= 0.1;", "Original Keepers"),
    ("horror", "Horror Movie (Saw/Ring)", "color.rgb = mix(vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), color.rgb, 0.4); color.rgb *= vec3(0.6, 0.8, 0.5); color.rgb = pow(color.rgb, vec3(1.3));", "Original Keepers"),
    ("bluehour", "Perfect Blue Hour", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(vec3(0.1, 0.2, 0.5) * lum, color.rgb, 0.4); color.rgb += vec3(0.0, 0.05, 0.15);", "Original Keepers"),
    ("goldenhour", "Warm Golden Hour", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); color.rgb = mix(color.rgb, vec3(1.0, 0.6, 0.2) * lum, 0.3); color.rgb += vec3(0.1, 0.05, 0.0);", "Original Keepers"),
    ("bleachbypass", "Bleach Bypass (War Movie)", "float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114)); vec3 lum3 = vec3(lum); vec3 blend = vec3(1.0) - (vec3(1.0)-color.rgb)*(vec3(1.0)-lum3); color.rgb = mix(color.rgb, blend, 0.6); color.rgb = mix(vec3(lum), color.rgb, 0.4);", "Original Keepers"),
]

# Dreamcore (5)
blur_logic = "vec4 blur = vec4(0.0); vec2 p = HOOKED_pt; for(float i=-2.0; i<=2.0; i+=1.0){ for(float j=-2.0; j<=2.0; j+=1.0){ blur += HOOKED_tex(HOOKED_pos + vec2(i,j)*p*2.0); } } blur /= 25.0;"
shaders.append(("dream_softglow", "Soft Glow", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.6); color.rgb += vec3(0.05);", "Dreamcore"))
shaders.append(("dream_pink", "Pink Dream", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.7); color.rgb *= vec3(1.1, 0.9, 1.0); color.rgb += vec3(0.1, 0.0, 0.05);", "Dreamcore"))
shaders.append(("dream_memory", "Memory Bleed", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.8); float l = dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.5) * 1.2;", "Dreamcore"))
shaders.append(("dream_euphoria", "Euphoria", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.5); color.rgb = mix(color.rgb, vec3(0.6, 0.4, 0.8), 0.2) + vec3(0.0, 0.0, 0.1);", "Dreamcore"))
shaders.append(("dream_lucid", "Lucid", "vec2 p2=HOOKED_pt*3.0; vec3 c; c.r = HOOKED_tex(HOOKED_pos+vec2(p2.x,0)).r; c.g = HOOKED_tex(HOOKED_pos).g; c.b = HOOKED_tex(HOOKED_pos+vec2(-p2.x,0)).b; color.rgb=c; " + blur_logic + "color.rgb=mix(color.rgb, blur.rgb, 0.4);", "Dreamcore"))

# Frosted Ambient (5)
shaders.append(("frost_glass", "Frosted Glass", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.9); float l = dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.6);", "Frosted Ambient"))
shaders.append(("frost_winter", "Winter Chill", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.6); color.rgb = mix(color.rgb, vec3(0.7, 0.8, 1.0), 0.3);", "Frosted Ambient"))
shaders.append(("frost_shadows", "Iced Shadows", blur_logic + "float l = dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(color.rgb*color.rgb, blur.rgb, clamp(l*2.0, 0.0, 1.0));", "Frosted Ambient"))
shaders.append(("frost_morning", "Morning Frost", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.5); color.rgb = color.rgb * 1.1 + vec3(0.05, 0.08, 0.1);", "Frosted Ambient"))
shaders.append(("frost_arctic", "Arctic Ambient", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.7) * vec3(0.6, 0.9, 1.0);", "Frosted Ambient"))

# Golden Hour (5)
shaders.append(("gold_sunset", "Late Sunset", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(color.rgb*0.8, vec3(1.2,0.6,0.2)*l, 0.4);", "Golden Hour"))
shaders.append(("gold_pastel", "Soft Sunset", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(color.rgb, vec3(1.0,0.7,0.6)*l, 0.3) + vec3(0.05,0.02,0.0);", "Golden Hour"))
shaders.append(("gold_desert", "Desert Heat", "color.rgb = pow(color.rgb, vec3(1.2)); color.rgb *= vec3(1.2, 1.0, 0.6);", "Golden Hour"))
shaders.append(("gold_magic", "Magic Hour", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(color.rgb, vec3(1.1,0.8,0.4)*l, 0.3); color.rgb *= 1.1;", "Golden Hour"))
shaders.append(("gold_sunkissed", "Sun-kissed", "color.rgb = mix(color.rgb, vec3(1.0,0.9,0.7), 0.15); color.rgb *= vec3(1.05, 1.0, 0.95);", "Golden Hour"))

# Film Grades (25)
grades = [
    ("film_matrix", "The Matrix", "color.rgb *= vec3(0.6, 1.1, 0.6); color.rgb = pow(color.rgb, vec3(1.1));"),
    ("film_madmax", "Mad Max", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.1,0.3,0.5), vec3(1.2,0.6,0.1), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.7);"),
    ("film_wick", "John Wick", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.0,0.1,0.3), vec3(0.8,0.1,0.6), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.6);"),
    ("film_fincher", "Fincher Noir", "color.rgb *= vec3(0.8, 0.9, 0.6); color.rgb = pow(color.rgb, vec3(1.2)); float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.5);"),
    ("film_amelie", "Amelie", "color.rgb *= vec3(1.2, 1.1, 0.6); color.rgb = mix(color.rgb, vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), 0.2);"),
    ("film_twilight", "Twilight", "color.rgb = mix(color.rgb, vec3(0.4, 0.6, 0.8), 0.4);"),
    ("film_wes", "Wes Anderson", "color.rgb = mix(color.rgb, vec3(1.1, 1.0, 0.9), 0.2); float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.7);"),
    ("film_ryan", "Saving Private Ryan", "color.rgb = mix(vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), color.rgb, 0.3); color.rgb *= vec3(0.8, 0.9, 0.8); color.rgb = pow(color.rgb, vec3(1.3));"),
    ("film_joker", "Joker", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.1,0.3,0.2), vec3(1.0,0.6,0.1), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.6);"),
    ("film_blade2049", "Blade Runner 2049", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.0,0.3,0.4), vec3(1.2,0.4,0.0), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.7);"),
    ("film_moonlight", "Moonlight", "color.rgb *= vec3(0.5, 0.6, 1.3); color.rgb = pow(color.rgb, vec3(1.2));"),
    ("film_300", "300", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(l), vec3(1.0,0.8,0.4)*l, 0.8); color.rgb = pow(color.rgb, vec3(1.5));"),
    ("film_oppenheimer", "Oppenheimer", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(color.rgb, vec3(1.0, 0.8, 0.6)*l, 0.6); color.rgb = pow(color.rgb, vec3(1.3));"),
    ("film_budapest", "Grand Budapest", "color.rgb = mix(color.rgb, vec3(1.1, 0.8, 0.9), 0.2);"),
    ("film_bay", "Transformers (Bayhem)", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.0,0.4,0.6), vec3(1.2,0.5,0.0), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.8); color.rgb = pow(color.rgb, vec3(1.2));"),
    ("film_traffic_mex", "Traffic (Mexico)", "color.rgb *= vec3(1.3, 1.1, 0.4); color.rgb = pow(color.rgb, vec3(1.2)); float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.6);"),
    ("film_traffic_ohio", "Traffic (Ohio)", "color.rgb *= vec3(0.4, 0.6, 1.3); color.rgb = pow(color.rgb, vec3(1.1));"),
    ("film_seven", "Seven", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.4); color.rgb *= vec3(0.9, 0.9, 0.7); color.rgb = pow(color.rgb, vec3(1.4));"),
    ("film_drive", "Drive", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.4,0.0,0.4), vec3(0.0,0.8,0.8), l); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.5);"),
    ("film_dune", "Dune", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(l), color.rgb, 0.5); color.rgb *= vec3(1.2, 0.9, 0.6);"),
    ("film_batman", "The Batman", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb=mix(vec3(0.0), vec3(1.2,0.3,0.1), clamp((l-0.2)*1.5, 0.0, 1.0)); color.rgb=mix(HOOKED_tex(HOOKED_pos).rgb, color.rgb, 0.6); color.rgb = pow(color.rgb, vec3(1.3));"),
    ("film_arrival", "Arrival", "color.rgb = mix(color.rgb, vec3(0.6, 0.7, 0.8), 0.3); float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.6);"),
    ("film_parasite", "Parasite", "color.rgb *= vec3(0.8, 1.0, 0.8); color.rgb = pow(color.rgb, vec3(1.2));"),
    ("film_midsommar", "Midsommar", "color.rgb *= vec3(1.2, 1.1, 0.9); color.rgb = pow(color.rgb, vec3(0.85));"),
    ("film_1917", "1917", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.4); color.rgb *= vec3(0.9, 0.8, 0.7);")
]
for fid, title, logic in grades:
    shaders.append((fid, title, logic, "Film Grades"))

# Anime Specific (10)
anime_grades = [
    ("anime_shinkai", "Shinkai Skies", "color.rgb = mix(color.rgb, vec3(0.5, 0.8, 1.1), 0.15); color.rgb = pow(color.rgb, vec3(0.9));"),
    ("anime_ghibli", "Ghibli Greens", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(color.rgb, vec3(1.1, 1.0, 0.8)*l, 0.2);"),
    ("anime_ufotable", "Ufotable Night", "color.rgb = pow(color.rgb, vec3(1.3)); color.rgb *= vec3(1.1, 1.0, 1.2);"),
    ("anime_edge", "Edgerunners Neon", "color.rgb = mix(color.rgb, vec3(1.0, 0.2, 0.6), 0.1); color.rgb *= vec3(1.2, 0.9, 1.1);"),
    ("anime_retro", "Retro 90s Anime", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.3); color.rgb *= vec3(1.05, 0.95, 0.9); color.rgb = mix(color.rgb, vec3(0.5), 0.1);"),
    ("anime_cel", "Vibrant Cel-Shade", "color.rgb = pow(color.rgb, vec3(1.4)); color.rgb *= vec3(1.3, 1.3, 1.3);"),
    ("anime_shoujo", "Pastel Shoujo", blur_logic + "color.rgb = mix(color.rgb, blur.rgb, 0.4); color.rgb = mix(color.rgb, vec3(1.0, 0.8, 0.9), 0.15);"),
    ("anime_mecha", "Mecha Grit", "color.rgb = mix(color.rgb, vec3(dot(color.rgb, vec3(0.3,0.59,0.11))), 0.4); color.rgb *= vec3(0.9, 1.0, 0.9);"),
    ("anime_golden", "Golden Hour Anime", "color.rgb = mix(color.rgb, vec3(1.2, 0.7, 0.3), 0.2);"),
    ("anime_moon", "Moonlight Anime", "color.rgb = mix(color.rgb, vec3(0.4, 0.6, 0.9), 0.2); color.rgb = pow(color.rgb, vec3(1.1));")
]
for fid, title, logic in anime_grades:
    shaders.append((fid, title, logic, "Anime Aesthetics"))

# 2D Art & Themes
estuary_logic = "float l = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)); float ld = pow(l, 1.58); vec3 abyss = vec3(0.055, 0.082, 0.070); vec3 jungle = vec3(0.096, 0.152, 0.128); vec3 alpine = vec3(0.165, 0.280, 0.218); vec3 moss = vec3(0.300, 0.445, 0.350); vec3 canopy = vec3(0.480, 0.565, 0.510); vec3 ramp = mix(abyss, mix(jungle, mix(alpine, mix(moss, canopy, clamp((ld - 0.48) / 0.52, 0.0, 1.0)), clamp((ld - 0.18) / 0.30, 0.0, 1.0)), clamp(ld / 0.18, 0.0, 1.0)), ld); vec3 warm = vec3(0.58, 0.30, 0.16); vec3 cool = vec3(0.14, 0.38, 0.30); vec3 chroma = color.rgb - vec3(l); vec3 themed = ramp + (chroma.r * warm + chroma.g * alpine * 1.5 + chroma.b * cool) * 0.38; color.rgb = clamp(themed, vec3(0.04, 0.07, 0.06), vec3(0.60, 0.68, 0.63));"

anime2d_grades = [
    ("a2d_dark", "Dark Fantasy", "float l=dot(color.rgb, vec3(0.3,0.59,0.11)); color.rgb = mix(vec3(l), color.rgb, 0.5); color.rgb = pow(color.rgb, vec3(1.3));", "2D Art & Anime4K"),
    ("a2d_perfectdeep", "Perfect Deep Color (Sweet Spot)", "float l = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)); vec3 chroma = color.rgb - l; float l_deep = mix(l, l*l*(3.0 - 2.0*l), 0.5); color.rgb = l_deep + chroma * 1.35;", "2D Art & Anime4K"),
    ("theme_estuary_dark", "Atelier Estuary Dark", estuary_logic, "Themes & Aesthetics")
]
for fid, title, logic, cat in anime2d_grades:
    shaders.append((fid, title, logic, cat))

menu_lines = ["\n# --- Custom Shaders Menu ---"]
menu_lines.append('ctrl+1 no-osd change-list glsl-shaders set "~~/shaders/anime4k/Anime4K_Clamp_Highlights.glsl:~~/shaders/anime4k/Anime4K_Restore_CNN_M.glsl:~~/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl:~~/shaders/anime4k/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/anime4k/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/anime4k/Anime4K_Upscale_CNN_x2_S.glsl" ; show-text "Anime4K: Mode A (Fast) Activated!" #! Shaders > Activate Anime4K Upscaling')

for fid, title, logic, category in shaders:
    path = os.path.join(SHADERS_DIR, f"{fid}.glsl")
    with open(path, "w") as f:
        f.write(GLSL_TEMPLATE.replace("{desc}", title).replace("{logic}", logic))
    menu_lines.append(f'_ change-list glsl-shaders toggle "~~/shaders/{fid}.glsl" #! Shaders > {category} > {title}')

menu_lines.append('ctrl+2 no-osd change-list glsl-shaders clr "" ; show-text "Shaders: Cleared" #! Shaders > Clear All Shaders\n')

with open(INPUT_CONF, "r") as f:
    content = f.read()

# Replace existing shaders menu
new_content = re.sub(r'# --- Custom Shaders Menu ---.*?# --- Default UOSC Menu Restore ---', 
                     '\\n'.join(menu_lines) + '\\n\\n# --- Default UOSC Menu Restore ---', 
                     content, flags=re.DOTALL)

with open(INPUT_CONF, "w") as f:
    f.write(new_content)

print(f"Generated {len(shaders)} premium shaders.")
