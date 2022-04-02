local u = require 'utils'

describe('tbl', function()
  describe('split_string', function()
    it('split string with delimiter', function() end)
    assert.are.same(
      { 'I', 'like', '', 'potatoes.' },
      u.split_string('I like  potatoes.', ' ')
    )
    assert.are.same(
      { 'I', 'like', 'potatoes.' },
      u.split_string('I  like  potatoes.', '  ')
    )
  end)
end)
