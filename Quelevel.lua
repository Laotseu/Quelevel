

local questtags, tags = {}, {Elite = "+", Group = "G", Dungeon = "D", Raid = "R", PvP = "P", Daily = "\226\128\162", Heroic = "H"}


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


-- Add tags to gossip frame
local i
local TRIVIAL, NORMAL = "|cff%02x%02x%02x[%d]|r "..TRIVIAL_QUEST_DISPLAY, "|cff%02x%02x%02x[%d]|r ".. NORMAL_QUEST_DISPLAY
local function helper(isActive, ...)
	local num = select('#', ...)
	if num == 0 then return end

	for j=1,num,3 do
		local title, level, isTrivial = select(j, ...)
		if level ~= -1 then
			local color = GetDifficultyColor(level)
			_G["GossipTitleButton"..i]:SetFormattedText(isActive and isTrivial and TRIVIAL or NORMAL, color.r*255, color.g*255, color.b*255, level, title)
		end
		i = i + 1
	end
	i = i + 1
end

hooksecurefunc("GossipFrameUpdate", function()
	i = 1
	helper(false, GetGossipAvailableQuests())
	helper(true, GetGossipActiveQuests())
end)
