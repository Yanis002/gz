function usage()
  io.stderr:write("usage: make-iso [<gzinject-arg>...] [--skip-movie-files]"
                  .. " [-m <input-rom>] [--mq-rom <input-rom>] [-o <output-iso>] <input-iso>\n")
  os.exit(1)
end

-- parse arguments
local arg = {...}
local opt_id
local opt_title
local opt_directory = "isoextract"
local opt_raphnet
local opt_disable_controller_remappings
local opt_keep_movies
local opt_rom
local opt_mq_rom
local opt_out
local opt_iso
while arg[1] do
  if arg[1] == "-i" or arg[1] == "--gameid" then
    opt_id = arg[2]
    if opt_id == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "-t" or arg[1] == "--gamename" then
    opt_title = arg[2]
    if opt_title == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "-d" or arg[1] == "--directory" then
    opt_directory = arg[2]
    if opt_directory == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "--raphnet" then
    opt_raphnet = true
    table.remove(arg, 1)
  elseif arg[1] == "--disable-controller-remappings" then
    opt_disable_controller_remappings = true
    table.remove(arg, 1)
  elseif arg[1] == "--keep-movies" then
    opt_keep_movies = true
    table.remove(arg, 1)
  elseif arg[1] == "-m" then
    opt_rom = arg[2]
    if opt_rom == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "--mq-rom" then
    opt_mq_rom = arg[2]
    if opt_mq_rom == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "-o" then
    opt_out = arg[2]
    if opt_out == nil then usage() end
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif opt_iso ~= nil then usage()
  else
    opt_iso = arg[1]
    table.remove(arg, 1)
  end
end
if opt_iso == nil then usage() end

local gzinject = os.getenv("GZINJECT")
if gzinject == nil or gzinject == "" then gzinject = "gzinject" end

wiivc = true
require("lua/rom_table")
local make = loadfile("lua/make.lua")

-- extract iso
gru.os_rm(opt_directory)
local gzinject_cmd = gzinject ..
                     " -a extract" ..
                     " -d \"" .. opt_directory .. "\"" ..
                     " --verbose" ..
                     " -s \"" .. opt_iso .. "\""
local _,_,gzinject_result = os.execute(gzinject_cmd)
if gzinject_result ~= 0 then return gzinject_result end

-- check gc version
local gc_header = gru.blob_load(opt_directory .. "/header.bin")
local gc_version = gc_table[gc_header:crc32()]
if gc_version == nil then error("unrecognized gc version") end

-- make rom
if opt_rom == nil then opt_rom = opt_directory .. "/" .. gc_version.rom_path end
local rom_info, rom, patched_rom = make(opt_rom)
if rom_info == nil then
  io.stderr:write("make-iso: unrecognized rom: " .. opt_rom .. "\n")
  return 2
end
patched_rom:save_file(opt_directory .. "/" .. gc_version.rom_path)

-- make MQ rom (if available)
if gc_version.mq_rom_path ~= nil then
  if opt_mq_rom == nil then
    opt_mq_rom = opt_directory .. "/" .. gc_version.mq_rom_path
  end
  local mq_rom_info, mq_rom, patched_mq_rom = make(opt_mq_rom)
  if mq_rom_info == nil then
    io.stderr:write("make-iso: unrecognized rom: " .. opt_mq_rom .. "\n")
    return 2
  end
  patched_mq_rom:save_file(opt_directory .. "/" .. gc_version.mq_rom_path)
end

-- make homeboy
print("building homeboy")
local make = os.getenv("MAKE")
if make == nil or make == "" then make = "make" end
local _,_,make_result = os.execute("(cd homeboy && " .. make ..
                                   " hb-" .. gc_version.game_id .. " GAME=OOT)")
if make_result ~= 0 then error("failed to build homeboy", 0) end

-- remove movie files
if not opt_keep_movies then
  for _, movie_path in ipairs(gc_version.movie_paths) do
    print("removing " .. movie_path)
    gru.os_rm(opt_directory .. "/" .. movie_path)
  end
end

-- build gzinject pack command string
local gzinject_cmd = gzinject ..
                     " -a pack" ..
                     " -d \"" .. opt_directory .. "\"" ..
                     " --verbose"
if opt_id ~= nil then
  gzinject_cmd = gzinject_cmd .. " -i \"" .. opt_id .. "\""
else
  gzinject_cmd = gzinject_cmd .. " -i " .. rom_info.gc_game_id
end
if opt_title ~= nil then
  gzinject_cmd = gzinject_cmd .. " -t \"" .. opt_title .. "\""
else
  gzinject_cmd = gzinject_cmd .. " -t " .. rom_info.gz_name
end
gzinject_cmd = gzinject_cmd ..
               " -p \"gzi/homeboy/hb_" .. gc_version.game_id .. ".gzi\"" ..
               " --dol-iso-path \"" .. gc_version.dol_path .. "\"" ..
               " --dol-inject \"homeboy/bin/hb-" .. gc_version.game_id .. "/homeboy.bin\"" ..
               " --dol-loading 80300000"
if not opt_disable_controller_remappings then
  if opt_raphnet then
    gzinject_cmd = gzinject_cmd .. " -p \"gzi/controller/gz_remap_raphnet_" .. gc_version.game_id .. ".gzi\""
  else
    gzinject_cmd = gzinject_cmd .. " -p \"gzi/controller/gz_remap_default_" .. gc_version.game_id .. ".gzi\""
  end
end
gzinject_cmd = gzinject_cmd .. " -p \"gzi/memcard/gz_memcard_" .. gc_version.game_id .. ".gzi\""
if opt_out ~= nil then
  gzinject_cmd = gzinject_cmd .. " -s \"" .. opt_out .. "\""
elseif opt_title ~= nil then
  gzinject_cmd = gzinject_cmd .. " -s \"" .. opt_title .. ".iso\""
else
  gzinject_cmd = gzinject_cmd .. " -s \"" .. rom_info.gz_name .. ".iso\""
end
-- execute
print(gzinject_cmd)
local _,_,gzinject_result = os.execute(gzinject_cmd)
if gzinject_result ~= 0 then return gzinject_result end

return 0
