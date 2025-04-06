pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- random numbers
function rand(l, h) return rnd(abs(h - l)) + min(l, h) end
function randint(l, h) return flr(rnd(abs(h + 1 - l))) + min(l, h) end

-- text functions
function pixlen(s) return print(s, 0, 128) end

function pprint(s, x, y, c1, c2, ind, out)
 x -= ind == "r" and print(s, 0, 128) or ind == "c" and print(s, 0, 128) / 2 or 0
 if out then
  for ox = -1, 1 do
   for oy = -1, 1 do
    if (ox | oy != 0) print(s, x + ox, y + oy, c2)
   end
  end
 else
  print(s, x, y + 1, c2)
 end
 print(s, x, y, c1)
end

function debug(infos, pos, col1, col2)
 for i, info in ipairs(infos) do
  local inf = info[2]
  if type(inf) == "table" and inf.x then
   inf = inf.x .. "," .. inf.y
  end
  pprint(info[1] .. " : " .. tostr(inf), pos.x, pos.y + ((i - 1) * 7), col1 or 7, col2 or 5)
 end
end

-- 2d vector
_v2 = {}
_v2.__index = _v2
function _v2:new(x, y) return setmetatable({ x = x or 0, y = y or 0 }, self) end
function v2(x, y) return _v2:new(x, y) end
function _v2:__add(o) return _v2:new(self.x + o.x, self.y + o.y) end
function _v2:__sub(o) return _v2:new(self.x - o.x, self.y - o.y) end
function _v2:__mul(s) return _v2:new(self.x * s, self.y * s) end
function _v2:__div(s) return _v2:new(self.x / s, self.y / s) end
function _v2:__len() return sqrt(self.x ^ 2 + self.y ^ 2) end
function _v2:clone() return _v2:new(self.x, self.y) end

function _v2:norm() local m = #self return m > 0 and self / m or v2() end
function _v2:rnd() return _v2:new(1, 0):rot(rnd()) end
function _v2:rand(lx, hx, ly, hy) return _v2:new(rand(lx, hx), rand(ly, hy)) end
function _v2:randint(lx, hx, ly, hy) return _v2:new(randint(lx, hx), randint(ly, hy)) end
function _v2:floor() return _v2:new(flr(self.x), flr(self.y)) end
function _v2:sqrdist(o) return (o.x - self.x) ^ 2 + (o.y - self.y) ^ 2 end
function _v2:limit(limit) self.x, self.y = mid(-limit[1], self.x, limit[1]), mid(limit[2], self.y, limit[3]) end
function _v2:rot(a) local c, s = cos(a), sin(a) return _v2:new(self.x * c - self.y * s, self.x * s + self.y * c) end
