local f = require 'iterator'
describe('flua', function()
  describe('pipe', function()
    it('shoule pipe functions', function()
      local function fb(t)
        return t .. 'b'
      end
      local function fc(t)
        return t .. 'c'
      end
      local function fd(t)
        return t .. 'd'
      end
      assert.are.same('abcd', f.pipe(fd, fc, fb) 'a')
      assert.are.same('abcd', f.compose(fb, fc, fd) 'a')
      assert.are.same('abcd', f.comp 'a'(fb, fc, fd))
    end)
  end)
  describe('tabularize', function()
    it('should clone table', function()
      local a = { 'b', 'c', 'd', 'e' }
      assert.are.same(a, f.tabularize()(ipairs(a)))
      assert.are.same({}, f.tabularize()(ipairs {}))
    end)
  end)
  describe('transform', function()
    it('should map and skip', function()
      assert.are.same(
        {},
        f.comp {}(
          ipairs,
          f.transform(function(k, v)
            return k, 2 * v
          end),
          f.tabularize()
        )
      )
      assert.are.same(
        { 2, 4, 6 },
        f.comp { 1, 2, 3 }(
          ipairs,
          f.transform(function(k, v)
            return k, 2 * v
          end),
          f.tabularize()
        )
      )
      assert.are.same(
        { a = 1, c = 3 },
        f.comp { a = 1, b = 2, c = 3 }(
          pairs,
          f.transform(function(k, v)
            if k == 'b' then
              return f.skip
            end
            return k, v
          end),
          f.tabularize()
        )
      )
      assert.are.same(
        { 1 },
        f.comp { 1, 2, 3 }(
          ipairs,
          f.transform(function(k, v)
            if k == 2 then
              return
            end
            return k, v
          end),
          f.tabularize()
        )
      )
    end)
  end)
  describe('each', function()
    it('should be called on each iteration', function()
      local acc = 'a'
      local function inc(_, v)
        acc = acc .. v
      end
      f.comp { 'b', 'c', 'd', 'e' }(ipairs, f.each(inc))
      assert.are.same(acc, 'abcde')
    end)
  end)
  describe('tap', function()
    it('should be called on each iteration', function()
      local acc = 'a'
      local function inc(_, v)
        acc = acc .. v
      end
      f.comp { 'b', 'c', 'd', 'e' }(ipairs, f.tap(inc), f.last)
      assert.are.same(acc, 'abcde')
    end)
  end)
  describe('fold', function()
    it('should fold', function()
      local function sum(acc, x)
        return acc + x
      end
      assert.are.same(0, f.fold(sum, 0)(ipairs {}))
      assert.are.same(6, f.fold(sum, 0)(f.range(1, 3)))
    end)
  end)
  describe('chain', function()
    it('should chain', function()
      local t = { 1, 2, 1, 2 }
      assert.are.same(
        t,
        f.comp { 1, 2 }(
          ipairs,
          f.chain(function(_, _)
            return ipairs(t)
          end),
          f.tabularize()
        )
      )
    end)
  end)
  describe('ichain', function()
    it('should chain', function()
      assert.are.same(
        { 2, 3, 4, 5, 3, 4, 5, 6 },
        f.comp { 2, 3 }(
          ipairs,
          f.ichain(function(_, v)
            return f.range(v, v + 3)
          end),
          -- f.tap(print),
          f.tabularize()
        )
      )
    end)
  end)
  describe('iconcat', function()
    it('should concatenate iterators', function()
      assert.are.same(
        { 1, 2, 3, 4 },
        f.comp(f.range(1, 2))(f.iconcat(f.range(3, 4)), f.tabularize())
      )
    end)
  end)
  describe('zip', function()
    local function iter(_, k)
      if k < 5 then
        return k + 1
      end
    end
    it('should zip two iterators', function()
      assert.are.same(
        { 3, 4, 5 },
        f.tabularize()(f.zip(iter, nil, 2)(iter, nil, 0))
      )
    end)
  end)
  describe('range', function()
    it('should iterate the range with index', function()
      assert.are.same({ 1, 2, 3 }, f.tabularize()(f.range(1, 3)))
      assert.are.same({ 1, 3, 5 }, f.tabularize()(f.range(1, 5, 2)))
      assert.are.same({ 5, 3, 1 }, f.tabularize()(f.range(5, 1, -2)))
    end)
  end)
  describe('take_while', function()
    it('should iterate while condition is true', function()
      assert.are.same(
        { 1, 2 },
        f.comp { 1, 2, 3, 4 }(
          ipairs,
          f.take_while(function(_, v)
            return v ~= 3
          end),
          f.tabularize()
        )
      )
    end)
  end)
  describe('idrop_while', function()
    it('should skip iterating while condition is true', function()
      assert.are.same(
        { 3, 4 },
        f.comp { 1, 2, 3, 4 }(
          ipairs,
          f.idrop_while(function(_, v)
            return v ~= 3
          end),
          f.tabularize()
        )
      )
    end)
  end)
end)
