local _ = require("gettext")
local logger = require("logger")
local json = require("json")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")

require("httprequest")

function LLBrowser:convertToItemTable(books)
    local book_tbl = {}
    for k, v in ipairs(books) do
        local text = string.format("%s by %s (%d ratings)",
            v.bookname or "Unknown",
            v.authorname or "Unknown",
            v.bookrate_count or 0
        )

        local item = {
            text = text,
            action = "book_" .. v.bookid,
        }

        --logger.info("Created item with bookid:", v.bookid, "bookdata present:", v ~= nil)
        table.insert(book_tbl, item)
    end

    return book_tbl
end

function LLBrowser:findBook(query)
    local encoded_query = query:gsub("%s", "+")
    local res = self:request(self.apiurl .. "&cmd=findBook&name=" .. encoded_query, "GET")
    if (not res) then return end

    local results = json.decode(res)

    if #results == 0 then
        UIManager:show(InfoMessage:new{
            text = _("Nothing found!")
        })
        return
    end

    -- Sort by bookrate_count (descending order)
    table.sort(results, function(a, b)
        return (a.bookrate_count or 0) > (b.bookrate_count or 0)
    end)

    -- Store book data in a lookup table
    self.book_data_cache = {}
    for _, book in ipairs(results) do
        self.book_data_cache[book.bookid] = book
    end

    -- Convert to item table and display
    self.book_tbl = self:convertToItemTable(results)
    self.catalog_title = "Search: " .. query
    self:switchItemTable(self.catalog_title, self.book_tbl)

    return results
end
