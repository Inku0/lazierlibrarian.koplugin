local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local FrameContainer = require("ui/widget/container/framecontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local Geom = require("ui/geometry")
local ButtonTable = require("ui/widget/buttontable")
local ScrollHtmlWidget = require("ui/widget/scrollhtmlwidget")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local http = require("socket/http")
local logger = require("logger")
local _ = require("gettext")
local T = require("ffi/util").template
local base64 = require("base64")

require("llapi")

function LLBrowser:tapBook(bookid, bookdata)
    local frame_bordersize = Size.border.window
    local book_dialog
    local add_button_text = _("Add")
    local add_button_func = self.addAndSearchBook

    local button_table = ButtonTable:new {
        width = self.width,
        buttons = {
            {
                {
                    text = add_button_text,
                    callback = function()
                        add_button_func(self, bookid)
                        UIManager:close(book_dialog)
                    end
                }
            },
            {
                {
                    text = _("Close"),
                    callback = function()
                        UIManager:close(book_dialog)
                        self.last_action = self.previous_action
                        self:updateItems(1, true)
                    end
                }
            }
        },
        zero_sep = true,
        show_parent = self,
    }

    -- Show loading message
    local message = InfoMessage:new {
        text = "Loading cover art..."
    }

    UIManager:show(message)

    -- Download cover image
    local cover = ""
    if bookdata.bookimg and bookdata.bookimg:match("^https?://") then
        local cover_tbl = {}
        local ret, status = http.request {
            url = bookdata.bookimg,
            method = "GET",
            sink = ltn12.sink.table(cover_tbl)
        }

        if status == 200 then
            local cover_data = base64.encode(table.concat(cover_tbl))
            cover = '<div class="cover"><img src="data:image/jpeg;base64,' ..
                cover_data .. '" style="width: 300px"/></div><br/>'
        else
            logger.warn("Failed to load cover:", status)
            cover = _("Failed to load cover<br/>")
        end
    else
        cover = _("No cover available<br/>")
    end

    UIManager:close(message)

    -- Build book info HTML
    local book_info = T(
        _("<b>%1</b><br/>by %2<br/><br/>" ..
            "Pages: %3<br/>" ..
            "Rating: %4 (%5 votes)<br/>" ..
            "Published: %6<br/>" ..
            "Publisher: %7<br/>" ..
            "ISBN: %8<br/>" ..
            "Language: %9<br/><br/>" ..
            "%10"),
        bookdata.bookname or "Unknown",
        bookdata.authorname or "Unknown",
        bookdata.bookpages or "Unknown",
        bookdata.bookrate or 0,
        bookdata.bookrate_count or 0,
        bookdata.bookdate or "Unknown",
        bookdata.bookpub or "Unknown",
        bookdata.bookisbn or "Unknown",
        bookdata.booklang or "Unknown",
        bookdata.bookdesc or ""
    )

    local textview = ScrollHtmlWidget:new {
        html_body = cover .. book_info,
        css = "img {text-align: center} .cover { text-align: center }",
        width = self.width,
        height = self.height - button_table:getSize().h,
        dialog = self
    }

    book_dialog = FrameContainer:new {
        radius = Size.radius.window,
        bordersize = frame_bordersize,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOR_WHITE,
        VerticalGroup:new {
            align = "left",
            CenterContainer:new {
                dimen = Geom:new {
                    w = self.width,
                    h = textview:getSize().h,
                },
                textview,
            },
            CenterContainer:new {
                dimen = Geom:new {
                    w = self.width,
                    h = button_table:getSize().h,
                },
                button_table,
            }
        }
    }

    UIManager:nextTick(function() UIManager:show(book_dialog) end)
end
