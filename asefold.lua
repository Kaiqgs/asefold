local _VERSION

--- _ignore_start_
local inspect = require("inspect")
local function pprint(...)
    print(inspect(...))
end
--- _ignore_end_

---@class UserCollisionGroup
---@field name string
---@field tiles table<number>
local UserCollisionGroup = {}

---@class SaveData
---@field dialog Dialog
---@field export_data table | boolean
---@field image_filepath string
---@field collision_filepath string | nil
---@field filepath string
---@field module_filename string
---@field tile_width number | nil
---@field tile_height number | nil
local SaveData = {}

---@class TilemapPathData
---@field relative_png string
---@field png string
---@field tilesource string
---@field relative_tilesource string
---@field tilemap string
local TilemapPathData = {}

--- constants
local C = {
    app_name = "asefold",
    app_group = "asefold_file_export",
    file_export_group = "file_export",
    pardir = "..",
    underscore = "_",
    temporary_export = "asefold_temporary",
    tab1 = "\t",
    tab2 = "\t\t",
    empty_space = " ",
    id_format = "%s_%s",
    tileset_filename_template = "%s_%s",
    module_filename_template = "%s_tilesource.lua",
    defold_sprite = "defold_sprite",
    extension_tilesource = "tilesource",
    extension_tilemap = "tilemap",
    filename = "%s.%s",
    extension_png = "png",
    data_filename_template = "{layer}|{frame}",
    filename_parse_separator = "|",
    layer = "layer",
    --- pattern matching
    data_filename_parse = "([%w%s_. ]*)|([%w%s_. ]+)",
    comma_separated_pattern = "([^,]+)",
    collision_group_pattern = ",*(collision_group%[(.-)%]%s-=%s-([%w%s]+)),*",
    --- export - templating
    _module_item_template = '%s%s = "%s"',
    _module_item_escape_template = '%s["%s"] = "%s"',
    _shallow_module_template = [[
-- generated @ aseprite: asefold-export
local M = {
    -- ase-animations: begin
%s,
    -- ase-animations: end
    layers = {
%s
    },
    tags = {
%s
    }
}
return M
]],
    _deep_module_template = [[
-- generated @ aseprite: asefold-export
local M = {
    animations = {
%s
    },
    layers = {
%s
    },
    tags = {
%s
    }
}
return M]],
    _tilesource_convex_hull_template = [[
convex_hulls {
  index: %d
  count: %d
  collision_group: "%s"
}]],
    _tilesource_animation_template = [[
animations {
  id: "%s"
  start_tile: %d
  end_tile: %d
  playback: %s
  fps: %d
  flip_horizontal: %d
  flip_vertical: %d
}]],
    _tilesource_template = [[
image: "%s"
tile_width: %d
tile_height: %d
tile_margin: 0
tile_spacing: 0
collision: "%s"
material_tag: "tile"
collision_groups: "default"
%s
extrude_borders: 2
inner_padding: 0
sprite_trim_mode: SPRITE_TRIM_MODE_OFF]],
    _tilemap_cell_template = [[
  cell {
    x: %d
    y: %d
    tile: %d
  }]],
    _tilemap_layer_template = [[
  id: "%s"
  z: %1.1f
  %s]],
    _tilemap_template = [[
tile_set: "%s"
layers {
    %s
}
material: "/builtins/materials/tile_map.material"]],
}
--- localization
local L = {
    mandatory_tileset = "tileset is mandatory :p",
    tilemap_data_not_found_template = 'tilemap not found for layer "%s"',
    tilesource_missing_template = 'collision "%s" -> "%s" but "%s" (layer or source) does not exist',
    inconsistent_file_count = "inconsistent file count",
    collision_tileset_exceeded = "only one collision per sprite is supported",
    dir_not_exists = "directory does not exist",
    tilemap_it = "tilemap it",
    accept_tilemap = "tilemaps?",
    accept_tilemap_message = "tilemaps export one tilesource per layer",
    format_limitations = "nor layer or tag shall contain underscores",
    cancel = "cancel",
    reset = "reset",
    title_clear_preferences = "erases it all",
    clear_preferences = "reset your preferences?",
    clear_preferences_template = "%dx sprite configurations",
    clear_preferences_path = "or edit json settings in",
    clear_preferences_path_template = '"%s"',
    suppress_info = "supress messages",
    suppress_label = "skip success dialog",
    clear = "clear",
    clear_label = "clear preferences",
    invalid_sprite = "invalid sprite",
    no_repeat_settings = "no settings to repeat",
    flatten = "flatten visible",
    title_template = "Asefold: %s",
    titles = {
        "export",
        "thanks for exporting w/ us",
        "soon w/ tilemap support",
        "Defold rocks",
        "you are appreciated",
        "export sprite stacks",
        "playback options in userdata",
        "final fps is average of duration",
        "comment what to improve",
        "localization coming next",
    },
    export_title = "Export to defold",
    repeat_title = "Repeat last",
    success = "success",
    sprite_tilesource_info = "export sprites to tilesource",
    sprite_tileset_info = "export tiles to tileset",
    path_info = "where to export",
    run_export = "export",
    import_animations = "get animations from",
    sorry = "sorry",
    not_implemented = "not implemented",
    ok = "ok",
    filepath_label = "where to export",
    output_folder_label = "output folder",
    run_label = "run export",
    sheet_type_label = "sheet type",
    generate_module = "generate lua module",
    generate_module_label = "to use w/ scripts",
    save_printout = 'saving %s at "%s"',
    pingpong_reverse_warning = {
        'There is no equivalent to "Ping-Pong Reverse" animation playback in Defold.',
        '    Using "Ping-Pong" instead.',
    },
}

