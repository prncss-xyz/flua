local t = require 'tbl'

describe('tbl', function()
  describe('concat', function()
    it('sould concatenate two arrays', function()
      assert.are.same({}, t.concat({}, {}))
      assert.are.same({ 1 }, t.concat({ 1 }, {}))
      assert.are.same({ 1 }, t.concat({}, { 1 }))
      assert.are.same({ 1, 2 }, t.concat({ 1 }, { 2 }))
    end)
  end)
  describe('deep_merge', function()
    it('should deep merge onto first table', function()
      assert.are.same(
        { a = { 1, 2 }, b = 3 },
        t.deep_merge({ a = { 4, 2 } }, { a = { 1 }, b = 3 })
      )
    end)
  end)
  describe('invert', function()
    it('should invert a table', function()
      assert.are.same({ 'a', 'b', 'c' }, t.invert { a = 1, b = 2, c = 3 })
    end)
  end)
  describe('group_by', function()
    it('should regroup entries by key', function()
      assert.are.same(
        { even = { 2, 4 }, odd = { 1, 3, 5 } },
        t.group_by(function(_, v)
          if v % 2 == 0 then
            return 'even'
          end
          return 'odd'
        end, { 1, 2, 3, 4, 5 })
      )
    end)
  end)
  describe('adjust', function()
    it('should return a modified copy', function()
      local o = { 1, 2, 3 }
      local m = t.adjust(o, 2, 4)
      assert.are.same({ 1, 4, 3 }, m)
      assert.are.same({ 1, 2, 3 }, o)
      assert.is_not(o, m) -- redundant
    end)
  end)
  describe('join', function()
    it('should read index properly', function()
      local t1 = { 'a', 'b', 'c' }
      local t2 = { a = 4, b = 5, c = 6 }
      local j = t.table_join(t1, t2)
      assert.are.same(j[2], 5)
    end)
    it('should write index properly', function()
      local t1 = { 'a', 'b', 'c' }
      local t2 = { a = 4, b = 5, c = 6 }
      local j = t.table_join(t1, t2)
      j[2] = 7
      assert.are.same(7, j[2])
      assert.are.same(7, t2.b)
    end)
    -- this just works, with lua built in iterator, and __index, no __ipairs involved
    it('iterate arrays properly', function()
      local t1 = { 'a', 'b', 'c' }
      local t2 = { a = 4, c = 6 }
      local j = t.table_join(t1, t2)
      local s = {}
      for i, v in ipairs(j) do
        s[i] = v
      end
      assert.are.same({ 4 }, s)
    end)
    it('iterate tables properly', function()
      local t1 = { 'a', 'b', 'c' }
      local t2 = { a = 4, c = 6 }
      local j = t.table_join(t1, t2)
      local s = {}
      for i, v in pairs(j) do
        s[i] = v
      end
      assert.are.same({ 4, [3] = 6 }, s)
    end)
  end)
end)
