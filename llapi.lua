require("httprequest")

function LLBrowser:forceSearch()
    local res = self:request(self.apiurl .. "&cmd=forceBookSearch&type=eBook", "GET")
    if (not res) then return end
end

function LLBrowser:queueBook(bookid)
    local res = self:request(self.apiurl .. "&cmd=queueBook&id=" .. bookid .. "&type=eBook", "GET")
    if (not res) then return end
end

function LLBrowser:addBook(bookid)
    local res = self:request(self.apiurl .. "&cmd=addBook&id=" .. bookid, "GET")
    if (not res) then return end
end

function LLBrowser:addAndSearchBook(bookid)
    self:addBook(bookid)
    os.execute("sleep 4")
    self:queueBook(bookid)
    os.execute("sleep 2")
    self:forceSearch()
end