local LuaModuleType = { none = "none", shallow = "shallow", deep = "deep" }
local DialogWidgets = {
    Animation = "animation",
    SpriteSheetType = "sprite_sheet_type",
    GenerateModule = "generate_module",
    OutputFolder = "output_folder",
    FlattenVisible = "flatten_visible",
    suppressInfo = "supress_info",
}
local WidgetsValueField = {
    [DialogWidgets.Animation] = "option",
    [DialogWidgets.SpriteSheetType] = "option",
    [DialogWidgets.GenerateModule] = "option",
    [DialogWidgets.OutputFolder] = "text",
    [DialogWidgets.FlattenVisible] = "selected",
    [DialogWidgets.suppressInfo] = "selected",
}
local AnimationType = {
    FromTags = "tags",
    FromLayers = "layers",
}
local UserData = {
    once = "once",
    loop = "loop",
    none = "none",
    collision = "collision",
    parameter = "",
}
local type_map = {
    ROWS = SpriteSheetType.ROWS,
    PACKED = SpriteSheetType.PACKED,
    COLUMNS = SpriteSheetType.COLUMNS,
    VERTICAL = SpriteSheetType.VERTICAL,
    HORIZONTAL = SpriteSheetType.HORIZONTAL,
}
local SpriteSheetLabels = {
    "ROWS",
    "PACKED",
    "COLUMNS",
    "VERTICAL",
    "HORIZONTAL",
}
local commands = {
    AsefoldExportDialog = "AsefoldExportDialog",
    AsefoldRepeatExport = "AsefoldRepeatExport",
}
local empty_name = "__empty__"

local PINGPONG_REVERSE = "pingpong_reverse"
local function direction_loop(anidir, loop)
    return tostring(anidir) .. ":" .. tostring(loop)
end
-- animation + loop
local MapAniDir = {
    [direction_loop(AniDir.FORWARD, true)] = "PLAYBACK_LOOP_FORWARD",
    [direction_loop(AniDir.FORWARD, false)] = "PLAYBACK_ONCE_FORWARD",
    [direction_loop(AniDir.REVERSE, true)] = "PLAYBACK_LOOP_BACKWARD",
    [direction_loop(AniDir.REVERSE, false)] = "PLAYBACK_ONCE_BACKWARD",
    [direction_loop(AniDir.PING_PONG, true)] = "PLAYBACK_LOOP_PINGPONG",
    [direction_loop(AniDir.PING_PONG, false)] = "PLAYBACK_ONCE_PINGPONG",
    [direction_loop("forward", true)] = "PLAYBACK_LOOP_FORWARD",
    [direction_loop("forward", false)] = "PLAYBACK_ONCE_FORWARD",
    [direction_loop("reverse", true)] = "PLAYBACK_LOOP_BACKWARD",
    [direction_loop("reverse", false)] = "PLAYBACK_ONCE_BACKWARD",
    [direction_loop("pingpong", true)] = "PLAYBACK_LOOP_PINGPONG",
    [direction_loop("pingpong", false)] = "PLAYBACK_ONCE_PINGPONG",
    [direction_loop(PINGPONG_REVERSE, true)] = "PLAYBACK_LOOP_PINGPONG",
    [direction_loop(PINGPONG_REVERSE, false)] = "PLAYBACK_ONCE_PINGPONG",
    none = "PLAYBACK_NONE",
}

local function round(x)
    return math.floor(x + 0.5)
end

local function random_choice(list)
    if #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    return list[index]
end

local function ternary(cond, case_true, case_false)
    if cond then
        return case_true
    end
    return case_false
end

local function get_temporary_file(filename)
    filename = filename or C.app_name
    local temp_name = app.fs.joinPath(app.fs.tempPath, filename)
    return temp_name
end

---formats
---@param layer string
---@param tag string
local function id_formatting(layer, tag)
    -- assert(not layer:find(C.underscore), loc.please_no_underscore_template:format(C.layer_underscore, ))
    local empty_tag = tag == empty_name
    local id = ternary(empty_tag, layer, C.id_format:format(layer, tag))
    local err = ternary(
        (layer:find(C.underscore) or tag:find(C.underscore)) and not empty_tag,
        L.format_limitations,
        false
    )
    return id, err
end

---@param dialog Dialog
---@return boolean
local function is_export_lua_module(dialog)
    return dialog.data[DialogWidgets.GenerateModule]
        and dialog.data[DialogWidgets.GenerateModule] ~= LuaModuleType.none
end

