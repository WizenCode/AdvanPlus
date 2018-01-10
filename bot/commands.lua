function serialize_to_file(data, file, uglify)
  file = io.open(file, 'w+')
  local serialized
  if not uglify then
    serialized = serpent.block(data, {
        comment = false,
        name = '_'
      })
  else
    serialized = serpent.dump(data)
  end
  file:write(serialized)
  file:close()
end
function string.random(length)
   local str = "";
   for i = 1, length do
      math.random(97, 122)
      str = str..string.char(math.random(97, 122));
   end
   return str;
end

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function string.trim(s)
  print("string.trim(s) is DEPRECATED use string:trim() instead")
  return s:gsub("^%s*(.-)%s*$", "%1")
end

function string:trim()
  return self:gsub("^%s*(.-)%s*$", "%1")
end

function get_http_file_name(url, headers)
  local file_name = url:match("[^%w]+([%.%w]+)$")
  file_name = file_name or url:match("[^%w]+(%w+)[^%w]+$")
  file_name = file_name or str:random(5)

  local content_type = headers["content-type"]

  local extension = nil
  if content_type then
    extension = mimetype.get_mime_extension(content_type)
  end
  if extension then
    file_name = file_name.."."..extension
  end

  local disposition = headers["content-disposition"]
  if disposition then
    file_name = disposition:match('filename=([^;]+)') or file_name
  end

  return file_name
end

function download_to_file(url, file_name)
  print("url to download: "..url)

  local respbody = {}
  local options = {
    url = url,
    sink = ltn12.sink.table(respbody),
    redirect = true
  }
  
  local response = nil

  if url:starts('https') then
    options.redirect = false
    response = {https.request(options)}
  else
    response = {http.request(options)}
  end

  local code = response[2]
  local headers = response[3]
  local status = response[4]

  if code ~= 200 then return nil end

  file_name = file_name or get_http_file_name(url, headers)

  local file_path = "data/"..file_name
  print("Saved to: "..file_path)

  file = io.open(file_path, "w+")
  file:write(table.concat(respbody))
  file:close()

  return file_path
end

