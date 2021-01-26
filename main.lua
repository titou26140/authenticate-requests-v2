function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)") ~= nil and str:match("(.*/)") or "./"
end

local path = script_path()
local base64 = require(path .. 'base64')
local sha256 = require(path .. 'sha256')
local json = require(path .. 'json')

paramsFilePath = path .. './params.json'
keyFilePath = path .. 'key'

function getParams(paramsFilePath)
    local params = {
        company = nill,
        serialNumber = nil,
        urlRedirect = nil
    }
    local fileContent = nil
    local file = io.open(paramsFilePath, "r")
    if (file == nil) then
        print "File does not exist. Check if your params.json is set."
        os.exit()
    end

    fileContent = json.parse(file:read "*a")

    if (fileContent.company == nil) then
        print "Company is not set in params file."
        os.exit()
    else
        params.company = fileContent.company
    end

    if (fileContent.serialNumber == nil) then
        print "Serial Number is not set in params file."
        os.exit()
    else
        params.serialNumber = fileContent.serialNumber
    end

    if (fileContent.urlRedirect == nil) then
        print "urlRedirect is not set in params file."
        os.exit()
    else
        params.urlRedirect = fileContent.urlRedirect
    end

    io.close(file)
    return params
end

function genToken(params)
    params.date = os.date("%d-%m-%Y")
    params.timestamp = os.time(os.date("!*t"))
    return base64.encode(json.stringify(params))
end

function genHash(encodedToken, keyFilePath)
    local file = io.open(keyFilePath, "r")

    if (file == nil) then
        error("Key file does not exit.")
    end
    local key = file:read "*a"
    local hash = sha256.hmac_sha256(key, encodedToken)
    io.close(file)

    return hash
end

function handle_request(env)
    local params = getParams(paramsFilePath)
    local token = genToken(params)
    local hash = genHash(token, keyFilePath)
    uhttpd.send("Status: 301 Moved Permanently\r\n")
    uhttpd.send("Content-Type: text/html\r\n\r\n")
    uhttpd.send("<script>document.location.href='" .. params.urlRedirect .. "/" .. token .. "/" .. hash .. "';</script>")
end

print("Date : " .. os.date("%d-%m-%Y"))
print("timestamp : " .. os.time(os.date("!*t")));