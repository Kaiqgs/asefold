--- _ignore_start_
local inspect = require("inspect")
--- _ignore_end_
local pardir = ".."
local _module_animation_line = '\t\t%s = "%s"'
local _module_shallow_animation_line = '\t%s = "%s"'
local _module_item_line = '\t\t["%s"] = "%s"'
local _shallow_module_template = [[
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
]]
local _deep_module_template = [[
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
return M
]]
local _tilesource_animation_template = [[
animations {
  id: "%s"
  start_tile: %d
  end_tile: %d
  playback: %s
  fps: %d
  flip_horizontal: %d
  flip_vertical: %d
}]]
local _tilesource_template = [[
image: "%s"
tile_width: %d
tile_height: %d
tile_margin: 0
tile_spacing: 0
collision: ""
material_tag: "tile"
collision_groups: "default"
%s
extrude_borders: 2
inner_padding: 0
sprite_trim_mode: SPRITE_TRIM_MODE_OFF]]

---@type Dialog
local _main_dialog_

local LuaModuleType = { none = "none", shallow = "shallow", deep = "deep" }
local DialogWidgets = {
    Animation = "animation",
    SpriteSheetType = "sprite_sheet_type",
    GenerateModule = "generate_module",
    OutputFolder = "output_folder",
    FlattenVisible = "flatten_visible",
}
local AnimationType = {
    FromTags = "tags",
    FromLayers = "layers",
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
local function ani_defold(ani, loop)
    return tostring(ani) .. ":" .. tostring(loop)
end
-- animation + loop
local MapAniDir = {
    [ani_defold(AniDir.FORWARD, true)] = "PLAYBACK_LOOP_FORWARD",
    [ani_defold(AniDir.FORWARD, false)] = "PLAYBACK_ONCE_FORWARD",
    [ani_defold(AniDir.REVERSE, true)] = "PLAYBACK_LOOP_BACKWARD",
    [ani_defold(AniDir.REVERSE, false)] = "PLAYBACK_ONCE_BACKWARD",
    [ani_defold(AniDir.PING_PONG, true)] = "PLAYBACK_LOOP_PINGPONG",
    [ani_defold(AniDir.PING_PONG, false)] = "PLAYBACK_ONCE_PINGPONG",
    [ani_defold("forward", true)] = "PLAYBACK_LOOP_FORWARD",
    [ani_defold("forward", false)] = "PLAYBACK_ONCE_FORWARD",
    [ani_defold("reverse", true)] = "PLAYBACK_LOOP_BACKWARD",
    [ani_defold("reverse", false)] = "PLAYBACK_ONCE_BACKWARD",
    [ani_defold("pingpong", true)] = "PLAYBACK_LOOP_PINGPONG",
    [ani_defold("pingpong", false)] = "PLAYBACK_ONCE_PINGPONG",
    [ani_defold(PINGPONG_REVERSE, true)] = "PLAYBACK_LOOP_PINGPONG",
    [ani_defold(PINGPONG_REVERSE, false)] = "PLAYBACK_ONCE_PINGPONG",
    none = "PLAYBACK_NONE",
}

local loc = {
    flatten = "flatten visible",
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
    run_export = "send",
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
    -- static, nonchanging
    id_format = "%s_%s",
    module_filename_form = "%s_tilesource.lua",
    defold_sprite = "defold_sprite",
    extension_tilesource = "tilesource",
    filename = "%s.%s",
    extension_png = "png",
    data_filename_form = "{layer}|{frame}",
    data_filename_parse = "([%w%s_. ]*)|([%w%s_. ]+)",
    filename_parse_separator = "|",
}
function math.round(x)
    return math.floor(x + 0.5)
end

function math.choice(list)
    if #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    return list[index]
end

function table.values(self)
    local list = {}
    for _, v in ipairs(self) do
        table.insert(list, v)
    end
    return list
end

local function ternary(cond, a, b)
    if cond then
        return a
    end
    return b
end
local function is_export_lua_module()
    return _main_dialog_.data[DialogWidgets.GenerateModule]
        and _main_dialog_.data[DialogWidgets.GenerateModule] ~= LuaModuleType.none
end
local function is_from_tags()
    return _main_dialog_.data[DialogWidgets.Animation] == AnimationType.FromTags
end
local function get_obj_from_temp(temp_json_path)
    local temp_file = io.open(temp_json_path, "r")
    if not temp_file then
        error("temp_file not generated")
    end
    local temp_data = temp_file:read("a")
    print(temp_data)
    local temp_object = json.decode(temp_data)
    temp_file:close()
    return temp_object
end

local function format_animation(id, start_tile, end_tile, playback, fps, flip_horizontal, flip_vertical)
    return _tilesource_animation_template:format(
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
    local _inner = Dialog({ title = loc.success, parent = parent })
    for _, msg in ipairs(messages) do
        _inner = _inner:label({ text = msg }):newrow()
    end
    _inner:button({
        text = loc.ok,
        onclick = function()
            _inner:close()
        end,
    })
    _inner:show()
end
local function error_dialog(parent, reason)
    local _inner = Dialog({ title = loc.sorry, parent = parent })

    if reason and type(reason) == "string" then
        _inner = _inner:label({ text = reason })
    elseif reason and type(reason) == "table" then
        for _, text in ipairs(reason) do
            _inner = _inner:label({ text = text }):newrow()
        end
    end
    _inner = _inner:button({
        text = loc.ok,
        onclick = function()
            _inner:close()
        end,
    })
    _inner:show()
end
local function not_implemented_dialog(parent)
    local _inner = Dialog({ title = loc.sorry, parent = parent }):label({ text = loc.not_implemented })
    _inner:button({
        text = loc.ok,
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
                to = #app.activeSprite.frames,
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
        print("frame_name") --, frame_name)
        print(frame_name)
        print(frame)
        print(loc.data_filename_parse)
        local layer, frame_number = string.match(frame_name, loc.data_filename_parse)
        print(frame_number, layer)
        frame_number = tonumber(frame_number)
        for _, tag_data in ipairs(export_data.meta.frameTags) do
            local tag = tag_data.name
            local start_frame = tag_data.from
            local end_frame = tag_data.to

            -- print(inspect(tag_data))
            -- print("frame frame_number", frame_number, start_frame, end_frame)
            if frame_number >= start_frame and frame_number <= end_frame then
                -- print(layer, tag, frame_number, "~~~~~~~~~~~~~~~~~", frame_name)
                layer = layer or string.sub(frame_name, 1, string.find(frame_name, loc.filename_parse_separator) - 1)
                tile_size = tile_size or frame.sourceSize
                sheet_size = sheet_size
                    or {
                        w = math.round(sheet_width / tile_size.w),
                        h = math.round(sheet_height / tile_size.h),
                    }
                -- + .5 for rounding
                local tilex = math.round(frame.frame.x / sheet_width * sheet_size.w)
                local tiley = math.round(frame.frame.y / sheet_height * sheet_size.h)
                local tile_index = tilex + tiley * sheet_size.w
                local id = tag == empty_name and layer or loc.id_format:format(layer, tag)
                if layer then
                    frame_data[id] = frame_data[id]
                        or {
                            layer = layer,
                            tag = tag,
                            frame_number = frame_number,
                            durations = {},
                            tiles = {},
                        }
                    table.insert(frame_data[id].tiles, { tile_index, tilex, tiley })
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

    -- TODO: for some reason we're getteing double ids...
    -- this is best workaround
    local consumed_ids = {}
    print("frame data")
    print(inspect(frame_data))

    for _, layer in ipairs(export_data.meta.layers) do
        for _, tag in ipairs(frame_tags) do
            tag = tag or { name = empty_name }
            assert(layer.name)
            local id = tag.name == empty_name and layer.name or loc.id_format:format(layer.name, tag.name)
            local data = frame_data[id]
            local tag_data = tag.data or "loop"
            -- print("here I am", id)
            -- print(inspect(data))
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
                    once = MapAniDir[ani_defold(tag.direction or AniDir.FORWARD, false)],
                    none = MapAniDir.none,
                    loop = MapAniDir[ani_defold(tag.direction or AniDir.FORWARD, true)],
                }

                if tag.direction == PINGPONG_REVERSE then
                    error_dialog(nil, loc.pingpong_reverse_warning)
                end

                local animation =
                    format_animation(id, data.from + 1, data.to + 1, playback_match[tag_data], data.fps, 0, 0)
                table.insert(animations, animation)
                table.insert(animation_ids, id)
                consumed_ids[id] = true
            end
        end
    end

    return animations, animation_ids
end
local function save_module(filepath, animation_ids, export_data)
    if not is_export_lua_module() then
        return
    end

    local is_shallow = _main_dialog_.data[DialogWidgets.GenerateModule] == LuaModuleType.shallow

    --- get animations
    local animations = {}
    for _, id in ipairs(animation_ids) do
        local line
        if is_shallow then
            line = table.insert(animations, _module_shallow_animation_line:format(id, id))
        else
            line = table.insert(animations, _module_animation_line:format(id, id))
        end
        table.insert(animations, line)
    end

    local layers = {}
    for _, layer in ipairs(export_data.meta.layers) do
        table.insert(layers, _module_item_line:format(layer.name, layer.name))
    end

    local tags = {}
    for _, tag in ipairs(export_data.meta.frameTags) do
        table.insert(tags, _module_item_line:format(tag.name, tag.name))
    end

    local animations_string = table.concat(animations, ",\n")
    local layers_string = table.concat(layers, ",\n")
    local tags_string = table.concat(tags, ",\n")

    -- _tilesource_template
    local module_file = io.open(filepath, "w+")
    if not module_file then
        error("not able to save module")
    end
    local template = ternary(is_shallow, _shallow_module_template, _deep_module_template)
    module_file:write(template:format(animations_string, layers_string, tags_string))
    module_file:close()
end
local function save_tilesource(export_data, image_filepath, filepath, module_filename)
    local file = io.open(filepath, "w+")
    print(filepath)
    if not file then
        error("not able to save tilesource")
    end

    local animations, animation_ids = {}, {}

    if is_from_tags() then
        animations, animation_ids = get_animations_from_tags(export_data)
    end
    local out_data = _tilesource_template:format(
        image_filepath,
        app.activeSprite.width,
        app.activeSprite.height,
        table.concat(animations, "\n")
    )

    file:write(out_data)
    file:close()
    -- print("wrote")
    -- print(image_filepath)
    -- print(filepath)

    save_module(module_filename, animation_ids, export_data)
end
-- local function export_tileset() end
local function _export_tilesource()
    local ran_transaction = false
    if _main_dialog_.data[DialogWidgets.FlattenVisible] then
        app.transaction(function()
            local layer_name = app.activeLayer.name
            for _,layer in ipairs(app.activeSprite.layers) do
                if not layer.isVisible then
                    app.activeSprite:deleteLayer(layer)
                    ran_transaction = true
                end
            end
            app.activeSprite:flatten()
            ran_transaction = true
            app.activeLayer.name = layer_name
            ran_transaction = true
        end)
    end

    local sprite_name = app.fs.fileTitle(app.activeSprite.filename) or loc.defold_sprite
    local sprite_filename = loc.filename:format(sprite_name, loc.extension_png)
    local curr_folder = app.fs.filePath(app.activeSprite.filename) or "/"
    local reference_folder = _main_dialog_.data[DialogWidgets.OutputFolder]
    ---@cast reference_folder string
    reference_folder = reference_folder:sub(1, 1) == app.fs.pathSeparator and reference_folder:sub(2)
        or reference_folder
    local relative_folder = app.fs.joinPath(curr_folder, app.fs.joinPath(pardir, reference_folder))
    relative_folder = app.fs.normalizePath(relative_folder)

    if not app.fs.isDirectory(relative_folder) then
        error_dialog(_main_dialog_, "directory does not exist")
        return
    end

    -- print("current folder", curr_folder)
    local temp_json_path = app.fs.joinPath(curr_folder, "temp_export_defold")
    local export_texture_path = app.fs.joinPath(relative_folder, sprite_filename)
    local internal_image_filename = app.fs.pathSeparator
        .. app.fs.joinPath(reference_folder, loc.filename:format(sprite_name, loc.extension_png))
    local tilesource_filename =
        app.fs.joinPath(relative_folder, loc.filename:format(sprite_name, loc.extension_tilesource))
    local module_filepath = app.fs.joinPath(relative_folder, loc.module_filename_form:format(sprite_name))

    app.command.ExportSpriteSheet({
        ui = false,
        dataFilename = temp_json_path,
        askOverwrite = false,
        splitLayers = true,
        -- dataFormat = SpriteSheetDataFormat.JSON_ARRAY

        type = type_map[_main_dialog_.data[DialogWidgets.SpriteSheetType]],
        textureFilename = export_texture_path,
        filenameFormat = loc.data_filename_form,
    })

    if ran_transaction then
        app.undo()
    end

    local export_data = get_obj_from_temp(temp_json_path)
    save_tilesource(export_data, internal_image_filename, tilesource_filename, module_filepath)
    local success_information = {}
    table.insert(success_information, loc.save_printout:format("Temporary JSON", temp_json_path))
    table.insert(success_information, loc.save_printout:format("Texture", export_texture_path))
    table.insert(success_information, loc.save_printout:format("Tile Source", tilesource_filename))
    if is_export_lua_module() then
        table.insert(success_information, loc.save_printout:format("Lua module", module_filepath))
    end
    success_dialog(_main_dialog_, success_information);
    (_main_dialog_ or { close = function(...) end }):close()
end

---@param dialog Dialog
local function dialog_export_tilesource(dialog)
    -- sheet_type_label = "sheet type",
    return dialog
        :check({ text = loc.flatten, id = DialogWidgets.FlattenVisible })
        :combobox({
            options = { SpriteSheetLabels[1], SpriteSheetLabels[4], SpriteSheetLabels[5] },
            id = DialogWidgets.SpriteSheetType,
            label = loc.sheet_type_label,
            onchange = function()
                if
                    dialog.data[DialogWidgets.SpriteSheetType] ~= SpriteSheetLabels[3]
                    and dialog.data[DialogWidgets.SpriteSheetType] ~= SpriteSheetLabels[2]
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
            label = loc.import_animations,
            onchange = function()
                if dialog.data[DialogWidgets.Animation] ~= AnimationType.FromLayers then
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
            options = { LuaModuleType.none, LuaModuleType.shallow, LuaModuleType.deep },
            selected = LuaModuleType.none,
            label = loc.generate_module_label,
            id = DialogWidgets.GenerateModule,
            text = loc.generate_module,
        })
end

---@param dialog Dialog
local function basic_dialog(dialog, overrides)
    return dialog
        :button({
            text = loc.run_export,
            label = loc.run_label,
            onclick = overrides.run_export or function(...) end,
        })
        :entry({
            text = "/assets",
            save = true,
            label = loc.output_folder_label,
            id = DialogWidgets.OutputFolder,
        })
end

local function show_dialog()
    local dlg = Dialog({
        title = ("Asefold: %s"):format(math.choice(loc.titles) or "asefold"),
        hexpand = true,
        vexpand = true,
    })

    dlg = basic_dialog(dlg, {
        run_export = _export_tilesource,
    })
    dlg = dialog_export_tilesource(dlg)
    _main_dialog_ = dlg
    dlg:show()
end

function init(plugin)
    local group = "asefold_file_export"
    plugin:newMenuGroup({
        id = group,
        title = loc.export_title,
        group = "file_export",
    })

    plugin:newCommand({
        id = commands.AsefoldExportDialog,
        title = loc.export_title,
        group = group,
        onclick = show_dialog,
    })
    plugin:newCommand({
        id = commands.AsefoldRepeatExport,
        title = loc.repeat_title,
        group = group,
        onclick = function()
            not_implemented_dialog()
        end,
    })
end

--- _ignore_start_
show_dialog()
--- _ignore_end_