---@param dialog Dialog
---@return boolean
local function is_from_tags(dialog)
    return dialog.data[DialogWidgets.Animation] == AnimationType.FromTags
end

---table of strings into dialog new rows
---@param dialog Dialog
---@param messages table<string>
---@return Dialog
local function dialog_concat(dialog, messages)
    if messages and type(messages) == "string" then
        dialog = dialog:label({ text = messages }):newrow()
    elseif messages and type(messages) == "table" then
        for i, text in ipairs(messages) do
            dialog = dialog:label({ text = text })
            if i < #messages then
                dialog = dialog:newrow()
            end
        end
    end
    return dialog
end
local function get_obj_from_temp(temp_json_path)
    local temp_file = io.open(temp_json_path, "r")
    print(("Temporary JSON file written to: \"%s\""):format(temp_json_path))
    if not temp_file then
        error("temp_file not generated")
    end
    local temp_data = temp_file:read("a")
    json = json or { decode = function(...) end }
    local temp_object = json.decode(temp_data)
    temp_file:close()
    return temp_object
end

local function get_is_success_suppressed(plugin, dialog)
    plugin = plugin or {}
    plugin.preferences = plugin.preferences or {}
    local sprite = app.sprite or {}
    local setting = plugin.preferences[sprite.filename]
    return (setting and setting[DialogWidgets.suppressInfo])
        or (dialog and dialog.data[DialogWidgets.suppressInfo])
end

local function dialog_verb_cancel(data, message, verb, callback)
    local dialog = Dialog({ title = data.title, parent = data.parent })
    dialog = dialog_concat(dialog, message)
    dialog = dialog:button({
        text = verb,
        onclick = function()
            if callback then
                callback()
            end
            dialog:close()
        end,
    })
    dialog = dialog:button({
        text = L.cancel,
        onclick = function()
            dialog:close()
        end,
    })
    return dialog
end

local function format_animation(
    id,
    start_tile,
    end_tile,
    playback,
    fps,
    flip_horizontal,
    flip_vertical
)
    return C._tilesource_animation_template:format(
        id,
        start_tile,
        end_tile,
        playback,
        fps,
        flip_horizontal,
        flip_vertical
    )
end

local function success_dialog(parent, messages)
    local _inner = Dialog({ title = L.success, parent = parent })
    _inner = dialog_concat(_inner, messages)
    _inner:button({
        text = L.ok,
        onclick = function()
            _inner:close()
        end,
    })
    _inner:show()
end
local function error_dialog(parent, reason)
    local _inner = Dialog({ title = L.sorry, parent = parent })
    _inner = dialog_concat(_inner, reason)
    _inner = _inner:button({
        text = L.ok,
        onclick = function()
            _inner:close()
        end,
    })
    _inner:show()
end
local function not_implemented_dialog(parent)
    local _inner = Dialog({ title = L.sorry, parent = parent }):label({
        text = L.not_implemented,
    })
    _inner:button({
        text = L.ok,
        onclick = function()
            _inner:close()
        end,
    })
    _inner:show()
end
local function get_minmax(list, selector)
    selector = selector or function(self)
        return self
    end
    local _max = -math.huge
    local _min = math.huge
    for _, v in ipairs(list) do
        local value = selector(v)
        if value > _max then
            _max = value
        end
        if value < _min then
            _min = value
        end
    end

    return {
        max = _max,
        min = _min,
    }
end
local function average(list, selector)
    selector = selector or function(self)
        return self
    end
    local sum = 0
    for _, v in ipairs(list) do
        local value = selector(v)
        sum = sum + value
    end
    return sum / #list