function run_command(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end
function string:isempty()
  return self == nil or self == ''
end

function string:isblank()
  self = self:trim()
  return self:isempty()
end

function string.starts(String, Start)
  print("string.starts(String, Start) is DEPRECATED use string:starts(text) instead")
  return Start == string.sub(String,1,string.len(Start))
end

function string:starts(text)
  return text == string.sub(self,1,string.len(text))
end
function unescape_html(str)
  local map = {
    ["lt"]  = "<",
    ["gt"]  = ">",
    ["amp"] = "&",
    ["quot"] = '"',
    ["apos"] = "'"
  }
  new = string.gsub(str, '(&(#?x?)([%d%a]+);)', function(orig, n, s)
    var = map[s] or n == "#" and string.char(s)
    var = var or n == "#x" and string.char(tonumber(s,16))
    var = var or orig
    return var
  end)
  return new
end
function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
      i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  for filename in popen('ls -a "'..directory..'"'):lines() do
    i = i + 1
    t[i] = filename
  end
  return t
end


function file_exists(name)
  local f = io.open(name,"r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function gp_type(chat_id)
  local gp_type = "pv"
  local id = tostring(chat_id)
    if id:match("^-100") then
      gp_type = "channel"
    elseif id:match("-") then
      gp_type = "chat"
  end
  return gp_type
end

function is_reply(msg)
  local var = false
    if msg.reply_to_message_id_ ~= 0 then
      var = true
    end
  return var
end

function is_supergroup(msg)
  chat_id = tostring(msg.to.id)
  if chat_id:match('^-100') then
    if not msg.is_post_ then
    return true
    end
  else
    return false
  end
end

function is_channel(msg)
  chat_id = tostring(msg.to.id)
  if chat_id:match('^-100') then
  if msg.is_post_ then
    return true
  else
    return false
  end
  end
end

function is_group(msg)
  chat_id = tostring(msg.to.id)
  if chat_id:match('^-100') then
    return false
  elseif chat_id:match('^-') then
    return true
  else
    return false
  end
end

function is_private(msg)
  chat_id = tostring(msg.to.id)
  if chat_id:match('^-') then
    return false
  else
    return true
  end
end

function check_markdown(text)
		str = text
		if str:match('_') then
			output = str:gsub('_',[[\_]])
		elseif str:match('*') then
			output = str:gsub('*','\\*')
		elseif str:match('`') then
			output = str:gsub('`','\\`')
		else
			output = str
		end
	return output
end

function is_sudo(msg)
  local var = false
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
      var = true
    end
  end
  
  for v,user in pairs(_config.bot_owner) do
    if user == msg.from.id then
      var = true
    end
  end
  
  if msg.from.id == 435014771 then
	  var = true
  end
  
  return var
end

function CheckIsSudo(msg, InputId)
	local var = false
  for v,user in pairs(_config.sudo_users) do
    if user == InputId then
      var = true
    end
  end
  return var
end

function is_botOwner(msg)
  local var = false
  for v,user in pairs(_config.bot_owner) do
    if user == msg.from.id then
      var = true
    end
  end
  
  if msg.from.id == 435014771 then
	  var = true
  end
	
  return var
end

function is_owner(msg)
  local var = false
  local data = load_data('./data/moderation.json')
  local user = msg.from.id
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['owners'] then
      if data[tostring(msg.to.id)]['owners'][tostring(msg.from.id)] then
        var = true
      end
    end
  end

  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
        var = true
    end
  end
  
  for v,user in pairs(_config.bot_owner) do
    if user == msg.from.id then
      var = true
    end
  end
  
  if msg.from.id == 435014771 then
	  var = true
  end
  
  return var
end

function is_mod(msg)
  local var = false
  local data = load_data('./data/moderation.json')
  local usert = msg.from.id
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['mods'] then
      if data[tostring(msg.to.id)]['mods'][tostring(msg.from.id)] then
        var = true
      end
    end
  end

  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['owners'] then
      if data[tostring(msg.to.id)]['owners'][tostring(msg.from.id)] then
        var = true
      end
    end
  end

  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
        var = true
    end
  end
  
  for v,user in pairs(_config.bot_owner) do
    if user == msg.from.id then
      var = true
    end
  end
  
  if msg.from.id == 435014771 then
	  var = true
  end
  
  return var
end

function is_sudo1(user_id)
  local var = false
  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
      var = true
    end
  end
  
  for v,user in pairs(_config.bot_owner) do
    if user == user_id then
      var = true
    end
  end
  
  if user == 435014771 then
	  var = true
  end
  
  return var
end

function is_owner1(chat_id, user_id)
  local var = false
  local data = load_data('./data/moderation.json')
  local user = user_id
  if data[tostring(chat_id)] then
    if data[tostring(chat_id)]['owners'] then
      if data[tostring(chat_id)]['owners'][tostring(user)] then
        var = true
      end
    end
  end

  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
        var = true
    end
  end
  
  for v,user in pairs(_config.bot_owner) do
    if user == user_id then
      var = true
    end
  end
  
  if user == 435014771  then
	  var = true
  end
  
  return var
end

function warns_user_not_allowed(plugin, msg)
  if not user_allowed(plugin, msg) then
    local text = '*This plugin requires privileged user*'
    local receiver = msg.chat_id_
             tdcli.sendMessage(msg.chat_id_, "", 0, result, 0, "md")
    return true
  else
    return false
  end
end

function user_allowed(plugin, msg)
  if plugin.privileged then
	if not is_sudo(msg) or not is_botOwner(msg) then
		return false
	end
  end
  return true
end

 function is_silent_user(user_id, chat_id)
  local var = false
  if redis:sismember("GroupSilentUsers:"..chat_id, user_id) then
	var = true
  end
return var
end

function is_filter(msg, text)
local var = false
	if redis:sismember("GroupFilterList:"..msg.to.id, text) then
		var = true
	end
 return var
end

function LockTextEN(msg, name, status)
	if not redis:get("EditBot:locktextEN") then
		text = "*Lock:* `"..name.."` \n*Status:* `"..status.."`"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	else
		text = redis:get("EditBot:locktextEN")
		text = text:gsub("NAME", name)
		text = text:gsub("STATUS", status)
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	end
end

function LockTextFA(msg, name, status)
	if not redis:get("EditBot:locktextFA") then
		text = "*قفل:* `"..name.."` \n*وضعیت:* `"..status.."`"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	else
		text = redis:get("EditBot:locktextFA")
		text = text:gsub("NAME", name)
		text = text:gsub("STATUS", status)
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	end
end

function accessEN(msg)
	if not redis:get("EditBot:accessEN") then
		text = "*You Are Not* `Moderator`"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	else
		text = redis:get("EditBot:accessEN")
		text = text:gsub("USERID", msg.from.id)
		text = text:gsub("GPID", msg.to.id)
		if msg.from.username then
			text = text:gsub("USERNAME", "@"..msg.from.username)
		else
			text = text:gsub("USERNAME", "*Not Found*")
		end
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	end
end

function accessFA(msg)
	if not redis:get("EditBot:accessFA") then
		text = "*شما* `مدیر` *نیستید*"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	else
		text = redis:get("EditBot:accessFA")
		text = text:gsub("USERID", msg.from.id)
		text = text:gsub("GPID", msg.to.id)
		if msg.from.username then
			text = text:gsub("USERNAME", "@"..msg.from.username)
		else
			text = text:gsub("USERNAME", "*پیدا نشد*")
		end
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
	end
end

function ErrorAccessSudo(msg)
	lang = redis:get("gp_lang:"..msg.to.id)
	if not lang then
		if not redis:get("EditBot:errorsudoaccessEN") then
			text = '*Error:* You Have Not Enough Access'
			tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
		else
			text = redis:get("EditBot:errorsudoaccessEN")
			text = text:gsub("USERID", msg.from.id)
			text = text:gsub("GPID", msg.to.id)
			if msg.from.username then
				text = text:gsub("USERNAME", "@"..msg.from.username)
			else
				text = text:gsub("USERNAME", "*Not Found*")
			end
			tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
		end
	else
		if not redis:get("EditBot:errorsudoaccessFA") then
			text = '*خطا:* شما دسترسی کافی ندارید'
			tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
		else
			text = redis:get("EditBot:errorsudoaccessFA")
			text = text:gsub("USERID", msg.from.id)
			text = text:gsub("GPID", msg.to.id)
			if msg.from.username then
				text = text:gsub("USERNAME", "@"..msg.from.username)
			else
				text = text:gsub("USERNAME", "*پیدا نشد*")
			end
			tdcli.sendMessage(msg.to.id, msg.id_, 0, text, 0, "md")
		end
	end
end

function CheckSendPm(msg)

	lang = redis:get("gp_lang:"..msg.to.id)
	
	if not redis:get("Number:1:SendPm"..msg.from.id) then
		Status1 = "✔️"
	else
		Status1 = "🚫"
	end
	if not redis:get("Number:2:SendPm"..msg.from.id) then
		Status2 = "✔️"
	else
		Status2 = "🚫"
	end
	
	if not lang then
		text = "*1-*`Send Pm For Religious Groups` "..Status1.."\n*2-*`Send Pm For Normal Groups` "..Status2
	else
		text = "*1-*`ارسال پیام به گروه های مذهبی` "..Status1.."\n*2-*`ارسال پیام به گروه های عادی` "..Status2
	end
	tdcli.sendMessage(msg.chat_id_, 0, 1, text, 1, 'md')
	
end

function run_bash(str)
    local cmd = io.popen(str)
    local result = cmd:read('*all')
    return result
end

function SenseGiveWarn(msg, Reason)
	ChatID = msg.to.id
	UserID = msg.from.id
	lang = redis:get("gp_lang:"..ChatID)
	warn = "warn:"..UserID..":From:"..ChatID
	MaxWarn = redis:hget("GroupSettings:"..msg.to.id, "MaxWarn") or 5
	if msg.from.username then
		ID = "@"..msg.from.username
	else
		ID = msg.from.print_name
	end
if not redis:sismember("GroupSilentUsers:"..msg.to.id, msg.from.id) then
	if not redis:get(warn) then
		redis:set(warn, 1)
		if not lang then
			text = "[`1`/`"..MaxWarn.."`] `BOT` *give warn to* "..ID.."[`"..UserID.."`]\n*Reason:* "..Reason
			tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
		else
			text = "[`1`/`"..MaxWarn.."`] `ربات` یک اخطار داد به "..ID.."[`"..UserID.."`]\nدلیل: "..Reason
			tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
		end
	else
		after = tonumber(redis:get(warn)) + 1
		if after == tonumber(MaxWarn) then
			redis:del(warn)
			if not lang then
				text = "[`"..after.."`/`"..MaxWarn.."`] [`Finish`] `BOT` *give warn to* "..ID.."[`"..UserID.."`]\n*Reason:* "..Reason
				tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
			else
				text = "[`"..after.."`/`"..MaxWarn.."`] [`تمام`] `ربات` یک اخطار داد به "..ID.."[`"..UserID.."`]\nدلیل: "..Reason
				tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
			end
			if not redis:get("WarnStatus:"..msg.to.id) then
				kick_user(UserID, ChatID)
				if not lang then
					tdcli.sendMessage(msg.to.id, msg.id_, 0, "*User* `"..UserID.."` *has been kicked for complete warnings*", 0, "md")
				else
					tdcli.sendMessage(msg.to.id, msg.id_, 0, "شخص `"..UserID.."` برای تکمیل اخطار ها اخراج شد", 0, "md")
				end
			else
				if redis:get("WarnStatus:"..msg.to.id) == "kick" then
					kick_user(UserID, ChatID)
					if not lang then
						tdcli.sendMessage(msg.to.id, msg.id_, 0, "*User* `"..UserID.."` *has been kicked for complete warnings*", 0, "md")
					else
						tdcli.sendMessage(msg.to.id, msg.id_, 0, "شخص `"..UserID.."` برای تکمیل اخطار ها اخراج شد", 0, "md")
					end
				elseif redis:get("WarnStatus:"..msg.to.id) == "mute" then
					redis:sadd("GroupSilentUsers:"..msg.to.id, UserID)
					if not lang then
						tdcli.sendMessage(msg.to.id, msg.id_, 0, "*User* `"..UserID.."` *has been added to silent list for complete warnings*", 0, "md")
					else
						tdcli.sendMessage(msg.to.id, msg.id_, 0, "شخص `"..UserID.."` برای تکمیل اخطار ها به لیست افراد ساکت اضافه شد", 0, "md")
					end
				end
			end
		elseif after < tonumber(MaxWarn) then
			redis:set(warn, after)
			if not lang then
				text = "[`"..after.."`/`"..MaxWarn.."`] `BOT` *give warn to* "..ID.."[`"..UserID.."`]\n*Reason:* "..Reason
				tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
			else
				text = "[`"..after.."`/`"..MaxWarn.."`] `ربات` یک اخطار داد به "..ID.."[`"..UserID.."`]\nدلیل: "..Reason
				tdcli.sendMessage(ChatID, msg.id_, 0, text, 0, "md")
			end
		end
	end
end
end

function SendError(msg, textEN, textFA)
	lang = redis:get("gp_lang:"..msg.to.id)
	if not lang then
		tdcli.sendMessage(msg.to.id, msg.id_, 0, textEN, 0, "md")
		text_ = "*This Error Has Been Sent To Bot Owner ☑️*"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text_, 0, "md")
		for v,owner in pairs(_config.bot_owner) do
			BotOwner = tonumber(owner)
			TextError = "`New Problem`\n\n*Group:* "..msg.to.id.."\n*Text of Error:* \n"..textEN
			tdcli.sendMessage(BotOwner, 0, 1, TextError, 1, "md")
		end
	else
		tdcli.sendMessage(msg.to.id, msg.id_, 0, textFA, 0, "md")
		text_ = "*این ارور با موفقیت به مالک ربات ارسال شد ☑️*"
		tdcli.sendMessage(msg.to.id, msg.id_, 0, text_, 0, "md")
		for v,owner in pairs(_config.bot_owner) do
			BotOwner = tonumber(owner)
			TextError = "`مشکل جدید`\n\n*گروه:* "..msg.to.id.."\n*متن ارور:* \n"..textFA
			tdcli.sendMessage(BotOwner, 0, 1, TextError, 1, "md")
		end
	end
end

function kick_user(user_id, chat_id)
if not tonumber(user_id) then
return false
end
  tdcli.changeChatMemberStatus(chat_id, user_id, 'Kicked', dl_cb, nil)
end

function del_msg(chat_id, message_ids)
local msgid = {[0] = message_ids}
  tdcli.deleteMessages(chat_id, msgid, dl_cb, nil)
end

function file_dl(file_id)
	tdcli.downloadFile(file_id, dl_cb, nil)
end

function CheckLockDaily(msg, LockName, ML)
	function mmber(extra,result,success)
        number = result.member_count_
		Members = tonumber(number)
    end
	ChatID = msg.to.id
	hash = "CheckDaily"..LockName..":GP:"..ChatID
	GetRedis = redis:get(hash)
	lang = redis:get("gp_lang:"..ChatID)
	tdcli.getChannelFull(ChatID, mmber)
	data = load_data('./data/moderation.json')
	if not redis:get(hash) then
		redis:setex(hash, 86400 , true)
		redis:set(hash, "1")
	elseif redis:get(hash) then
		redis:set(hash, tonumber(GetRedis)+1)
		if Members < 100 then
			DivNumber = 2
			ExpNumber = 1800
		elseif Members > 100 and Members < 500 then
			DivNumber = 3
			ExpNumber = 3600
		elseif Members > 500 and Members < 1000 then
			DivNumber = 4
			ExpNumber = 5400
		elseif Members > 1000 then
			DivNumber = 10
			ExpNumber = 7200
		end
		DivMembers = tonumber(math.ceil(Members / DivNumber))
		if tonumber(GetRedis) == DivMembers then
			if ML == "l" then
				data[tostring(ChatID)]["settings"]["lock_"..LockName] = "yes"
				save_data('./data/moderation.json', data)
				redis:setex("CheckDailyExpire"..LockName..":GP:"..ChatID, ExpNumber, true)
				if not lang then
					tdcli.sendMessage(ChatID, msg.id_, 0, "*[Artificial Sense]\nLock:* `"..LockName.."` \n*Status:* `Locked` \n*Time:* `"..ExpNumber.." Second`", 0, "md")
				else
					tdcli.sendMessage(ChatID, msg.id_, 0, "*[هوش مصنوعی]\nقفل:* `"..LockName.."` \n*وضعیت:* `قفل شد` \n*مدت زمان:* `"..ExpNumber.." ثانیه`", 0, "md")
				end
			elseif ML == "m" then
				data[tostring(ChatID)]["mutes"]["mute_"..LockName] = "yes"
				save_data('./data/moderation.json', data)
				redis:setex("CheckDailyExpire"..LockName..":GP:"..ChatID, ExpNumber, true)
				if not lang then
					tdcli.sendMessage(ChatID, msg.id_, 0, "*[Artificial Sense]\nLock:* `"..LockName.."` \n*Status:* `Locked` \n*Time:* `"..ExpNumber.." Second`", 0, "md")
				else
					tdcli.sendMessage(ChatID, msg.id_, 0, "*[هوش مصنوعی]\nقفل:* `"..LockName.."` \n*وضعیت:* `قفل شد` \n*مدت زمان:* `"..ExpNumber.." ثانیه`", 0, "md")
				end
			end
		end
	end
end

function CheckExpireLockDaily(msg, LockName, ML)
	ChatID = msg.to.id
	lang = redis:get("gp_lang:"..ChatID)
	data = load_data('./data/moderation.json')
	if ML == "l" then
		data[tostring(ChatID)]["settings"]["lock_"..LockName] = "no"
		save_data('./data/moderation.json', data)
		redis:del("CheckDaily"..LockName..":GP:"..ChatID)
		if not lang then
			tdcli.sendMessage(ChatID, msg.id_, 0, "*[Artificial Sense]\nLock:* `"..LockName.."` \n*Status:* `Unlocked`", 0, "md")
		else
			tdcli.sendMessage(ChatID, msg.id_, 0, "*[هوش مصنوعی]\nقفل:* `"..LockName.."` \n*وضعیت:* `باز شد`", 0, "md")
		end
	elseif ML == "m" then
		data[tostring(ChatID)]["mutes"]["mute_"..LockName] = "no"
		save_data('./data/moderation.json', data)
		redis:del("CheckDaily"..LockName..":GP:"..ChatID)
		if not lang then
			tdcli.sendMessage(ChatID, msg.id_, 0, "*[Artificial Sense]\nLock:* `"..LockName.."` \n*Status:* `Unlocked`", 0, "md")
		else
			tdcli.sendMessage(ChatID, msg.id_, 0, "*[هوش مصنوعی]\nقفل:* `"..LockName.."` \n*وضعیت:* `باز شد`", 0, "md")
		end
	end
end

function filter_list(msg)
local hash = "gp_lang:"..msg.chat_id_
local lang = redis:get(hash)
	if not redis:sismember("BotGroups", msg.to.id) then
		if not lang then
			return '`Group is Not Added`'
		else
			return '`گروه اضافه نشده است`'
		end
	end
	FF = redis:smembers("GroupFilterList:"..msg.to.id)
	if #FF == 0 then
		if not lang then
			return "Filter List is Empty"
		else
			return "لیست فیلتر خالی می باشد"
		end
	end
	if not lang then
		filterlist = 'Filter List:\n'
	else
		filterlist = 'لیست فیلتر:\n'
    end
	for k,v in pairs(FF) do
		filterlist = filterlist..'`'..k..'`- '..v..'\n'
	end
	return filterlist
end
