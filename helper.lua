package.path = package.path..';.luarocks/share/lua/5.2/?.lua;.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath..';.luarocks/lib/lua/5.2/?.so'
serpent = require "serpent"
https = require('ssl.https')
json = require "JSON"
JSON = require "cjson"
redis_ = require "redis"
redis = Redis.connect('127.0.0.1', 6379)
URL = require('socket.url')
lgi = require ('lgi')
notify = lgi.require('Notify')
notify.init ("Telegram updates")
CFG = loadfile("./data/config.lua")()
_config = CFG
print("Bot Token: "..CFG.Token)
API = "https://api.telegram.org/bot"..CFG.Token
plugins = {}

function request(url)
	local dat, res = https.request(url)
	local tab = JSON.decode(dat)
	if res ~= 200 then
		return false 
	end
	if not tab.ok then
		return false 
	end
	return tab
end

function GetStart()
	B = nil
	while not B do
		B = request(API.."/getMe")
	end
	B = B.result
	last_update = last_update or 0
	last_cron = last_cron or os.time()
	started = true
end

function GetUpdates(offset)
	local url = API.."/getUpdates?timeout=10"
	if offset then
		url = url.."&offset="..offset
	end
	return request(url)
end

function load_data(filename)
	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)
	return data
end

function match_helper(msg)
	for name,plugin in pairs(plugins) do
		for k,pattern in pairs(plugin.inline) do
			local matches = Patt(pattern, msg.text or msg.caption or msg.query)
			if matches then
				if plugin.helper then
					local result = plugin.helper(msg, matches)
						if result then
							get_alert(msg.cb_id, result)
						end
					end
				return
			end
		end
	end
end

function get_var_inline(msg)
	if msg.query then
		if msg.query:match("-%d+") then
			msg.chat = {}
			msg.chat.id = "-"..msg.query:match("%d+")
		end
	elseif not msg.query then
		msg.chat.id = msg.chat.id
	end
	match_helper(msg)
end

function Patt(pattern, text, lower_case)
  if text then
    local matches = {}
    if lower_case then
      matches = { string.match(text:lower(), pattern) }
    else
      matches = { string.match(text, pattern) }
    end
      if next(matches) then
        return matches
      end
  end
end

local function inline_key(msg)
  msg.text = '###cb:'..msg.data
  msg.cb = true
if msg.message then
  msg.old_text = msg.message.text
  msg.old_date = msg.message.date
  msg.message_id = msg.message.message_id
  msg.chat = msg.message.chat
  msg.message_id = msg.message.message_id
  msg.chat = msg.message.chat
else
	msg.chat = {type = 'inline', id = msg.from.id, title = msg.from.first_name}
	msg.message_id = msg.inline_message_id
    end
  msg.cb_id = msg.id
  msg.date = os.time()
  msg.message = nil
  msg.target_id = msg.data:match('.*:(-?%d+)')
  return get_var(msg)
end

function get_var(msg)
	msg.reply = {}
	msg.fwd = {}
	msg.data = {}
	msg.id = msg.message_id
	msg.from.name = msg.from.first_name
	msg.from.name2 = msg.from.last_name
	match_helper(msg)
end
	
function load_plugins()
	P = {
	"TD"
	}
	for k, v in pairs(P) do
		local ok, err =  pcall(function()
		local t = loadfile(v..'.lua')()
		plugins[v] = t
		end)
		if not ok then
			print('\27[31mError Loading! '..v..'\27[39m')
			print(tostring(io.popen("lua "..v..".lua"):read('*all')))
			print('\27[31m'..err..'\27[39m')
		else
			print(v..' Has Been Started!')
		end
	end
end
	
GetStart()
load_plugins()

while started do
	local res = GetUpdates(last_update+1)
	if res then
		for i,v in ipairs(res.result) do
			last_update = v.update_id
			if v.edited_message then
				get_var(v.edited_message)
			elseif v.message then
				get_var(v.message)
			elseif v.inline_query then
				get_var_inline(v.inline_query)
			elseif v.callback_query then
				inline_key(v.callback_query)
			end
		end
	else
		print("nil")
	end
	if last_cron < os.time() - 30 then
		for name,plugin in pairs(plugins) do
			if plugin.cron then
				local res, E = pcall(
				function()
					plugin.cron()
				end)
			end
			if not res then
				print('Error Loading: '..E) 
			end
		end
		last_cron = os.time()
	end
end