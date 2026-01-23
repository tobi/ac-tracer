-- lib/init.lua - Re-export commonly used modules
return {
    state = require('lib.core.state'),
    settings = require('lib.core.settings'),
    lap = require('lib.lap'),
    theme = require('lib.ui.theme'),
    ui_utils = require('lib.ui.utils'),
}
