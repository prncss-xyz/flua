local M = {}

--- create an iterate whose values are the result of cb applied to original values
function M.map(cb)
  return function(gen, param, state)
    local s = state
    local function map0(k, ...)
      if k then
        s = k
        return cb(k, ...)
      end
    end

    return function()
      return map0(gen(param, s))
    end
  end
end

--- create a new iterator where values for with cb is falsy are skipped
function M.filter(cb)
  return function(gen, param, state)
    local function a(k, ...)
      if k == nil then
        return
      end
      if cb(k, ...) then
        return k, ...
      end
      return a(gen(param, k))
    end

    return function(_, k_)
      return a(gen(param, k_))
    end, nil, state
  end
end

--- prepend a 1-based index to each iterated value
function M.indexize(gen, param, state)
  local i = 0
  local function indexize(...)
    i = i + 1
    return i, ...
  end

  return M.map(indexize)(gen, param, state)
end

--- returns the last value of an iterator
function M.last()
  local l
  return function(gen, param, state)
    local v = state
    while true do
      v = gen(param, v)
      if v == nil then
        return l
      else
        l = v
      end
    end
  end
end

--- like last, but optimized for iterators of a single value
function M.last1(gen, param, state)
  local lstate
  for state_ in gen, param, state do
    lstate = state_
  end
  return lstate
end

--- apply a reducing operation to the iterator; use fold to get end results conveniently
function M.scan1(reducer, acc)
  local function scan(...)
    acc = reducer(acc, ...)
    return acc
  end

  return M.map(scan)
end

function M.fold1(reducer, acc)
  return M.compose(M.scan1(reducer, acc), M.last1)
end

function M.chain(cb)
  return M.compose(M.map(cb), M.flatten)
end

--- create an iterator consting of the succesion of two iterators
function M.concat(gen2, param2, state2)
  return function(gen1, param1, state1)
    local second
    local gen = gen1
    local param = param1
    local function a(state_, ...)
      if state_ == nil then
        if second then
          return
        end
        second = true
        gen = gen2
        param = param2
        return a(gen(param, state2))
      else
        return state_, ...
      end
    end

    return function(_, state__)
      return a(gen(param, state__))
    end,
      nil,
      state1
  end
end

local function list_concat0(t1, i, v, ...)
  if v == nil then
    return t1
  else
    t1[i] = v
    return list_concat0(t1, i + 1, ...)
  end
end