end
local function get_animations_from_tags(export_data)
    local animations = {}
    local err = false
    -- TODO: get from input
    local animation_ids = {}
    -- print(inspect(export_data))

    local sheet_width = export_data.meta.size.w
    local sheet_height = export_data.meta.size.h

    local tile_size
    local sheet_size
    if #export_data.meta.frameTags == 0 then
        export_data.meta.frameTags = {
            {
                name = empty_name,
                from = 0,
                to = #app.sprite.frames,
                direction = "forward",
                color = "#000000ff",
            },
        }
    end
    --TODO: check exported type
    -- if _temporary_type == SpriteSheetDataFormat.JSON_HASH then
    -- end
    local frame_tags = export_data.meta.frameTags
    local frame_data = {}
    for frame_name, frame in pairs(export_data.frames) do
        local layer, frame_number =
            string.match(frame_name, C.data_filename_parse)
        frame_number = tonumber(frame_number)
        for _, tag_data in ipairs(export_data.meta.frameTags) do
            local tag = tag_data.name
            local start_frame = tag_data.from
            local end_frame = tag_data.to
            if frame_number >= start_frame and frame_number <= end_frame then
                layer = layer
                    or string.sub(
                        frame_name,
                        1,
                        string.find(frame_name, C.filename_parse_separator) - 1
                    )
                tile_size = tile_size or frame.sourceSize
                sheet_size = sheet_size
                    or {
                        w = round(sheet_width / tile_size.w),
                        h = round(sheet_height / tile_size.h),
                    }
                local tilex =
                    round(frame.frame.x / sheet_width * sheet_size.w)
                local tiley =
                    round(frame.frame.y / sheet_height * sheet_size.h)
                local tile_index = tilex + tiley * sheet_size.w
                local id, format_err = id_formatting(layer, tag)
                if format_err then
                    return {}, {}, format_err
                end

                if layer then
                    frame_data[id] = frame_data[id]
                        or {
                            layer = layer,
                            tag = tag,
                            frame_number = frame_number,
                            durations = {},
                            tiles = {},
                        }
                    table.insert(
                        frame_data[id].tiles,
                        { tile_index, tilex, tiley }
                    )
                    table.insert(frame_data[id].durations, frame.duration)
                end
            end
        end
    end

    for data_id, frame in pairs(frame_data) do
        local minmax = get_minmax(frame.tiles, function(table)
            return table[1]
        end)
        local avg_duration_ms = average(frame.durations)
        local avg_fps = 1000 / avg_duration_ms
        frame_data[data_id].fps = avg_fps
        frame_data[data_id].from = minmax.min
        frame_data[data_id].to = minmax.max
    end

    -- TODO: for some reason we're getting double ids...
    -- this is best workaround
    local consumed_ids = {}
    local pingpong_reverse_warning = true

    for _, layer in ipairs(export_data.meta.layers) do
        for _, tag in ipairs(frame_tags) do
            tag = tag or { name = empty_name }
            assert(layer.name)
            local id, format_err = id_formatting(layer.name, tag.name)
            if format_err then
                return {}, {}, format_err
            end
            local data = frame_data[id]
            local tag_data = tag.data or UserData.loop
            if data and not consumed_ids[id] then
                --- _ignore_start_
                print(
                    ("Layer '%s', tag '%s', tag_direction '%s' and data '%s'"):format(
                        layer.name,
                        tag.name,
                        tag.direction,
                        tag_data
                    )
                )
                --- _ignore_end_
                local playback_match = {
                    [UserData.once] = MapAniDir[direction_loop(
                        tag.direction or AniDir.FORWARD,
                        false
                    )],
                    [UserData.none] = MapAniDir.none,
                    [UserData.loop] = MapAniDir[direction_loop(
                        tag.direction or AniDir.FORWARD,
                        true
                    )],
                }
                local resulting_match = playback_match.loop
                for key, v in pairs(playback_match) do
                    if tag_data:find(key) then
                        resulting_match = v
                        break
                    end
                end

                if
                    tag.direction == PINGPONG_REVERSE
                    and pingpong_reverse_warning
                then
                    error_dialog(nil, L.pingpong_reverse_warning)
                    pingpong_reverse_warning = false
                end

                local animation = format_animation(
                    id,
                    data.from + 1,
                    data.to + 1,
                    resulting_match,
                    data.fps,
                    0,
                    0
                )
                table.insert(animations, animation)
                table.insert(animation_ids, id)
                consumed_ids[id] = true
            end
        end
    end

    return animations, animation_ids, err
end

---@param name string
local function format_module_line(name, tab)
    tab = tab or C.tab2
    local need_escape = name:find(C.empty_space)
    if need_escape == nil then
        return C._module_item_template:format(tab, name, name)
    end
    return C._module_item_escape_template:format(tab, name, name)
end
local function save_module(dialog, filepath, animation_ids, export_data)
    if not is_export_lua_module(dialog) then
        return
    end

    local is_shallow = dialog.data[DialogWidgets.GenerateModule]
        == LuaModuleType.shallow

    --- get animations
    local animations = {}
    for _, id in ipairs(animation_ids) do
        local line
        if is_shallow then
            line = table.insert(animations, format_module_line(id, C.tab1))
        else
            line = table.insert(animations, format_module_line(id))
        end
        table.insert(animations, line)
    end

    local layers = {}
    for _, layer in ipairs(export_data.meta.layers) do
        table.insert(layers, format_module_line(layer.name))
    end

    local tags = {}
    for _, tag in ipairs(export_data.meta.frameTags) do
        table.insert(tags, format_module_line(tag.name))
    end

    local animations_string = table.concat(animations, ",\n")
    local layers_string = table.concat(layers, ",\n")
    local tags_string = table.concat(tags, ",\n")

    -- _tilesource_template
    local module_file = io.open(filepath, "w+")
    if not module_file then
        error("not able to save module")
    end
    local template =
        ternary(is_shallow, C._shallow_module_template, C._deep_module_template)
    module_file:write(
        template:format(animations_string, layers_string, tags_string)
    )
    module_file:close()
end

---@param savedata SaveData
local function save_tilesource(savedata)
    local file
    ---@type boolean | string | nil
    local err
    file, err = io.open(savedata.filepath, "w+")
    if err or not file then
        return { tostring(err) }, true
    end
    local animations, animation_ids = {}, {}
    err = false
    if is_from_tags(savedata.dialog) and savedata.export_data then
        animations, animation_ids, err =
            get_animations_from_tags(savedata.export_data)
    end
    local out_data = C._tilesource_template:format(
        savedata.image_filepath,
        savedata.tile_width or app.sprite.width,
        savedata.tile_height or app.sprite.height,
        --- TODO: add option to enable/disable collision default
        savedata.collision_filepath
        or savedata.image_filepath
        or "",
        table.concat(animations, "\n") or ""
    )
    file:write(out_data)
    file:close()
    if savedata.export_data then
        save_module(
            savedata.dialog,
            savedata.module_filename,
            animation_ids,
            savedata.export_data
        )
    end
    return false
