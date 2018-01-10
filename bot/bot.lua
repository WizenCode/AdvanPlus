tdcli = dofile('./tg/tdcli.lua')
require('./bot/commands')
serpent = require "serpent"
http = require "socket.http"
URL = require "socket.url"
https = require "ssl.https"
ltn12 = require "ltn12"
json = require "JSON"
JSON = require "cjson"
redis_ = require "redis"
redis = Redis.connect('127.0.0.1', 6379)
lgi = require ('lgi')
notify = lgi.require('Notify')
notify.init ("Telegram updates")
chats = {}
plugins = {}

function do_notify (user, msg)
	local n = notify.Notification.new(user, msg)
	n:show ()
end
function dl_cb (arg, data)

end
function vardump(value)
	print(serpent.block(value, {comment=false}))
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
function save_data(filename, data)
	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()
end
function save_config( )
	serialize_to_file(_config, './data/config.lua')
end
function whoami()
	local usr = io.popen("whoami"):read('*a')
	usr = string.gsub(usr, '^%s+', '')
	usr = string.gsub(usr, '%s+$', '')
	usr = string.gsub(usr, '[\n\r]+', ' ') 
	if usr:match("^root$") then
		tcpath = '/root/.telegram-cli'
	elseif not usr:match("^root$") then
		tcpath = '/home/'..usr..'/.telegram-cli'
	end
end
function create_config( )
	io.write('\n\27[1;33m Please Send Me Your Telegram ID Here (This ID IS Bot Owner): \27[0;39;49m\n')
	local owner_id =  tonumber(io.read())
	io.write('\n\27[1;33m Now Send Helper UserName Without @ : \27[0;39;49m\n')
	local Helper_ = io.read()
	io.write('\n\27[1;33m Now Send Helper Token From @botfather: \27[0;39;49m\n')
	local Token_ = io.read()
	config = {
    bot_owner = {owner_id},
    sudo_users = {BOT},
	cmd = '^[/!#]',
	Helper = Helper_,
	Token = Token_,
  }
	serialize_to_file(config, './data/config.lua')
end
color={
  black={30,40},
  red={31,41},
  green={32,42},
  yellow={33,43},
  blue={34,44},
  magenta={35,45},
  cyan={36,46},
  white={37,47}
}
local blank1 = "\027["..color.cyan[2]..";"..color.white[1].."m                         \027[00m"
local blank2 = "\027["..color.cyan[1]..";"..color.white[2].."m                         \027[00m"
function load_config( )
	local f = io.open('./data/config.lua', "r")
	if not f then
		create_config()
	else
		f:close()
	end
	local config = loadfile ("./data/config.lua")()
	for v,owner in pairs(config.bot_owner) do
	    print("\027["..color.black[2]..";"..color.green[1].."m   Bots Owner: " .. owner .. " \027[00m")
	end
	for v,user in pairs(config.sudo_users) do
	    print("\027["..color.black[1]..";"..color.green[2].."m   Sudo Users: " .. user .. " \027[00m")
	end
	return config
end
whoami()
_config = load_config()

function load_plugins()
	local config = loadfile ("./data/config.lua")()
	plug = {
	"TD"
	}
	if redis:get("BotStartedTester") then
		redis:del("BotStartedTester")
	else
		redis:set("BotStarted?",true)
	end
	if not redis:get("CheckVersion") then
		redis:set("CheckVersion", "1.0.0")
		redis:set("CheckVersionID", 100)
	end
	print(blank2)
	print("\027["..color.cyan[1]..";"..color.white[2].."m    Enabled Plugins:     \027[00m")
	print(blank2)
    print(blank1)
	for k,v in pairs(plug) do
	    w = string.len(v)
	    if w == 1 then
		    space = "            "
		elseif w == 2 then
		    space = "           "
		elseif w == 3 then
		    space = "          "
		elseif w == 4 then
		    space = "         "
		elseif w == 5 then
		    space = "        "
		elseif w == 6 then
		    space = "       "
		elseif w == 7 then
		    space = "      "
		elseif w == 8 then
		    space = "     "
		elseif w == 9 then
		    space = "    "
		elseif w == 10 then
		    space = "   "
		elseif w == 11 then
		    space = "  "
		elseif w == 12 then
		    space = " "
		elseif w > 12 then
			space = ""
		end
		local ok, err =  pcall(function()
		plugins[v] = loadfile(v..'.lua')()
		end)
		if ok then
			print("\027["..color.cyan[2]..";"..color.white[1].."m    Loading "..v..""..space.."\027[00m")
		else
			print("\027["..color.red[2]..";"..color.white[1].."m    Loading "..v..""..space.."\027[00m")
			print(tostring(io.popen("lua "..v..".lua"):read('*all')))
		end
	end
	print(blank1)
	print(blank2)
	print(blank2)
	print("")
	print("Source Version: "..redis:get("CheckVersion"))
