local base64 = require "./base64"
local sha256 = require("sha256")
local json = require("json")

paramsFilePath = "params.json"
keyFilePath = "key"

function getParams (paramsFilePath)
  local params = {company = nil, serialNumber = nil, urlRedirect = nil}
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
  return base64.encode(json.stringify(params))
end

function genHash(encodedToken, keyFilePath)
  local file = io.open(keyFilePath, "r")

  if (file == nil) then
    error("Key file does not exit.")
  end
  key = file:read "*a"
  io.close(file)

  return sha256.hmac_sha256(key, encodedToken)
end

function handle_request(env)
  local params = getParams(paramsFilePath)
  local token = genToken(params)
  local hash = genHash(token, keyFilePath)
  print(hash)
  uhttpd.send("Status: 301 Moved Permanently\r\n")                                                               
  uhttpd.send("Content-Type: text/html\r\n\r\n")                                                                 
  uhttpd.send("<head><meta http-equiv='refresh' content='0; url='" .. params.urlRedirect .. "/?token=" .. token .. "&hash=" .. hash .."' /></head>")                                                                                                        
end