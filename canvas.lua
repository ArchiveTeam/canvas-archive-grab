local url_count = 0
local tries = 0


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end


wget.callbacks.lookup_host = function(host)
  if host == "canv.as" or host == "www.canv.as" then
    return 'drawquest-export.s3-website-us-east-1.amazonaws.com'
  end
end

--
--wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
--  if urlpos["link_inline_p"] then
--    -- always download the page requisites
--    return true
--  end
--
--  return verdict
--end


wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]

  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()

  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = read_file(file)

  for url in string.gmatch(html, "url%(([%w/%%.:_-]+)%)") do

    -- prevent segfault of missing full url
    if url:sub(1, 4) ~= 'http' then
      if url:sub(1, 1) ~= '/' then
        url = '/' .. url
      end

      url = 'http://canv.as' .. url
    end

--    io.stdout:write("\n  Added " .. url .. ".\n")
--    io.stdout:flush()

    table.insert(urls, { url=url })
  end

  for url in string.gmatch(html, "'(http[%w/%%.:_-]+)'") do
--    io.stdout:write("\n  Added " .. url .. ".\n")
--    io.stdout:flush()
    table.insert(urls, { url=url })
  end

  return urls
end