end
function msg_valid(msg)
	local msg_time = os.time() - 60
	local data = load_data('./data/moderation.json')
	if msg.date_ < tonumber(msg_time) then
		print("\027["..color.red[2]..";"..color.white[1].."m OLD MSG \027[00m")
		return false
	end
    if msg.sender_user_id_ == data.id_ then
		return false
	end
    return true
end
function match_pattern(pattern, text, lower_case)
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
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
		pre_msg = plugin.pre_process(msg)
    end
  end
  return pre_msg
end
function matching(msg, pattern, plugin, plugin_name)
	matches = match_pattern(pattern, msg.text or msg.media.caption)
	if matches then
		if plugin.run then
		print("\027["..color.blue[2]..";"..color.white[1].."m Matches: \027[00m "..pattern)
			if not warns_user_not_allowed(plugin, msg) then
				local result = plugin.run(msg, matches)
				if result then
					tdcli.sendChatAction(msg.chat_id_, 'Typing', dl_cb, nil)
					tdcli.sendMessage(msg.chat_id_, msg.id_, 0, result, 0, "md")
				end
			end
		end
		return
	end
end
function match_plugin(plugin, plugin_name, msg)
	for k, pattern in pairs(plugin.patterns) do
		matching(msg, pattern, plugin, plugin_name)
	end
end
function match_plugins(msg)
	for name, plugin in pairs(plugins) do
		match_plugin(plugin, name, msg)
	end
end
load_plugins()
 function var_cb(msg, data)
	bot = {}
	msg.to = {}
	msg.from = {}
	msg.media = {}
	msg.id = msg.id_
	msg.to.type = gp_type(data.chat_id_)
	if data.content_.caption_ then
		msg.media.caption = data.content_.caption_
	end

	if data.reply_to_message_id_ ~= 0 then
		msg.reply_id = data.reply_to_message_id_
    else
		msg.reply_id = false
	end
	 function get_gp(arg, data)
		if gp_type(msg.chat_id_) == "channel" or gp_type(msg.chat_id_) == "chat" then
			msg.to.title = data.title_
			msg.to.id = msg.chat_id_
		else
			msg.to.id = msg.chat_id_
			msg.to.title = false
		end
	end
	tdcli_function ({ ID = "GetChat", chat_id_ = data.chat_id_ }, get_gp, nil)
	function botifo_cb(arg, data)
		bot.id = data.id_
		our_id = data.id_
	end
	tdcli_function({ ID = 'GetMe'}, botifo_cb, {chat_id=msg.chat_id_})
	 function get_user(arg, data)
		msg.from.id = data.id_
		if data.username_ then
			msg.from.username = data.username_
		else
			msg.from.username = false
		end
		if data.first_name_ then
			msg.from.first_name = data.first_name_
		end
		if data.last_name_ then
			msg.from.last_name = data.last_name_
		else
			msg.from.last_name = false
		end
		if data.first_name_ and data.last_name_ then
			msg.from.print_name = data.first_name_..' '..data.last_name_
		else
			msg.from.print_name = data.first_name_
		end
     False = false
     pre_process_msg(msg)
		match_plugins(msg)
	end
	tdcli_function ({ ID = "GetUser", user_id_ = data.sender_user_id_ }, get_user, nil)

end
function file_cb(msg)
	if msg.content_.ID == "MessageDocument" then
		document_id, document_name = '', ''
		local function get_cb(arg, data)
			document_id = data.content_.document_.document_.id_
			document_name = data.content_.document_.file_name_
			tdcli.downloadFile(document_id, dl_cb, nil)
		end
		tdcli_function ({ ID = "GetMessage", chat_id_ = msg.chat_id_, message_id_ = msg.id_ }, get_cb, nil)
	end