--- create an iterator whose value are the concatenation of the values of each iterator
--- iteration stops when the value of the first iterator is nil
--- only the second iterator can have multiple values
function M.zip(f2, s2, k2)
  return function(f1, s1, k1)
    return function()
      local vars1 = { f1(s1, k1) }
      k1 = vars1[1]
      if k1 == nil then
        return
      end
      local function a(k2_, ...)
        if k2_ == nil then
          return
        end
        k2 = k2_
        return unpack(list_concat0(vars1, #vars1 + 1, k2, ...))
      end

      return a(f2(s2, k2))
    end
  end
end

-- Function composition

local function pipe0(f1, f2)
  return function(...)
    return f1(f2(...))
  end
end

local function id(...)
  return ...
end

local function pipe_n(f1, f2, ...)
  if f2 then
    return pipe0(f1, pipe_n(f2, ...))
  elseif f1 then
    return f1
  else
    return id
  end
end

--- return a function which is equivalent to the composition of each argument
--- if no argument are passed, retruns the identity function
M.pipe = pipe_n

local function compose_n(f1, f2, ...)
  if f2 then
    return pipe0(compose_n(f2, ...), f1)
  elseif f1 then
    return f1
  else
    return id
  end
end

--- return a function which is equivalent to the composition of each argument starting from the last
--- if no argument are passed, retruns the identity function
M.compose = compose_n

function M.comp(...)
  local args = { ... }
  return function(...)
    return M.compose(...)(unpack(args))
  end
end

--- identity function
M.id = id

-- Extra methods

-- iterator transformation

function M.tap(cb)
  return M.map(function(...)
    cb(...)
    return ...
  end)
end

function M.each(cb)
  return pipe0(M.last(), M.tap(cb))
end

local function counter(n)
  return function()
    n = n - 1
    return n >= 0
  end
end

function M.take(cb)
  if type(cb) == 'number' then
    cb = counter(cb)
  end
  return M.map(function(...)
    if cb(...) then
      return ...
    end
  end)
end

local function replay(gen, param, state, res)
  local first = true
  return function(_, state_)
    if first then
      first = false
      return state, unpack(res)
    else
      return gen(param, state_)
    end
  end,
    nil,
    state
end

function M.drop(cb)
  if type(cb) == 'number' then
    cb = counter(cb)
  end
  return function(gen, param, state)
    local function d(state_, ...)
      if state_ == nil then
        return function() end
      end
      if cb(state_, ...) then
        return d(gen(param, state_))
      end
      return replay(gen, param, state_, { ... })
    end

    return d(gen(param, state))
  end
end

function M.head()
  return function(gen, param, state)
    return gen(param, state)
  end
end

-- iterators

--- empty iterator
function M.null()
  return function() end
end

--- returns iterator that yields argument tuple once
---@vararg any
---@return function(_: any, k: any): ...
function M.once(...)
  local args = { ... }
  return function(_, k)
    if k == nil then
      return unpack(args)
    end
  end
end

function M.range(a_, b_, c_)
  local b, e, s
  if a_ and b_ and c_ then
    b, e, s = a_, b_, c_
  elseif a_ and b_ then
    b, e, s = a_, b_, 1
  elseif a_ then
    b, e, s = 1, a_, 1
  else
    b, e, s = 1, nil, 1
  end
  return function(_, v)
    v = v + s
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
    return v
  end,
    nil,
    b - s
end

-- iterator consumption

function M.to_table(t)
  t = t or {}
  return function(gen, param, state)
    local k = state
    while true do
      local v
      k, v = gen(param, k)
      if k == nil then
        return t
      else
        t[k] = v
      end
    end
  end
end

function M.to_list(l)
  l = l or {}
  local i = #l
  return function(gen, param, state)
    local v = state
    while true do
      v = gen(param, v)
      if v == nil then
        return l
      else
        i = i + 1
        l[i] = v
      end
    end
  end
end

function M.nth(n)
  return function(gen, param, state)
    while n > 1 do
      n = n - 1
      state = gen(param, state)
      if not state then
        return
      end
    end
    return gen(param, state)
  end
end

function M.flatten(gen1, param1, state1)
  local gen2, param2, state2 = gen1(param1, state1)
  if gen2 == nil then
    return function() end
  end
  local function d(k2_, ...)
    state2 = k2_
    if state2 == nil then
      gen2, param2, state2 = gen1(param1, state1)
      if gen2 == nil then
        return
      end
      return d(gen2(param2, state2))
    else
      return state2, ...
    end
  end

  return function()
    return d(gen2(param2, state2))
  end
end

local function cmp_(a, b)
  if a < b then
    return -1
  end
  if a > b then
    return 1
  end
  return 0
end

function M.min(cmp)
  cmp = cmp or cmp_
  return M.fold1(function(acc, _, v)
    if acc == nil then
      return v
    end
    if cmp(v, acc) < 0 then
      return v
    end
    return acc
  end)
end

function M.max(cmp)
  cmp = cmp or cmp_
  return M.fold1(function(acc, _, v)
    if acc == nil then
      return v
    end
    if cmp(v, acc) > 0 then
      return v
    end
    return acc
  end)
end

function M.tbl(t, ...)
  return M.to_table()(M.comp(pairs(t))(...))
end

function M.list(t, ...)
  return M.to_table()(M.comp(ipairs(t))(...))
end

return M
