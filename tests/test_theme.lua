-- test_theme.lua - Tests for theme.lua module

suite("theme")

test("theme exposes expected sections and helpers", function()
    local originalTheme = package.loaded['lib.ui.theme']
    package.loaded['lib.ui.theme'] = nil
    local theme = require('lib.ui.theme')

    assert_not_nil(theme.bg)
    assert_not_nil(theme.text)
    assert_not_nil(theme.trace)
    assert_not_nil(theme.delta)
    assert_not_nil(theme.corner)
    assert_not_nil(theme.style)

    local c = rgbm(1, 0, 0, 1)
    local withAlpha = theme.withAlpha(c, 0.5)
    assert_equal(withAlpha.r, 1)
    assert_equal(withAlpha.g, 0)
    assert_equal(withAlpha.b, 0)
    assert_equal(withAlpha.mult, 0.5)

    package.loaded['lib.ui.theme'] = originalTheme
end)