end
local function get_paths(dialog, names)
    names = names or {}
    local paths = {}
    local sprite_name = app.fs.fileTitle(app.sprite.filename) or C.defold_sprite
    local sprite_filename = C.filename:format(sprite_name, C.extension_png)
    local curr_folder = app.fs.filePath(app.sprite.filename) or "/"
    ---@type string
    local reference_folder = dialog.data[DialogWidgets.OutputFolder]
    reference_folder = reference_folder:sub(1, 1) == app.fs.pathSeparator
        and reference_folder:sub(2)
        or reference_folder
    local relative_folder = app.fs.joinPath(
        curr_folder,
        app.fs.joinPath(C.pardir, reference_folder)
    )
    relative_folder = app.fs.normalizePath(relative_folder)

    if not app.fs.isDirectory(relative_folder) then
        error_dialog(
            ternary(dialog.data._is_synthetic, nil, dialog),
            L.dir_not_exists
        )
        return false
    end

    --- TODO: try and follow same naming convention
    paths.temporary_export_path = get_temporary_file(C.temporary_export)
    paths.export_texture_path =
        app.fs.joinPath(relative_folder, sprite_filename)
    local _sprite_png = C.filename:format(sprite_name, C.extension_png)
    paths.internal_image_filename = app.fs.pathSeparator
        .. app.fs.joinPath(reference_folder, _sprite_png)
    local _tilesource_p = C.filename:format(sprite_name, C.extension_tilesource)
    paths.tilesource_filename = app.fs.joinPath(relative_folder, _tilesource_p)
    paths.module_filepath = app.fs.joinPath(
        relative_folder,
        C.module_filename_template:format(sprite_name)
    )

    if not names.tileset then
        return paths
    end

    ---@type table<TilemapPathData>
    paths.tilesets = {}
    for _, tilename in ipairs(names.tileset) do
        local joint_name =
            C.tileset_filename_template:format(sprite_name, tilename)
        local joint_png = C.filename:format(joint_name, C.extension_png)
        local joint_tilesource =
            C.filename:format(joint_name, C.extension_tilesource)
        local joint_tilemap = C.filename:format(joint_name, C.extension_tilemap)
        local png_filepath = app.fs.joinPath(relative_folder, joint_png)
        local tilesource_filepath =
            app.fs.joinPath(relative_folder, joint_tilesource)
        local relative_png_filepath = app.fs.pathSeparator
            .. app.fs.joinPath(reference_folder, joint_png)
        local relative_tilesource_filepath = app.fs.pathSeparator
            .. app.fs.joinPath(reference_folder, joint_tilesource)
        local tilemap_filepath = app.fs.joinPath(relative_folder, joint_tilemap)
        -- paths.tileset[tilename] = tile_filepath
        -- table.insert(paths.tileset, png_filepath)
        -- table.insert(paths.tileset_tilesources, tilesource_filepath)
        -- table.insert(paths.tileset_internal_png, relative_png_filepath)
        -- table.insert(paths.tileset_internal_tilesources, relative_tilesource_filepath)
        -- table.insert(paths.tileset_tilemap, tilemap_filepath)
        ---@type TilemapPathData
        local tileset_data = {
            tilemap = tilemap_filepath,
            png = png_filepath,
            tilesource = tilesource_filepath,
            relative_png = relative_png_filepath,
            relative_tilesource = relative_tilesource_filepath,
        }
        table.insert(paths.tilesets, tileset_data)
    end
    return paths
end

---@param layer Layer
local function iterate_grid(canvas_width, canvas_height, layer, tile_size)
    -- app.usetool({
    --
    -- })
    local tile_cells = {}
    local iterations = 0
    local tilemap_data
    for _, cel in ipairs(layer.cels) do
        if cel.image.colorMode == ColorMode.TILEMAP then
            local tilemap = cel.image
            tilemap_data = {}
            for it in tilemap:pixels() do
                table.insert(tilemap_data, app.pixelColor.tileI(it()))
            end
            -- pprint({ tiles = tilemap_data, iterations = iterations })
        end
    end
    if not tilemap_data then
        return {}, L.tilemap_data_not_found_template:format(layer.name)
    end

    local tile_count_x_axis = math.floor(canvas_width / tile_size.width)
    local tile_count_y_axis = math.floor(canvas_height / tile_size.height)
    --- _ignore_start_
    -- pprint({
    --     tilemap_width = tile_size.width,
    --     tilemap_height = tile_size.height,
    --     tiles_per_row = tile_count_x_axis,
    --     tiles_per_column = tile_count_y_axis,
    --     canvas_width = canvas_width,
    --     canvas_height = canvas_height,
    -- })
    --- _ignore_end_
    -- local half_tile_width = tile_size.width / 2
    -- local half_tile_height = tile_size.height / 2
    local x = 0
    local y = tile_count_y_axis - 1
    local rowcount = 0
    for _, tile in ipairs(tilemap_data) do
        rowcount = rowcount + 1
        local tile_cell = C._tilemap_cell_template:format(x, y, tile)
        table.insert(tile_cells, tile_cell)
        x = x + 1
        if rowcount >= tile_count_x_axis then
            x = 0
            y = y - 1
            rowcount = 0
        end
    end
    local tile_cells_stream = table.concat(tile_cells, "\n")
    return tile_cells_stream, false
