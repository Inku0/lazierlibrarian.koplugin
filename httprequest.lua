local http = require("socket.http")
local ltn12 = require("ltn12")
local logger = require("logger")

function LLBrowser:request(url, method)
    --logger.info("Request:", url)

    local response_tbl = {}
    local ret, status, headers = http.request {
        url = url,
        headers = self.headers,
        method = method,
        sink = ltn12.sink.table(response_tbl)
    }

    local response = table.concat(response_tbl)

    if status ~= 200 then
        logger.err("Error during request:", status)
        logger.err(response)
        return false
    end

    return response
end
