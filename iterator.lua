local M = {}
local tbl = require 'tbl'

local unpack = table.unpack or unpack

-- Core functions

M.skip = {}

function M.transform(cb)
  return function(f, s, var)
    local k = var
    return function()
      while true do
        local vars = { f(s, k) }
        -- local vars = pack(f(s, k))
        k = vars[1]
        if k == nil then
          return
        end
        local res = { cb(unpack(vars)) }
        -- local res = pack(cb(unpack(vars)))
        local k2 = res[1]
        if k2 == nil then
          return
        end
        if k2 ~= M.skip then
          return unpack(res)
        end
      end
    end
  end
end

function M.last(f, s, var)
  local lvars
  while true do
    local vars = { f(s, var) }
    var = vars[1]
    if var == nil then
      if lvars == nil then
        return
      end
      return unpack(lvars)
    end
    lvars = vars
  end
end

function M.fold(reducer, init, default)
  if init == nil then
    init = function(...)
      local args = { ... }
      return args[#args]
    end
  end
  if type(init) ~= 'function' then
    default = default or init
    local acc0 = init
    init = function(...)
      return reducer(acc0, ...)
    end
  end
  local acc
  return function(f, s, var)
    M.last(M.transform(function(...)
      local vars = { ... }
      if acc == nil then
        acc = init(unpack(vars))
      else
        acc = reducer(acc, unpack(vars))
      end
      return acc
    end)(f, s, var))
    if acc == nil then
      acc = default
    end
    return acc
  end
end

function M.id(...)
  return ...
end

function M.chain(cb, isArray)
  return function(f, s, k)
    local args, args2
    local f2, s2, k2
    local lk = 0
    local d
    return function()
      while true do
        if k2 == nil then
          d = lk
          args = { f(s, k) }
          k = args[1]
          if k == nil then
            return
          end
          f2, s2, k2 = cb(unpack(args))
          if not f2 then
            return
          end
        end
        args2 = { f2(s2, k2) }
        k2 = args2[1]
        if k2 ~= nil then
          if isArray then
            lk = k2
            args2[1] = k2 + d
          end
          return unpack(args2)
        end
      end
    end
  end
end

function M.ichain(cb)
  return M.chain(cb, true)
end

--- concatenate two iterator
---@param _f2 function
---@param _s2 any
---@param _var2 any
---@return function(_f1: function, _s1: any, _var1: any): function(): ...
function M.concat(_f2, _s2, _var2)
  return function(_f1, _s1, _var1)
    local function shifter(i)
      if i == 1 then
        return _f1, _s1, _var1
      else
        return _f2, _s2, _var2
      end
    end
    return M.chain(shifter)(M.range(1, 2))
  end
end

function M.iconcat(_f2, _s2, _var2)
  return function(_f1, _s1, _var1)
    local function shifter(i)
      if i == 1 then
        return _f1, _s1, _var1
      else
        return _f2, _s2, _var2
      end
    end
    return M.ichain(shifter)(M.range(1, 2))
  end
end

local function array_concat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

function M.zip(f2, s2, var2)
  return function(f1, s1, var1)
    local k1 = var1
    local k2 = var2
    return function()
      local vars1 = { f1(s1, k1) }
      local vars2 = { f2(s2, k2) }
      k1 = vars1[1]
      k2 = vars2[1]
      if k1 == nil then
        return
      end
      if k2 == nil then
        return
      end
      array_concat(vars1, vars2)
      return unpack(vars1)
    end
  end
end

-- Function composition

local function pipe0(f1, f2)
  return function(...)
    return f1(f2(...))
  end
end

function M.pipe(f1, f2, f3, ...)
  if not f2 then
    return f1
  end
  if not f3 then
    return pipe0(f1, f2)
  end
  return pipe0(f1, M.pipe(f2, f3, ...))
end

function M.compose(f1, f2, f3, ...)
  if not f2 then
    return f1
  end
  if not f3 then
    return pipe0(f2, f1)
  end
  return pipe0(M.compose(f2, f3, ...), f1)
end

function M.comp(...)
  arg = { ... }
  return function(...)
    return M.compose(...)(unpack(arg))
  end
end

-- Extra methods

-- iterator transformation

function M.tap(cb)
  return M.transform(function(...)
    cb(...)
    return ...
  end)
end

function M.each(cb)
  return pipe0(M.last, M.tap(cb))
end

function M.take_while(cb)
  return M.transform(function(...)
    if cb(...) then
      return ...
    end
  end)
end

function M.drop_while(cb, isArray)
  local passing
  local d = 0
  return M.transform(function(...)
    passing = passing or not cb(...)
    if passing then
      if isArray then
        local args = { ... }
        args[1] = args[1] - d
        return unpack(args)
      end
      return ...
    else
      d = ...
      return M.skip
    end
  end)
end

function M.idrop_while(cb)
  return M.drop_while(cb, true)
end

-- iterators

--- empty iterator
function M.zero() end

--- returns iterator that yields argument tuple once
---@vararg any
---@return function(_: any, k: any): ...
function M.unit(...)
  local args = { ... }
  return function(_, k)
    if k == nil then
      return unpack(args)
    end
  end
end

function M.range(b, e, s)
  s = s or 1
  b = b or 1
  b = b - s
  return function(_, i)
    i = i + 1
    local v = b + i * s
    if e then
      if s > 0 then
        if v > e then
          return
        end
      else
        if v < e then
          return
        end
      end
    end
    return i, v
  end,
    _,
    0
end

-- iterator consumption

function M.tabularize(t)
  t = t or {}
  return M.fold(function(acc, k, v)
    acc[k] = v
    return acc
  end, t)
end

function M.first(_f, _s, _var)
  return _f and _f(_s, _var)
end

return M