end

---@param _ Dialog
---@param tilemap_layer Layer
---@param tilemap_filepath any
---@param internal_tilesource_filepath any
---@return table
---@return string | nil
local function save_tilemap(
    _,
    tilemap_layer,
    tile_size,
    tilemap_filepath,
    internal_tilesource_filepath
)
    local file, err = io.open(tilemap_filepath, "w+")
    if not file or err then
        return {}, tostring(err)
    end
    local canvas_width = app.sprite.width
    local canvas_height = app.sprite.height
    local tile_cells, tile_err =
        iterate_grid(canvas_width, canvas_height, tilemap_layer, tile_size)
    if tile_err then
        return {}, tile_err
    end
    -- local basic_cell = C._tilemap_cell_template:format(0, 0, 2)
    local basic_layer =
        C._tilemap_layer_template:format(C.layer, 0.0, tile_cells)
    ---@type string
    local tilemap_data =
        C._tilemap_template:format(internal_tilesource_filepath, basic_layer)
    file:write(tilemap_data)
    file:close()
    return {}, nil
end

local function _export_tileset(dialog, tile_layers, tile_names)
    local paths = get_paths(dialog, { tileset = tile_names })
    if not paths then
        return {}, true
    end
    -- print(inspect(tile_names))
    -- print(inspect(paths.tileset))
    local tilesources = {}
    for i, tile_layer in ipairs(tile_layers) do
        ---@cast tile_layer Layer
        local tileset = tile_layer.tileset
        ---@type TilemapPathData
        local tilepath = paths.tilesets[i]
        if not tileset then
            return {}, L.mandatory_tileset
        end
        print("layer:")
        print(("    name: %s"):format(tile_layer.name))
        print(("    data: %s"):format(tile_layer.data))
        print("tileset:")
        print(("    name: %s"):format(tileset.name))
        print(("    grid: %s"):format(tileset.grid))
        print(("    grid.tileSize: %s"):format(tileset.grid.tileSize))
        print(("    grid.origin: %s"):format(tileset.grid.origin))
        print(("    base index: %s"):format(tileset.baseIndex))
        print(("    color: %s"):format(tileset.color))
        print(("    data: %s"):format(tileset.data))
        print(("    properties: %s"):format(tileset.properties.width))
        print(("    paths: %s"):format(inspect(tilepath)))

        local layer_data = tostring(tile_layer.data or "")
        local tileset_data = tostring(tileset.data or "")
        local is_collision = layer_data:find(UserData.collision)
            or tileset_data:find(UserData.collision)
        local target
        if is_collision then
            local collision_target = tileset.name
            target = collision_target
            tilesources[target] = tilesources[target] or {}
            tilesources[target].collision_filepath = tilepath.relative_png
            tilesources[target].collider_name = tile_layer.name
        else
            target = tile_layer.name or tileset.name
            tilesources[target] = tilesources[target] or {}
            tilesources[target].image_filepath = tilepath.relative_png
            tilesources[target].filepath = tilepath.tilesource
            tilesources[target].tilemap_filepath = tilepath.tilemap
            tilesources[target].internal_tilesource_filepath =
                tilepath.relative_tilesource
            tilesources[target].layer = tile_layer
        end
        tilesources[target].tile_width = tileset.grid.tileSize.width
        tilesources[target].tile_height = tileset.grid.tileSize.height

        app.command.ExportSpriteSheet({
            ignoreEmpty = false,
            mergeDuplicates = false,
            fromTilesets = true,
            ui = false,
            layer = tile_layer.name,
            textureFilename = tilepath.png,
            dataFilename = nil,
            askOverwrite = false,
        })
    end
    for name, tilesource in pairs(tilesources) do
        print("Tilesource:")
        print(inspect(tilesource))
        if
            tilesource.image_filepath
            and tilesource.image_filepath ~= ""
            and tilesource.filepath
            and tilesource.filepath ~= ""
        then
            save_tilesource({
                module_filename = paths.module_filepath,
                dialog = dialog,
                collision_filepath = tilesource.collision_filepath,
                image_filepath = tilesource.image_filepath,
                filepath = tilesource.filepath,
                tile_width = tilesource.tile_width,
                tile_height = tilesource.tile_height,
                --- TODO: keep in mind that we might be able to export animations too...
                export_data = false,
            })

            local tilemap_filepath = tilesource.tilemap_filepath
            local internal_tilesource_filepath =
                tilesource.internal_tilesource_filepath
            save_tilemap(
                dialog,
                tilesource.layer,
                Size(tilesource.tile_width, tilesource.tile_height),
                tilemap_filepath,
                internal_tilesource_filepath
            )
        elseif tilesource.collision_filepath then
            error_dialog(
                dialog,
                L.tilesource_missing_template:format(
                    tilesource.collider_name,
                    name,
                    name
                )
            )
        end
    end
    -- save_tilemap(dialog, )