end
function tdcli_update_callback (data)
	if (data.ID == "UpdateNewMessage") then
		local msg = data.message_
		local d = data.disable_notification_
		local chat = chats[msg.chat_id_]
		tdcli.openChat(msg.chat_id_, dl_cb, nil)
		GP = redis:smembers("BotGroups")
		if #GP ~= 0 then
			for k,v in pairs(GP) do
				tdcli.openChat(v, dl_cb, nil)
			end
		end
		tdcli.viewMessages(msg.chat_id_, {[0] = msg.id_}, dl_cb, nil)
		redis:incr('getMessages:'..msg.sender_user_id_..':'..msg.chat_id_)
		redis:incr('getMessages:'..msg.chat_id_)
if msg_valid(msg) then
	var_cb(msg, msg)
	
	if msg.to.type == "channel" and not redis:sismember("BotHaveRankMembers", msg.sender_user_id_) and not redis:sismember("BotHaveRankMembers(Group)"..msg.chat_id_, msg.sender_user_id_) and not redis:get("AllowUser~"..msg.sender_user_id_.."~From~"..msg.chat_id_) then
		if redis:hget("GroupSettings:"..msg.chat_id_, "mute_all") == "yes" then
			del_msg(msg.chat_id_, tonumber(msg.id))
		end
		if redis:get("~LockGroup~"..msg.chat_id_) then
			del_msg(msg.chat_id_, tonumber(msg.id))
		end
		if msg.content_.ID == "MessageSticker" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_sticker") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."sticker") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageText" then
			msg.text = msg.content_.text_
			local link_msg = msg.text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or msg.text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Dd][Oo][Gg]/") or msg.text:match("[Tt].[Mm][Ee]/") or msg.text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]/")
			if link_msg and redis:hget("GroupSettings:"..msg.chat_id_, "lock_link") == "yes" then
				if not redis:get("Allow~"..msg.text.."From~"..msg.chat_id_) then
					del_msg(msg.chat_id_, tonumber(msg.id))
				end
			end
			if redis:hget("GroupSettings:"..msg.chat_id_, "lock_MaxWords") == "yes" then
				num = string.len(msg.text)
				if redis:hget("GroupSettings:"..msg.chat_id_, "MaxWords") then 	
					MaxWords = tonumber(redis:hget("GroupSettings:"..msg.chat_id_, "MaxWords"))
				else 	
					MaxWords = 50
				end
				if tonumber(num) > tonumber(MaxWords) then
					del_msg(msg.chat_id_, tonumber(msg.id))
				end
			end
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_text") == "yes" then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessagePhoto" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_photo") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."photo") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageVideo" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_video") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."video") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageDocument" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_document") == "yes" then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageAnimation" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_gif") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."gif") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageContact" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_contact") == "yes" then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageLocation" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_location") == "yes" then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageVoice" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_voice") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."voice") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageGame" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_game") == "yes" then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		elseif msg.content_.ID == "MessageAudio" then
			if redis:hget("GroupSettings:"..msg.chat_id_, "mute_audio") == "yes" or redis:get("mute"..msg.sender_user_id_.."from"..msg.chat_id_.."audio") then
				del_msg(msg.chat_id_, tonumber(msg.id))
			end
		end
	end
	
	file_cb(msg)
	if msg.content_.ID == "MessageText" then
		msg.text = msg.content_.text_
		msg.edited = false
	elseif msg.content_.ID == "MessageChatAddMembers" then
		for i=0,#msg.content_.members_ do
			msg.adduser = msg.content_.members_[i].id_
		end
	elseif msg.content_.ID == "MessageForwardedFromUser" then
		msg.forward_info_ = true
	end
	if msg.content_.photo_ then
		return false
	end
end
	elseif data.ID == "UpdateMessageContent" then
		cmsg = data
		local function edited_cb(arg, data)
			msg = data
			msg.media = {}
			if cmsg.new_content_.text_ then
				msg.text = cmsg.new_content_.text_
			end
			if cmsg.new_content_.caption_ then
				msg.media.caption = cmsg.new_content_.caption_
			end
			msg.edited = true
			if msg_valid(msg) then
				var_cb(msg, msg)
			end
		end
	tdcli_function ({ ID = "GetMessage", chat_id_ = data.chat_id_, message_id_ = data.message_id_ }, edited_cb, nil)
	elseif data.ID == "UpdateFile" then
		file_id = data.file_.id_
	elseif (data.ID == "UpdateChat") then
		chat = data.chat_
		chats[chat.id_] = chat
	elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
		tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)    
	end
end
