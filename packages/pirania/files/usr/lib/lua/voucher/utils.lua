#!/bin/lua

local json = require('luci.jsonc')
local fs = require("nixio.fs")

local utils = {}

-- Used to get shell output
local function shell (command)
  -- TODO(nicoechaniz): sanitize or evaluate if this is a security risk
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Used to escape "'s by toCSV
local function escapeCSV (s)
  if string.find(s, '[,"]') then
    s = '"' .. string.gsub(s, '"', '""') .. '"'
  end
  return s
end

local function dateNow ()
  return os.time() * 1000
end

-- Convert from CSV string to table (converts a single line of a CSV file)
local function fromCSV (s)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end

-- Convert from table to CSV string
local function toCSV (tt)
  local s = ""
  for _,p in ipairs(tt) do
    s = s .. "," .. escapeCSV(p)
  end
  return string.sub(s, 2)      -- remove first comma
end

utils.writeJsonFile = function(path, content)
  local res = {
      success = false
  }
  local file = io.open(path, "w")
  if file then
      local jsonContent = json.stringify(content)
      file:write(jsonContent)
      io.close(file)
      res.success = true
  end
  return res
end

utils.readJsonFile = function(path)
    local file = io.open( path, "r" )
    local result = {}
    if file then
      local contents = file:read( "*a" )
      result = json.parse(contents);
    end
    return result
end

utils.from_csv_to_table = function(filename)
    local line, lines, fh, err

    lines = {}

    fh, err = io.open(filename)
    if err then
        return nil
    end

    while true do
        line = fh:read()
        if line == nil or line == '' then break end

        table.insert(lines, fromCSV(line))
    end

    fh:close()

    return lines
end

utils.from_table_to_csv = function(filename, table)
    local fho, err
    -- Open a file for write
    fho,err = io.open(filename, "w")

    for _, line in pairs( table ) do
        fho:write(toCSV(line))
        fho:write('\n')
    end

    fho:close()
end

utils.string_split = function(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; local i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

utils.split = function(string, sep)
  local ret = {}
  for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
  return ret
end

utils.format_voucher_key = function (input, type)
  local hostname = fs.readfile("/proc/sys/kernel/hostname"):gsub("\n","")
  local noteHiph = string.gsub(input, "%s+", "-")
  local noteLower = string.lower(noteHiph)
  local key = ''
  if (type == 'member') then
    key = hostname..'-m-'..noteLower
  else
    key = hostname..'-v-'..noteLower
  end
  return key
end

utils.parse_voucher_key = function (key, expire)
  local result = {}
  local startName = 3
  local nameInfo = {}
  for word in key:gmatch("[^-]+") do
      table.insert(nameInfo, word)
  end
  result.node = nameInfo[1]
  if (nameInfo[2] == 'm') then
      result.type = 'member'
  else
      result.type = 'visitor'
  end
  if (#nameInfo > startName) then
      local t = nameInfo[startName]
      for k,v in ipairs(nameInfo) do
          if (k > startName) then
              t = t..'-'..v
          end
      end
      result.note = t
  else result.note = nameInfo[startName]
  end
  local expireDate = tonumber(expire) or 0
  if (expireDate < dateNow()) then
      result.type = 'invalid'
  end
  return result
end

utils.dateNow = dateNow

utils.shell = shell

utils.redirect_page = function(url)
  return string.format([[
    <!doctype html>
    <html>
      <head>
        <title>Redirect</title>
        <meta http-equiv="cache-control" content="no-cache" />
        <meta http-equiv="Refresh" content="0; url=%s">
        <!-- If the meta tag doesn't work, try JavaScript to redirect. -->
        <script type="text/javascript">
          window.location.href = %q
        </script>
      </head>
      <body>
        <!-- If JavaScript doesn't work, give a link to click on to redirect. -->
        <p><a href=%q>ENTER</a></p>
      </body>
    </html>
    ]], url, url , url)
end

return utils
