#!/usr/bin/env bash
# ==============================================================================
# 🧪 Ballade Sandbox Test & Diagnostic Runner
# Runs all theming engines, dotfile deployments, and preset switches in an
# isolated, temporary filesystem sandbox without touching your real system files.
# ==============================================================================

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESET_TO_TEST="${1:-all}"

echo "================================================================="
echo "🧪 Ballade Sandbox Test & Diagnostic Suite"
echo "📂 Workspace: $REPO_ROOT"
echo "🎨 Preset target: $PRESET_TO_TEST"
echo "================================================================="

python3 -c "
import os, sys, subprocess, tempfile, shutil

repo_root = '$REPO_ROOT'
preset_target = '$PRESET_TO_TEST'

with tempfile.TemporaryDirectory(prefix='ballade_sandbox_', ignore_cleanup_errors=True) as sandbox:
    print(f'\n📦 Created Isolated Sandbox: {sandbox}')
    
    # 1. Mock user environment isolated inside the sandbox
    mock_env = os.environ.copy()
    mock_env['HOME'] = sandbox
    mock_env['XDG_CONFIG_HOME'] = os.path.join(sandbox, '.config')
    mock_env['XDG_CACHE_HOME'] = os.path.join(sandbox, '.cache')
    mock_env['XDG_STATE_HOME'] = os.path.join(sandbox, '.local/state')
    mock_env['XDG_DATA_HOME'] = os.path.join(sandbox, '.local/share')
    
    # Pre-create standard XDG structure
    os.makedirs(os.path.join(sandbox, '.config'), exist_ok=True)
    os.makedirs(os.path.join(sandbox, '.local/share'), exist_ok=True)
    os.makedirs(os.path.join(sandbox, '.cache'), exist_ok=True)

    # 2. Test setup.sh in sandbox
    print('\n[Step 1] Executing setup.sh in sandbox...')
    res_setup = subprocess.run(['bash', os.path.join(repo_root, 'setup.sh')], env=mock_env, capture_output=True, text=True)
    if res_setup.returncode == 0:
        print('  ✅ setup.sh completed with exit code 0')
    else:
        print(f'  ❌ setup.sh failed (code {res_setup.returncode}):\n{res_setup.stderr}')
        sys.exit(1)

    # 3. Test Theme Presets
    all_presets = ['purple', 'green', 'golden', 'orange', 'pink', 'red', 'blue', 'grayscale']
    test_list = all_presets if preset_target == 'all' else [preset_target]

    print(f'\n[Step 2] Testing Theme Presets: {test_list}...')
    for p in test_list:
        res_p = subprocess.run(
            ['bash', os.path.join(repo_root, 'scripts/theming/apply-theme-preset.sh'), p],
            env=mock_env, capture_output=True, text=True
        )
        if res_p.returncode == 0:
            print(f'  ✅ Preset {p:<10} -> SUCCESS')
        else:
            print(f'  ❌ Preset {p:<10} -> FAILED (code {res_p.returncode})\n{res_p.stderr}')

    # 4. Verify Generated Configurations & Assets
    print('\n[Step 3] Verifying Generated Files & Sizes in Sandbox...')
    files_to_check = [
        ('.config/Vencord/themes/DiscordPlus.theme.css', 'Discord+ Theme'),
        ('.config/Vencord/settings/quickCss.css', 'Vencord QuickCSS'),
        ('.config/joplin-desktop/userchrome.css', 'Joplin UI Theme'),
        ('.config/joplin-desktop/userstyle.css', 'Joplin Rendered Notes'),
        ('.config/micro/colorschemes/ballade.micro', 'Micro Syntax Colors'),
        ('.config/fastfetch/config.jsonc', 'Fastfetch Telemetry'),
        ('.config/Kvantum/kvantum.kvconfig', 'Kvantum Qt Config'),
        ('.config/matugen/config.toml', 'Matugen Color Config'),
        ('.config/kdeglobals', 'KDE Globals'),
        ('.local/share/konsole/Quickshell.colorscheme', 'Konsole Theme'),
        ('.local/share/color-schemes/PurpleDark.colors', 'KDE Color Scheme'),
        ('.config/rmpc/config.ron', 'rmpc Base Config'),
        ('.config/rmpc/themes/purple.ron', 'rmpc Purple Theme'),
        ('.local/bin/rmpc-run', 'rmpc-run Script'),
        ('.local/bin/rmpc-fetch-lyrics', 'rmpc-fetch-lyrics Script')
    ]

    all_passed = True
    for rel_path, desc in files_to_check:
        full_path = os.path.join(sandbox, rel_path)
        if os.path.exists(full_path):
            sz = os.path.getsize(full_path)
            print(f'  ✅ {desc:<22} [{rel_path}] ({sz} bytes)')
        else:
            print(f'  ❌ {desc:<22} [MISSING: {rel_path}]')
            all_passed = False

    print('\n' + '='*65)
    if all_passed:
        print('🎉 ALL SANDBOX DIAGNOSTIC CHECKS PASSED 100%!')
    else:
        print('⚠️ SOME SANDBOX CHECKS FAILED - REVIEW OUTPUT ABOVE')
    print('='*65)
"
