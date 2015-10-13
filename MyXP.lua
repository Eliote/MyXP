SLASH_MYXP1 = '/mxp';
SLASH_MYXP2 = '/myxp';

BINDING_HEADER_MYXP = "MyXP";
BINDING_NAME_MYXP_SAY = "Say";
BINDING_NAME_MYXP_PARTY = "Party";
BINDING_NAME_MYXP_GUILD = "Guild";
BINDING_NAME_MYXP_RAID = "Raid";
BINDING_NAME_MYXP_WARNING = "Warning";
BINDING_NAME_MYXP_PRINT = "Print";

local YELLOW  = "|cFFFFFF00"
local PARTY   = "|cFFAAA7FF"
local GUILD   = "|cFF40FB40"
local RAID    = "|cFFFF7D00"
local WHISPER = "|cFFFF7EFF"
local CHANNEL = "|cFFFFBDC0"

local PREFIX_REPORT = "MYXP_REPORT"
local PREFIX_REQUEST = "MYXP_REQUEST"
local PLAYER_XP = {}

local MYXP = CreateFrame('Frame', 'MyXP')
MYXP:SetScript('OnEvent', function(self, event, ...) self[event](...) end)
MYXP:RegisterEvent('CHAT_MSG_ADDON')
MYXP:RegisterEvent('PLAYER_XP_UPDATE')
MYXP:RegisterEvent('PARTY_MEMBERS_CHANGED')
RegisterAddonMessagePrefix(PREFIX_REPORT)
RegisterAddonMessagePrefix(PREFIX_REQUEST)

function MYXP.CHAT_MSG_ADDON(prefix, msg, channel, sender)
	local REALM_SUFFIX = "-" .. gsub(GetRealmName(), "%s", "")
	local PLAYER_NAME = UnitName("player") .. REALM_SUFFIX
	
	if prefix == PREFIX_REPORT then
		PLAYER_XP[sender] = msg
		local name, unit = GameTooltip:GetUnit()
		
		if unit then 
			GameTooltip:SetUnit(unit)
		end
	elseif prefix == PREFIX_REQUEST and PLAYER_NAME == msg then
		MYXP.SendReport()
	end
end

function MYXP.PLAYER_XP_UPDATE()
	MYXP.SendReport()
end

function MYXP.PARTY_MEMBERS_CHANGED()
	MYXP.SendReport()
end

GameTooltip:HookScript("OnTooltipSetUnit", function(tip)
    local name, unit = tip:GetUnit()
    
    if not unit then
    	return
    end
    
    local uname = GetUnitName(unit, true)
    
    if not uname then
    	return
    end
    
    if not UnitInParty(unit) then
    	return
    end
    
    if not string.find(uname, "-") then
    	uname = uname.."-"..gsub(GetRealmName(), "%s", "")
    end
    
    if PLAYER_XP[uname] then
    	GameTooltip:AddLine(PLAYER_XP[uname])
    	GameTooltip:Show()
    else
    	SendAddonMessage(PREFIX_REQUEST, uname, "PARTY")
    end
end)

function MYXP.SendReport()
	local playerLvl = NotNull(UnitLevel("player"), 0)
	local playerXP = NotNull(UnitXP("player"), 0)
	local playerXPMax = NotNull(UnitXPMax("player"), 0)

	local maxLvl = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
	if not maxLvl then
		maxLvl = 20
	end

	if (playerLvl == maxLvl) then
		local overall, equipped = GetAverageItemLevel()
		SendAddonMessage(PREFIX_REPORT, "iLvL: |cFFFFFFFF"..string.format("%.1f", equipped), "PARTY")
	end

	local percent = floor(playerXP / playerXPMax * 100)

	-- XP: 23% [1234/12345] 
	SendAddonMessage(PREFIX_REPORT, "XP: |cFFFFFFFF"..percent.."% ["..playerXP.."/"..playerXPMax.."]", "PARTY")
end


function SlashCmdList.MYXP(msg, editbox)
    if (not msg) or (string.trim(msg) == "") then
        print("Usage: |cffffffff/mxp "..YELLOW.."<|rsay"..YELLOW.."||"..PARTY.."party"..YELLOW.."||"..GUILD.."guild"..YELLOW.."||"..RAID.."instance"..YELLOW.."||"..RAID.."raid"..YELLOW.."||warning"..YELLOW.."|||rprint"..YELLOW..">")
        print("Usage: |cffffffff/mxp "..YELLOW.."<"..WHISPER.."whisper"..YELLOW.."||"..CHANNEL.."channel"..YELLOW.."> <"..WHISPER.."who"..YELLOW.."||"..CHANNEL.."where"..YELLOW..">")
        return
    end

    local _, _, cmdFirst, cmdRemain = string.find(msg, "(%w+)(.*)")

    if (cmdFirst) then cmdFirst = string.trim(cmdFirst) end
    if (cmdRemain) then cmdRemain = string.trim(cmdRemain) end

    cmdFirst = string.lower(cmdFirst)

    if (cmdFirst == "say" or cmdFirst == "party" or cmdFirst == "guild" or cmdFirst == "raid") then
        SendChatMessage(GetXPString(), cmdFirst)
        return
    elseif (cmdFirst == "instance") then
        SendChatMessage(GetXPString(), "instance_chat")
        return
    elseif (cmdFirst == "whisper" or cmdFirst == "channel") then
        SendChatMessage(GetXPString(), cmdFirst, nil, cmdRemain)
        return
    elseif (cmdFirst == "warning") then
        RaidNotice_AddMessage(RaidWarningFrame, GetXPString(), ChatTypeInfo["RAID_WARNING"])
        return
    elseif (cmdFirst == "print") then
        print("|cFF00AFFF"..GetXPString())
        return
    end

    print("<MyXP> |cffb2323fUnknown Command '"..cmdFirst.."'")
end

function GetXPString()
    local playerLvl = NotNull(UnitLevel("player"), 0)
    local playerXP = NotNull(UnitXP("player"), 0)
    local playerXPMAx = NotNull(UnitXPMax("player"), 0)
    
    local maxLvl = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
    if not maxLvl then
        maxLvl = 20
    end

    if (playerLvl == maxLvl) then
        local overall, equipped = GetAverageItemLevel()
        return "<MyXP> LVL: "..playerLvl.." || ".."iLVL: "..string.format("%.1f", equipped)  
    end

    local percent = floor(playerXP / playerXPMAx * 100)
    local toUp = playerXPMAx - playerXP

    -- <MyXP> LVL: 40 | XP: 1002323 [67%] 230431 to lvl up
    return "<MyXP> LVL: "..playerLvl.." || XP: "..playerXP.." ["..percent.."%".."] "..toUp.." to lvl up"
end

function NotNull(string, def)
    if not string then
        return def
    end

    return string
end