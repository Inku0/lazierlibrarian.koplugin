local _ = require("gettext")
local Menu = require("ui/widget/menu")
local Device = require("device")
local UIManager = require("ui/uimanager")
local ds = require("datastorage")
local logger = require("logger")
local misc = require("misc")

local Screen = Device.screen
LLBrowser = Menu:extend{
}

require("index")
require("searchDialog")
require("findBook")
require("llbook")

function LLBrowser:init()
    self.catalog_title = "LazyLibrarian"
    self.headers = {
        ["Content-Type"] = "text/html;charset=utf-8",
        ["User-Agent"] = "koreader.lazierlibrarian.koplugin/1.0"
    }
    self.conf_path = ds:getDataDir() .. "/ll.conf"
    --logger.info("Conf path is", self.conf_path)
    self:loadConf()
    self.last_action = ""
    self.width = Screen:getWidth()
    self.height = Screen:getHeight()
    Menu.init(self)
    self:indexPage()
end

function LLBrowser:loadConf()
    local file = io.open(self.conf_path, 'r')
    local data = file:read("*a")

    local apikey
    local apiurl

    for key, value in string.gmatch(data, "(%w+)=([^\r\n]+)") do
        if key == "URL" then
            apiurl = value
        elseif key == "KEY" then
            apikey = value
        else
            logger.err(string.format("Invalid config entry %1!", key))
        end
    end

    self.apiurl = apiurl .. "/api?apikey=" .. apikey

    file:close()
end

function LLBrowser:onMenuSelect(item)
    if item.action == nil then
        logger.err("Invalid menu item! Returning to start")
        self:init()
        return
    end

    local args = misc.split(item.action, "_")[2]
    self.previous_action = self.last_action
    self.last_action = item.action

    --logger.info("onMenuSelect - action:", item.action, "args:", args)

    if item.action == "search" then
        self:searchDialog()

    elseif misc.startswith(item.action, "search_") then
        self:findBook(args)

    elseif misc.startswith(item.action, "book_") then
        local bookdata = self.book_data_cache[args]
        self:tapBook(args, bookdata)

    else
        UIManager:show(InfoMessage:new{
            text = _("Not implemented")
        })

    end
end

function LLBrowser:onReturn()
    table.remove(self.paths)
    local path = self.paths[#self.paths]
    if path then
        -- return to last path
        self.catalog_title = path.title
        self:onMenuSelect({
            action = path.action
        })
    else
        self:indexPage()
    end
    return true
end

return LLBrowser
