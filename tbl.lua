local M = {}

--- concatenates two arrays
---@param t1 any[]
---@param t2 any[]
---@return any[]
function M.concat(t1, t2)
  local len1 = #t1
  for i = 1, #t2 do
    t1[len1 + 1] = t2[i]
  end
  return t1
end

-- TODO: merge arrays
function M.deep_merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
      M.deep_merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

function M.invert(tbl)
  local res = {}
  for key, value in pairs(tbl) do
    res[value] = key
  end
  return res
end

function M.group_by(fn, t)
  local acc = {}
  for k, v in pairs(t) do
    local key = fn(k, v)
    local l = acc[key]
    if l then
      table.insert(l, v)
    else
      acc[key] = { v }
    end
  end
  return acc
end

function M.adjust(t, k, v)
  local acc = {}
  for k1, v1 in pairs(t) do
    if k1 == k then
      acc[k1] = v
    else
      acc[k1] = v1
    end
  end
  return acc
end

local meta_table_join = {}

function meta_table_join.__index(t, k)
  k = t.t1[k]
  if k == nil then
    return
  end
  return t.t2[k]
end

function meta_table_join.__newindex(t, k, v)
  k = t.t1[k]
  if k == nil then
    return
  end
  t.t2[k] = v
end

local function join_next(t, k)
  local v
  while true do
    k, v = next(t.t1, k)
    if k == nil then
      return
    end
    local v2 = t.t2[v]
    if v ~= nil then
      return k, v2
    end
  end
end

function meta_table_join.__pairs(t)
  return join_next, t, nil
end

function M.table_join(t1, t2)
  local o = {
    t1 = t1,
    t2 = t2,
  }
  setmetatable(o, meta_table_join)
  return o
end

return M
