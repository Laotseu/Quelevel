

local questtags, tags = {}, {Elite = "+", Group = "G", Dungeon = "D", Raid = "R", PvP = "P", Daily = "•", Heroic = "H", Repeatable = "\0xE2\0x88\0x9E"}

local IS_MOP = select(4, _G.GetBuildInfo()) >= 50000
local ACTIVE_QUEST_PARAMS = IS_MOP and 5 or 4
local AVAILABLE_QUEST_PARAMS = IS_MOP and 6 or 5

local function GetTaggedTitle(i)
	local name, level, tag, group, header, _, complete, daily = GetQuestLogTitle(i)
	if header or not name then return end

	if not group or group == 0 then group = nil end
	return string.format("[%s%s%s%s] %s", level, tag and tags[tag] or "", daily and tags.Daily or "",group or "", name), tag, daily, complete
end


-- Add tags to the quest log
local function QuestLog_Update()
	for i,butt in pairs(QuestLogScrollFrame.buttons) do
		local qi = butt:GetID()
		local title, tag, daily, complete = GetTaggedTitle(qi)
		if title then butt:SetText("  "..title) end
		if (tag or daily) and not complete then butt.tag:SetText("") end
		QuestLogTitleButton_Resize(butt)
	end
end
hooksecurefunc("QuestLog_Update", QuestLog_Update)
hooksecurefunc(QuestLogScrollFrame, "update", QuestLog_Update)


-- Add tags to the quest watcher
hooksecurefunc("WatchFrame_Update", function()
	local questWatchMaxWidth, watchTextIndex = 0, 1

	for i=1,GetNumQuestWatches() do
		local qi = GetQuestIndexForWatch(i)
		if qi then
			local numObjectives = GetNumQuestLeaderBoards(qi)

			if numObjectives > 0 then
				for bi,butt in pairs(WATCHFRAME_QUESTLINES) do
					if butt.text:GetText() == GetQuestLogTitle(qi) then butt.text:SetText(GetTaggedTitle(qi)) end
				end
			end
		end
	end
end)


-- Add tags to quest links in chat
local function filter(self, event, msg, ...)
	if msg then
		return false, msg:gsub("(|c%x+|Hquest:%d+:(%d+))", "(%2) %1"), ...
	end
end
for _,event in pairs{"SAY", "GUILD", "GUILD_OFFICER", "WHISPER", "WHISPER_INFORM", "PARTY", "RAID", "RAID_LEADER", "BATTLEGROUND", "BATTLEGROUND_LEADER"} do ChatFrame_AddMessageEventFilter("CHAT_MSG_"..event, filter) end


-- Added by Laotseu: my own coloring for gossip frame, I change the trivial and standard colours to be readable
local function MyGetQuestDifficultyColor(level)
	local levelDiff = level - UnitLevel("player");
	local color
	if ( levelDiff >= -2 ) then
		color = GetQuestDifficultyColor(level);
	elseif ( -levelDiff <= GetQuestGreenRange() ) then
--		color = QuestDifficultyColor["standard"];
		color = { r = 0.12, g = 0.37, b = 0.12 }
	else
--		color = QuestDifficultyColor["trivial"];
		color = { r = 0.25, g = 0.25, b = 0.25 }
	end
	return color;
end

-- Add tags to gossip frame
local i
local TRIVIAL, NORMAL = "|cff%02x%02x%02x[%d%s%s]|r "..TRIVIAL_QUEST_DISPLAY, "|cff%02x%02x%02x[%d%s%s]|r ".. NORMAL_QUEST_DISPLAY
local function helper(isActive, ...)
	local num = select('#', ...)
	if num == 0 then return end

	local skip = isActive and ACTIVE_QUEST_PARAMS or AVAILABLE_QUEST_PARAMS

	for j=1,num,skip do
		local title, level, isTrivial, daily, repeatable = select(j, ...)
		if isActive then daily, repeatable = nil end
		if title and level and level ~= -1 then
			local color = MyGetQuestDifficultyColor(level)
			_G["GossipTitleButton"..i]:SetFormattedText(isActive and isTrivial and TRIVIAL or NORMAL, color.r*255, color.g*255, color.b*255, level, repeatable and tags.Repeatable or "", daily and tags.Daily or "", title)
		end
		i = i + 1
	end
	i = i + 1
end

local function GossipUpdate()
	i = 1
	helper(false, GetGossipAvailableQuests()) -- name, level, trivial, daily, repeatable
	helper(true, GetGossipActiveQuests()) -- name, level, trivial, complete
end
hooksecurefunc("GossipFrameUpdate", GossipUpdate)
if GossipFrame:IsShown() then GossipUpdate() end
