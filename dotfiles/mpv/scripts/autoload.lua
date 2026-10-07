-- Safe, ultra-lightweight autoload: loads next video files in the exact same directory
local utils = require 'mp.utils'

local VIDEO_EXTS = {
    mkv = true, mp4 = true, avi = true, webm = true,
    flv = true, mov = true, m4v = true, ts = true
}

local function get_ext(path)
    return path:match("%.([^%.]+)$")
end

local function autoload_videos()
    local path = mp.get_property("path", "")
    if not path or path == "" or path:find("://") then return end
    local dir, file = utils.split_path(path)
    if not dir or dir == "" then return end

    local entries = utils.readdir(dir, "files")
    if not entries then return end

    local video_files = {}
    for _, f in ipairs(entries) do
        local ext = get_ext(f)
        if ext and VIDEO_EXTS[ext:lower()] then
            table.insert(video_files, utils.join_path(dir, f))
        end
    end
    table.sort(video_files)

    local pl = mp.get_property_native("playlist", {})
    local existing = {}
    for _, item in ipairs(pl) do
        existing[item.filename] = true
    end

    local current_idx = nil
    for i, vf in ipairs(video_files) do
        if vf == path then
            current_idx = i
            break
        end
    end
    if not current_idx then return end

    for i = current_idx + 1, #video_files do
        local next_file = video_files[i]
        if not existing[next_file] then
            mp.commandv("loadfile", next_file, "append")
            existing[next_file] = true
        end
    end
end

mp.register_event("file-loaded", autoload_videos)
