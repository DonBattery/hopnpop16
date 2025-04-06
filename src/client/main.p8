pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
_g = _ENV

_env = { __index = _ENV }

function env(obj)
  return setmetatable(obj, _env)
end

#include tools.p8

function new_terminal(text_color, bg_color, error_color)
  local t = {}
  t.history, t.buffer, t.t_col, t.bg_col, t.err_col, t.commands, t.append, t.render = {}, "", text_color or 11, bg_color or 0, error_color or 8, { cls = function(_ENV) history = {} end }, function(_ENV, str, err)
    for line in all(split(tostr(str), "\n")) do
      add(history, { s = line, c = err and err_col or t_col }, 1)
    end
  end, function(_ENV, x, y, h)
    -- while there is a character in the keyboard buffer
    while stat(30) do
      -- read the next character
      local c = stat(31)
      -- backspace
      if c == "\b" then
        buffer = sub(buffer, 1, #buffer - 1)
        -- enter
      elseif c == "\r" then
        -- prevent pico-8's pop-up window
        poke(0x5f30, 1)
        append(_ENV, buffer)
        local parts = split(buffer, " ")
        buffer = ""
        local p1 = parts[1]
        if p1 ~= "" then
          if commands[p1] then
            local res, code = commands[p1](_ENV, parts)
            if (res) append(_ENV, res, code)
          else
            append(_ENV, "unknown command: " .. p1, 1)
          end
        end
      else
        buffer = buffer .. c
      end
    end

    rectfill(x, y, 127, y + h * 6, bg_col)
    local lines = min(#history, h - 1)
    for i = lines, 1, -1 do
      print(history[i].s, x, y + (lines - i) * 6, history[i].c)
    end
    print(">" .. buffer .. "_", x, y + lines * 6, t_col)
  end

  return env(t)
end

maps = {
  [0] = {
    "1110000000000000000000",
    "1000000000001000011000",
    "1000111100001100000000",
    "1000000000011110000011",
    "1100000000111000000001",
    "1110001111110000000001",
    "1000000000000011110001",
    "1000000000000000000011",
    "1110011100000000000111",
    "1000000000003100000001",
    "1000000000031110000001",
    "1011110000311111111001",
    "1000000000000000000001",
    "1100000000000000000011",
    "2222222214000001333111",
    "2222222211111111111111"
  }
}

function build_map(map_index)
  local map_data = maps[map_index]

  local full_width, full_height = 32, 32
  local wall_tile, empty_tile = 1, 0
  local src_height, src_width = #map_data, #map_data[1]
  local start_y = full_height - src_height

  -- Clear the map first
  map(0, 0, 0, 0, 128, 64)

  -- Copy the source map into the bottom-left corner
  for y = 1, src_height do
    local row = map_data[y]
    for x = 1, #row do
      mset(x - 1, start_y + y - 1, tonum(sub(row, x, x)))
    end
  end

  -- Fill right side with walls
  for y = start_y, full_height - 1 do
    for x = src_width, full_width - 1 do
      mset(x, y, wall_tile)
    end
  end

  -- Fill cells above according to top row
  for x = 0, full_width - 1 do
    local top_tile = wall_tile
    if x < src_width and sub(map_data[1], x + 1, x + 1) == "0" then
      top_tile = empty_tile
    end
    for y = 0, start_y - 1 do
      mset(x, y, top_tile)
    end
  end
end

player_id = 0

world = {
  running = true,
  map_id = 0,
  countdown = 0,
  num_players = 0,
  players = {}
}

function decode_world()
  local base = 0x5f80 + 2
  -- gpio pin 3 onwards (offset by JS)

  -- World state byte at gpio pin 3
  local state_byte = peek(base)
  world.running = band(state_byte, 0x01) == 0
  world.map_id = band(shr(state_byte, 1), 0x0f)

  -- Countdown at gpio pin 4
  world.countdown = peek(base + 1)

  -- Local player id packed into gpio pin 5
  local packed_players_byte = peek(base + 2)
  player_id = band(shr(packed_players_byte, 4), 0x0f)

  -- Player presence bytes at gpio pins 6 and 7
  local presence_byte_1 = peek(base + 3)
  local presence_byte_2 = peek(base + 4)

  -- Parse player data starting from gpio pin 8
  world.players = {}
  local player_base = base + 5

  for i = 0, 15 do
    local is_present = false
    if i < 8 then
      is_present = band(presence_byte_1, shl(1, i)) ~= 0
    else
      is_present = band(presence_byte_2, shl(1, i - 8)) ~= 0
    end

    if is_present then
      local offset = player_base + (i * 5)
      local packed_id_col = peek(offset)
      local pid = band(shr(packed_id_col, 4), 0x0f)
      local color_id = band(packed_id_col, 0x0f)
      local score = peek(offset + 1)

      local char_byte = peek(offset + 2)
      local facing_left = band(char_byte, 0x80) ~= 0
      local char_type = band(shr(char_byte, 4), 0x07)
      local anim_phase = band(char_byte, 0x0f)

      local x = peek(offset + 3)
      local y = peek(offset + 4)

      add(
        world.players, {
          pid = pid,
          color = color_id,
          score = score,
          facing_left = facing_left,
          char_type = char_type,
          anim_phase = anim_phase,
          x = x,
          y = y
        }
      )
    end
  end
end

function _init()
  -- Set the map
  build_map(0)
end

function _update60()
  -- Send input bits
  local input_bits = 0
  if btn(0) then input_bits |= 0x01 end
  if btn(1) then input_bits |= 0x02 end
  if btn(2) then input_bits |= 0x04 end
  if btn(3) then input_bits |= 0x08 end
  if btn(4) then input_bits |= 0x10 end
  if btn(5) then input_bits |= 0x20 end
  poke(0x5f80, input_bits)

  decode_world()
end

function _draw()
  cls(0)

  local me = world.players[player_id + 1]
  if me then
    camera(mid(0, me.x - 64, 128), mid(0, me.y - 74, 128))
  end

  map()

  for i, p in pairs(world.players) do
    rectfill(p.x - 2, p.y - 2, p.x + 2, p.y + 2, p.color)
  end

  camera(0, 0)
  print("state:" .. (world.running and "run" or "highscore") .. " map:" .. world.map_id .. " id:" .. player_id, 1, 1, 7)
  print("timer:" .. world.countdown .. " players:" .. world.num_players, 1, 8, 7)
  for i, p in pairs(world.players) do
    print("p" .. i .. " id:" .. p.pid .. " sc:" .. p.score .. " x:" .. p.x .. " y:" .. p.y .. " c:" .. p.color, 1, 14 + (i - 1) * 6, 10)
  end
end

__gfx__
0000000033333333ccccccccdddddddd444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333ccccccccddddddcd000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333b3333ccccc77cddddddcd444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333ccccccccdddddddd4a9494940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333ccccccccddcddddd4a9494940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003b3333b3c77cccccddcddddd4a9494940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333ccccccccdddddddd4a9494940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333ccccccccdddddddd444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0b000b0000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0bb00b000b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0bbb0bbb0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0b000b0000bb00b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0bb00b000b000b0b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0bbb0bbb0bb000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0b000b0000bb00000b0b0bbb0bbb0bbb0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b00000b0b00b000b000b00b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0bb00b000b000b0b00000bb000b000b000b00bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b00000b0b00b000b000b0000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0bbb0bbb0bb000000b0b0bbb00b000b00bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0b000b0000bb00000b0b0bbb0bbb0bbb0b0b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b00000b0b00b000b000b00b0b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0bb00b000b000b0b00000bb000b000b000b00bbb00b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b000b000b000b0b00000b0b00b000b000b0000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bbb0bbb0bbb0bb000000b0b0bbb00b000b00bbb00b000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b00bb00bb0bbb00bb00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000b0b0b000b000b000b000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0b0b0b000b000bb00bbb0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0b0b0b000b000b00000b000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb000bb00bb00bb0bbb0bb00bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b00bb00bb0bbb00bb00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000b0b0b000b000b000b000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0b0b0b000b000bb00bbb0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0b0b0b000b000b00000b000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb000bb00bb00bb0bbb0bb00bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08880888088800880888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880088008080880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08880808080808800808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb0b0b0bb000bb00000bbb0bbb000000000bbb0bbb0000000b0000000000000000000000000000000000000000000000000000000000000000000000000000
0b000b0b0b0b0b0b00000b0b0bbb000000000b0b0b00000000b00000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0b0b0b0b0b0b00000bb00b0b00000bbb0bb00bb0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000
000b0b0b0b0b0b0b00000b0b0b0b000000000b0b0b00000000b00000000000000000000000000000000000000000000000000000000000000000000000000000
0bb000bb0bbb0bb000000b0b0b0b000000000b0b0b0000000b000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080880080808800088080808800000008800880888088808880880088000000000008808080880008800000000000000000000000000000000000000000000
08080808080808080808080808080000080008080888088808080808080800800000080008080808080800000000000000000000000000000000000000000000
08080808088008080808080808080000080008080808080808880808080800000000088808080808080800000000000000000000000000000000000000000000
08080808080808080808088808080000080008080808080808080808080800800000000808080808080800000000000000000000000000000000000000000000
00880808080808080880088808080000008808800808080808080808088800000000088000880888088000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

