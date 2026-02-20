local BD = require("ui/bidi")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local LuaSettings = require("luasettings")
local LLBrowser = require("llbrowser")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local util = require("util")
local _ = require("gettext")
local T = require("ffi/util").template
local NetworkMgr = require("ui/network/manager")

local LL = WidgetContainer:new{
    name = "ll",
    --ll_settings_file = DataStorage:getSettingsDir() .. "/ll.lua",
    --settings = nil,
    --servers = nil,
    --downloads = nil,
}

function LL:init()
    --self.ll_settings = LuaSettings:open(self.ll_settings_file)
    --self.downloads = self.ll_settings:readSetting("downloads", {})
    --self.settings = self.ll_settings:readSetting("settings", {})
    --self.pending_syncs = self.ll_settings:readSetting("pending_syncs", {})
    self.ui.menu:registerToMainMenu(self)
end

function LL:addToMainMenu(menu_items)
    if not self.ui.document then -- FileManager menu only
        menu_items.ll = {
            text = _("LazyLibrarian"),
            sorting_hint = "search",
            callback = function()
                self:onShowLLCatalog()
            end,
        }
    end
end

function LL:showFileDownloadedDialog(file)
    self.last_downloaded_file = file
    local confirm_box = ConfirmBox:new{
        text = T(_("File saved to:\n%1\nWould you like to read the downloaded book now?"), BD.filepath(file)),
        ok_text = _("Read now"),
        ok_callback = function()
            self.last_downloaded_file = nil
            self.ll_browser.close_callback()
            if self.ui.document then
                self.ui:switchDocument(file)
            else
                self.ui:openFile(file)
            end
        end,
    }
    -- As the InfoMessage "Downloading" is getting closed, show this ConfirmBox on the next UI tick to avoid e-Ink rendering congestion
    UIManager:nextTick(function()
        UIManager:show(confirm_box)
    end)
end

function LL:onShowLLCatalog()
    if not NetworkMgr:isOnline() then
        NetworkMgr:turnOnWifiAndWaitForConnection(function()
            UIManager:scheduleIn(2, function() self:openLL() end)
        end)
        return
    end

    self:openLL()
end

function LL:openLL()
    self.ll_browser = LLBrowser:new{
        title = _("LazyLibrarian catalog"),
        is_popout = false,
        is_borderless = true,
        title_bar_fm_style = true,
        file_downloaded_callback = function(file)
            self:showFileDownloadedDialog(file)
        end,
        close_callback = function()
            UIManager:close(self.ll_browser)
        end,
    }

    UIManager:show(self.ll_browser)
end

return LL
