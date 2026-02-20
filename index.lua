local _ = require("gettext")
local T = require("ffi/util").template
function LLBrowser:indexPage()
    local item_table = {
        {
            text = "\u{f002} " .. _("Search"),
            action = "search"
        },
    }
    self.page_count = 1
    self:switchItemTable("LazyLibrarian", item_table)
    return item_table
end
