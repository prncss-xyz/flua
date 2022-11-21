local M = {}

function M.cmp_(a, b)
  if a < b then
    return -1
  end
  if a > b then
    return 1
  end
  return 0
end

--- lexicographical sorting for tuples
function M.cmp(t1, t2)
  local i = 1
  while true do
    local v1, v2 = t1[i], t2[i]
    if v1 == nil and v2 == nil then
      return 0
    end
    if v1 == nil then
      return -1
    end
    if v2 == nil then
      return 1
    end
    if v1 < v2 then
      return -1
    end
    if v2 > v1 then
      return 1
    end
    i = i + 1
  end
end

function M.gen_cmp(cmps)
  return function(t1, t2)
    local i = 1
    while true do
      local v1, v2 = t1[i], t2[i]
      if v1 == nil and v2 == nil then
        return 0
      end
      if v1 == nil then
        return -1
      end
      if v2 == nil then
        return 1
      end
      local c = cmps[i](t1, t2)
      if c ~= 0 then
        return c
      end
      i = i + 1
    end
  end
end

function M.is_in_range(cmp, s, e, x)
  if cmp(x, s) < 0 then
    return false
  end
  if cmp(e, x) > 0 then
    return false
  end
  return true
end

return M
