--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tConfig, tChatHistory = {
		sBotName = SetMan.GetString( 21 ) or "PtokaX",
		sProfiles = "012",		-- No history for commands from users with profiles
		sLogsPath = "/www/ChatLogs/",
		sTimeFormat = "[%I:%M:%S %p] ",
		iMaxLines = 100,
	}, { "Hi!" }
end

function ChatArrival( tUser, sMessage )
	LogMessage( sMessage:sub(1, -2) )
	local sCmd, sData = sMessage:match "%b<> [-+*/?!#](%w+)%s?(.*)|"
	local sTime = os.date( tConfig.sTimeFormat )
	local sChatLine = sTime..sMessage:sub( 1, -2 )
	if not( sCmd and tConfig.sProfiles:find(tUser.iProfile) ) then
		table.insert( tChatHistory, sChatLine )
		if tChatHistory[ tConfig.iMaxLines + 1 ] then
			table.remove( tChatHistory, 1 )
		end
	end
	if sCmd then
		return ExecuteCommand( sCmd:lower(), sData, tUser )
	end
	return false
end

function ToArrival( tUser, sMessage )
	local sTo, sFrom = sMessage:match "$To: (%S+) From: (%S+)"
	if sTo ~= tConfig.sBotName then return false end
	local sCmd, sData = sMessage:match "%b$$%b<> [-+*/?!#](%w+)%s?(.*)|"
	if sCmd then
		return ExecuteCommand( sCmd:lower(), sData, tUser, true )
	end
	return false
end

function UserConnected( tUser )
	if tUser.iProfile == -1 then return end
	local sLastLines = "<"..tConfig.sBotName.."> Here is what was happening a few moments ago:\n\t"
	sLastLines = sLastLines..History( 15 )
	Core.SendToUser( tUser, sLastLines )
end

RegConnected, OpConnected = UserConnected, UserConnected

function History( iNumLines )
	local iStartIndex = ( #tChatHistory - iNumLines ) + 1
	if #tChatHistory < iNumLines then
		iStartIndex = 1
	end
	if iStartIndex > #tChatHistory then
		iStartIndex = #tChatHistory
	end
	return table.concat( tChatHistory, "\n\t", iStartIndex, #tChatHistory )
end

function LogMessage( sLine )
	local sTime = os.date( tConfig.sTimeFormat )
	local sChatLine, sFileName = sTime..sLine, tConfig.sLogsPath..os.date( "%Y/%m/%d_%m_%Y" )..".txt"
	sChatLine = sChatLine:gsub( "&#124;", "|" ):gsub( "&#36;", "$" ):gsub( "[\n\r]+", "\n\t" )
	local fWrite = io.open( sFileName, "a" )
	fWrite:write( sChatLine.."\n" )
	fWrite:flush()
	fWrite:close()
end

function Reply( tUser, sMessage, bIsPM )
	if bIsPM then
		Core.SendPmToUser( tUser, tConfig.sBotName, sMessage )
	else
		Core.SendToUser( tUser, sMessage )
	end
	return true
end

ExecuteCommand = {
	history = function()
		local sPrefix = ( "<%s> \n\r\t\tChat history bot for HiT Hi FiT Hai\n\tShowing the mainchat history for past %%d messages\n\t" ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			local iLimit = tonumber( sData )
			if (not iLimit) or iLimit > tConfig.iMaxLines or iLimit < 0 then iLimit = 15 end
			local sReply = sPrefix:format(iLimit)..History(iLimit)
			return Reply( tUser, sReply, bIsPM )
		end
	end,

	hubtopic = function()
		local sPrefix, sNoTopic = ( "<%s> Current hub topic is: %%s." ):format( tConfig.sBotName ), "Sorry! No hub topic exists."
		return function( tUser, sData, bIsPM )
			local sReply = sPrefix:format( SetMan.GetString(10) or sNoTopic )
			return Reply( tUser, sReply, bIsPM )
		end
	end,

	topic = function()
		local sErased, sUpdated = ( "<%s> Hub topic was erased by [ %%s ]." ):format( tConfig.sBotName ), ( "<%s> Hub topic was updated by [ %%s ] to %%s." ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			if not ProfMan.GetProfilePermission( tUser.iProfile, 7 ) then return false end
			if sData:len() == 0 then
				Core.SendToAll( sErased:format(tUser.sNick) )
				SetMan.SetString( 10, "" )
				return true
			end
			SetMan.SetString( 10, sData )
			Core.SendToAll( sUpdated:format(tUser.sNick, sData) )
			return true
		end
	end,
}
