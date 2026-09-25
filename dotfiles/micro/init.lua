-- ~/.config/micro/init.lua
-- Atelier Estuary · micro init.lua
-- Custom Lua automation, QoL helpers, and plugin hooks

local micro    = import("micro")
local config   = import("micro/config")
local buffer   = import("micro/buffer")
local shell    = import("micro/shell")
local util     = import("micro/util")

-- ── On startup ───────────────────────────────────────────────────────────────
function init()
    -- Ensure the colorscheme persists across reopens
    config.RegisterCommonOption("initlua", "colorscheme", "atelier-estuary")
end

-- ── Status bar helper: show word count in status ─────────────────────────────
function wordCount(bp)
    local txt  = util.String(bp.Buf:Bytes())
    local words = 0
    for _ in txt:gmatch("%S+") do words = words + 1 end
    micro.InfoBar():Message("Words: " .. words)
    return true
end

-- ── Insert current date (ISO 8601) ───────────────────────────────────────────
function insertDate(bp)
    local date = os.date("%Y-%m-%d")
    bp.Buf:Insert(bp.Cursor.Loc, date)
    return true
end

-- ── Insert current datetime ───────────────────────────────────────────────────
function insertDateTime(bp)
    local dt = os.date("%Y-%m-%dT%H:%M:%S")
    bp.Buf:Insert(bp.Cursor.Loc, dt)
    return true
end

-- ── Duplicate selection or line ───────────────────────────────────────────────
function duplicateLineOrSel(bp)
    local c = bp.Cursor
    if c:HasSelection() then
        local sel = util.String(c:GetSelection())
        bp.Buf:Insert(c.CurSelection[2], sel)
    else
        local line = util.String(bp.Buf:Line(c.Y))
        bp.Buf:Insert(buffer.Loc(0, c.Y + 1), line .. "\n")
    end
    return true
end

-- ── Strip trailing whitespace on save ─────────────────────────────────────────
function onSave(bp)
    -- micro handles this via rmtrailingws option; hook kept for future use
    return true
end

-- ── Auto-create parent dirs when saving a new file ──────────────────────────
function preSave(bp)
    local path = bp.Buf.Path
    if path ~= "" then
        local dir = path:match("(.+)/[^/]*$")
        if dir then
            shell.RunCommand("mkdir -p " .. dir)
        end
    end
    return true
end

-- ── Trim all trailing newlines on save ───────────────────────────────────────
function onBufferOpen(buf)
    -- Set per-buffer options based on filetype
    local ft = buf:FileType()
    if ft == "markdown" or ft == "text" then
        buf.Settings["softwrap"]  = true
        buf.Settings["wordwrap"]  = true
        buf.Settings["ruler"]     = false
    end
end

-- ── Quick grep in current dir ─────────────────────────────────────────────────
function grepCursor(bp)
    local c    = bp.Cursor
    local word = ""
    if c:HasSelection() then
        word = util.String(c:GetSelection())
    else
        c:SelectWord()
        word = util.String(c:GetSelection())
        c:ResetSelection()
    end
    if word ~= "" then
        micro.InfoBar():Prompt("grep: ", word, "Search", nil, function(resp, cancelled)
            if not cancelled and resp ~= "" then
                shell.RunInteractiveShell("grep -rn '" .. resp .. "' .", false, false)
            end
        end)
    end
    return true
end

-- ── Reload config ─────────────────────────────────────────────────────────────
function reloadConfig(bp)
    config.ResetAll()
    micro.InfoBar():Message("Config reloaded!")
    return true
end