end
---@diagnostic disable undefined-field
local function check_tilemap_layers(dialog)
    local tile_layers = {}
    local tileset_names = {}
    for _, layer in ipairs(app.sprite.layers) do
        local tileset = layer.tileset
        if layer.isTilemap and tileset ~= nil and layer.isVisible then
            table.insert(tile_layers, layer)
            table.insert(tileset_names, layer.name)
        end
    end
    print(("I have: layers:%d names:%d"):format(#tile_layers, #tileset_names))
    if #tile_layers == 0 or #tileset_names == 0 then
        return false
    end

    if #tile_layers ~= #tileset_names then
        error_dialog(dialog, L.inconsistent_file_count)
        return false
    end

    local tilemap_dialog
    tilemap_dialog = dialog_verb_cancel(
        { title = L.accept_tilemap, parent = dialog },
        L.accept_tilemap_message,
        L.tilemap_it,
        function()
            tilemap_dialog:close()
            _export_tileset(dialog, tile_layers, tileset_names)
        end
    )
    tilemap_dialog:show()
    return true
end
---@diagnostic enable undefined-field

local function _export_tilesource(dialog)
    if check_tilemap_layers(dialog) then
        return {}
    end
    local ran_transaction = false
    if dialog.data[DialogWidgets.FlattenVisible] then
        app.transaction(function()
            local layer_name = app.layer.name
            for _, layer in ipairs(app.sprite.layers) do
                if not layer.isVisible then
                    app.sprite:deleteLayer(layer)
                    ran_transaction = true
                end
            end
            app.sprite:flatten()
            ran_transaction = true
            app.layer.name = layer_name
            ran_transaction = true
        end)
    end

    local paths = get_paths(dialog)
    if not paths then
        return {}
    end

    app.command.ExportSpriteSheet({
        ui = false,
        dataFilename = paths.temporary_export_path,
        askOverwrite = false,
        splitLayers = true,
        -- dataFormat = SpriteSheetDataFormat.JSON_ARRAY

        type = type_map[dialog.data[DialogWidgets.SpriteSheetType]],
        textureFilename = paths.export_texture_path,
        filenameFormat = C.data_filename_template,
    })

    if ran_transaction then
        app.undo()
    end

    local export_data = get_obj_from_temp(paths.temporary_export_path)
    ---@cast export_data table
    local err = save_tilesource({
        dialog = dialog,
        export_data = export_data,
        image_filepath = paths.internal_image_filename,
        filepath = paths.tilesource_filename,
        module_filename = paths.module_filepath,
    })
    if err then
        error_dialog(dialog, { err })
        return {}
    end

    local success_information = {}
    table.insert(
        success_information,
        L.save_printout:format("Temporary JSON", paths.temporary_export_path)
    )
    table.insert(
        success_information,
        L.save_printout:format("Texture", paths.export_texture_path)
    )
    table.insert(
        success_information,
        L.save_printout:format("Tile Source", paths.tilesource_filename)
    )
    if is_export_lua_module(dialog) then
        table.insert(
            success_information,
            L.save_printout:format("Lua module", paths.module_filepath)
        )
    end
    (dialog or { close = function(...) end }):close()
    return success_information
end

---@param dialog Dialog
local function dialog_export_tilesource(dialog)
    -- sheet_type_label = "sheet type",
    return dialog
        :check({ text = L.flatten, id = DialogWidgets.FlattenVisible })
        :combobox({
            options = {
                SpriteSheetLabels[1],
                SpriteSheetLabels[4],
                SpriteSheetLabels[5],
            },
            id = DialogWidgets.SpriteSheetType,
            label = L.sheet_type_label,
            onchange = function()
                if
                    dialog.data[DialogWidgets.SpriteSheetType]
                    ~= SpriteSheetLabels[3]
                    and dialog.data[DialogWidgets.SpriteSheetType]
                    ~= SpriteSheetLabels[2]
                then
                    return
                end
                not_implemented_dialog(dialog)
                dialog:modify({
                    id = DialogWidgets.SpriteSheetType,
                    option = SpriteSheetLabels[1],
                })
            end,
        })
        :combobox({
            id = DialogWidgets.Animation,
            option = AnimationType.FromTags,
            options = { AnimationType.FromTags, AnimationType.FromLayers },
            label = L.import_animations,
            onchange = function()
                if
                    dialog.data[DialogWidgets.Animation]
                    ~= AnimationType.FromLayers
                then
                    return
                end
                not_implemented_dialog(dialog)
                dialog:modify({
                    id = DialogWidgets.Animation,
                    option = AnimationType.FromTags,
                })
            end,
        })
        :combobox({
            options = {
                LuaModuleType.none,
                LuaModuleType.shallow,
                LuaModuleType.deep,
            },
            selected = LuaModuleType.none,
            label = L.generate_module_label,
            id = DialogWidgets.GenerateModule,
            text = L.generate_module,
        })
        :check({
            id = DialogWidgets.suppressInfo,
            text = L.suppress_info,
            label = L.suppress_label,
        })
end

---@param dialog Dialog
local function basic_dialog(dialog, overrides)
    return dialog
        :button({
            text = L.run_export,
            label = L.run_label,
            onclick = overrides.run_export or function(...) end,
        })
        :entry({
            text = "/assets",
            save = true,
            label = L.output_folder_label,
            id = DialogWidgets.OutputFolder,
        })
end

---persistesting
---@param plugin any
---@param dialog Dialog
local function dialog_persistence(plugin, dialog)
    dialog:button({
        text = L.clear,
        label = L.clear_label,
        onclick = function()
            local counter = 0
            for _, _ in pairs(plugin.preferences or {}) do
                counter = counter + 1
            end
            dialog_verb_cancel(
                { title = L.title_clear_preferences, parent = dialog },
                {
                    L.clear_preferences_template:format(counter),
                    L.clear_preferences_path,
                    L.clear_preferences_path_template:format(
                        get_temporary_file(C.temporary_export)
                    ),
                    L.clear_preferences,
                },
                L.reset,
                function()
                    plugin.preferences = {}
                end
            ):show()
        end,
    })
    local data = plugin.preferences[app.sprite.filename]
    if data then
        for _, key in pairs(DialogWidgets) do
            local update = {
                id = key,
            }
            pcall(function()
                update[WidgetsValueField[key]] = data[key]
                -- print(inspect(update))
                -- print(key)
                dialog:modify(update)
            end)
        end
    end
    -- print(app.sprite.filename, inspect.inspect(plugin.preferences))
    return dialog
end

local function repeat_export(plugin)
    if not app.sprite then
        error_dialog(nil, L.invalid_sprite)
        return
    end
    if
        not plugin.preferences
        or (plugin.preferences and not plugin.preferences[app.sprite.filename])
    then
        error_dialog(nil, L.no_repeat_settings)
        return
    end
    -- print(inspect.inspect(plugin.preferences))
    -- print(inspect.inspect(plugin.preferences[app.sprite.filename]))

    local data = plugin.preferences[app.sprite.filename]
    data._is_synthetic = true
    local success_information = _export_tilesource({
        data = data,
        close = function(...) end,
    })
    if not get_is_success_suppressed(plugin) and #success_information ~= 0 then
        success_dialog(nil, success_information)
    end
end

local function _read_plugin_preferences()
    if not app.fs.isFile(get_temporary_file()) then
        print("warn: no file")
        return {}
    end

    local file, err = io.open(get_temporary_file(), "r")
    if err or not file then
        return {}
    end
    local data = file:read()
    file:close()
    return json.decode(data)
end
local function _write_plugin_preferences(plugin_preferences)
    local file, err = io.open(get_temporary_file(), "w+")
    if err or not file then
        return
    end
    -- print("written")
    -- print(inspect(plugin_preferences))
    file:write(json.encode(plugin_preferences))
    file:close()
end
---@param plugin any
---@param dialog Dialog
local function _export_persistence(plugin, dialog)
    local data = dialog.data
    local new_data = {}
    for _, key in pairs(DialogWidgets) do
        new_data[key] = data[key]
    end
    plugin.preferences[app.sprite.filename] = new_data
    _write_plugin_preferences(plugin.preferences)
end

local function show_dialog(plugin)
    plugin = plugin or {}
    if not app.sprite then
        error_dialog(nil, L.invalid_sprite)
        return
    end
    local dialog = Dialog({
        title = L.title_template:format(random_choice(L.titles) or C.app_name),
        hexpand = true,
        vexpand = true,
    })

    dialog = basic_dialog(dialog, {
        run_export = function()
            local success_information = _export_tilesource(dialog)
            if #success_information ~= 0 then
                _export_persistence(plugin, dialog)
            end
            if not get_is_success_suppressed(plugin, dialog) and #success_information ~= 0 then
                success_dialog(dialog, success_information)
            end
        end,
    })
    dialog = dialog_export_tilesource(dialog)
    dialog = dialog_persistence(plugin, dialog)
    dialog:show()
end

function init(plugin)
    local group = C.app_group
    plugin:newMenuGroup({
        id = group,
        title = L.export_title,
        group = C.file_export_group,
    })
    plugin:newCommand({
        id = commands.AsefoldExportDialog,
        title = L.export_title,
        group = group,
        onclick = function()
            show_dialog(plugin)
        end,
    })
    plugin:newCommand({
        id = commands.AsefoldRepeatExport,
        title = L.repeat_title,
        group = group,
        onclick = function()
            repeat_export(plugin)
        end,
    })
    plugin = plugin or {}
    plugin.preferences = _read_plugin_preferences()
end

function exit(_)
    -- no use
end
