-- ============================================================
-- 🌐 GITHUB AUTO-UPDATER + DAHİLİ YEDEK (V18.2 Nova Edition)
-- ============================================================
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Banlanmak/Rblx-Script/refs/heads/main/admin.lua"
local USE_GITHUB_UPDATER = true

local HttpService = game:GetService("HttpService")

local function tryLoadFromGitHub(isManualReload)
	if not USE_GITHUB_UPDATER then return false end
	if _G.__AdminLoadingFromGitHub then return false end
	if not GITHUB_RAW_URL or GITHUB_RAW_URL == "" or GITHUB_RAW_URL:find("KULLANICI_ADIN", 1, true) then
		return false
	end

	-- GitHub CDN önbelleğini aşmak için zaman damgası ekle
	local sep = GITHUB_RAW_URL:find("?", 1, true) and "&" or "?"
	local fetchUrl = GITHUB_RAW_URL .. sep .. "t=" .. tostring(os.time())

	local fetchOk, remoteCode = pcall(function()
		return HttpService:GetAsync(fetchUrl, true)
	end)

	if not fetchOk or type(remoteCode) ~= "string" or #remoteCode < 50 then
		warn("[ADMIN LOADER] GitHub'dan kod çekilemedi: " .. tostring(remoteCode))
		return false
	end

	if remoteCode:match("^%s*<!DOCTYPE") or remoteCode:match("^%s*<html") then
		warn("[ADMIN LOADER] GitHub geçersiz HTML döndürdü (404 / yanlış Raw linki).")
		return false
	end

	local compiler = loadstring
	if type(compiler) ~= "function" then
		warn("[ADMIN LOADER] ServerScriptService.LoadStringEnabled kapalı! Dahili yedek koda geçiliyor.")
		return false
	end

	local compiledFn, compileErr = compiler(remoteCode, "@GitHubAdminSystem")
	if not compiledFn then
		warn("[ADMIN LOADER] GitHub kodunda derleme (syntax) hatası var: " .. tostring(compileErr))
		return false
	end

	local prevCleanup = _G.AdminSystemCleanup
	if isManualReload then
		_G.__AdminForceReload = true
	end

	_G.__AdminLoadingFromGitHub = true
	_G.__AdminPendingSource = "🌐 GitHub"
	local execOk, execErr = pcall(compiledFn)
	_G.__AdminLoadingFromGitHub = false
	_G.__AdminPendingSource = nil

	if not execOk or _G.AdminSystemActive ~= true then
		warn("[ADMIN LOADER] GitHub kodu çalışırken arıza verdi: " .. tostring(execErr))
		_G.__AdminForceReload = false
		if _G.AdminSystemCleanup and _G.AdminSystemCleanup ~= prevCleanup then
			pcall(_G.AdminSystemCleanup)
		end
		return false
	end

	print("[ADMIN LOADER] ✅ GitHub sürümü başarıyla yüklendi!")
	return true
end

-- Sunucu açılışında önce GitHub'ı dene; başarısız olursa aşağıdaki dahili V18.2 kodu çalışır
if tryLoadFromGitHub(false) then
	return
end

-- ============================================================
-- ⚡ DAHİLİ YEDEK SİSTEM: ULTRA GELİŞMİŞ ADMIN SİSTEMİ V18.2 (Nova Edition)
-- ============================================================
local SCRIPT_VERSION = 30
local LOAD_SOURCE = _G.__AdminPendingSource or "💾 Dahili Yedek"

-- ============================================================
-- 🔒 VERSION GUARD: Sadece EN YÜKSEK sürüm çalışır
-- ============================================================
if _G.AdminSystemVersion then
	if _G.AdminSystemVersion > SCRIPT_VERSION and not _G.__AdminForceReload then
		warn("[ADMIN] Daha yüksek sürüm çalışıyor (v" .. _G.AdminSystemVersion .. "). Bu v" .. SCRIPT_VERSION .. " yok sayıldı.")
		return
	elseif _G.AdminSystemVersion == SCRIPT_VERSION and _G.AdminSystemActive and not _G.__AdminForceReload then
		warn("[ADMIN] Aynı sürüm zaten aktif (v" .. SCRIPT_VERSION .. "). Duplicate yok sayıldı.")
		return
	elseif _G.AdminSystemVersion <= SCRIPT_VERSION or _G.__AdminForceReload then
		warn("[ADMIN] Eski/mevcut sürüm (v" .. _G.AdminSystemVersion .. ") kapatılıyor, v" .. SCRIPT_VERSION .. " başlatılıyor...")
		if _G.AdminSystemCleanup then pcall(_G.AdminSystemCleanup) end
	end
end

_G.__AdminForceReload = false
_G.AdminSystemVersion = SCRIPT_VERSION
_G.AdminSystemActive = true

local ActiveConnections = {}
local function trackConnection(conn)
	table.insert(ActiveConnections, conn)
	return conn
end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local StatsService = game:GetService("Stats")

local FlyStates = {}
local LoopStates = {}
local GeminiStates = {}

_G.AdminSystemCleanup = function()
	for _, conn in ipairs(ActiveConnections) do
		pcall(function() conn:Disconnect() end)
	end
	ActiveConnections = {}

	for _, f in pairs(FlyStates) do
		if f.conn then pcall(function() f.conn:Disconnect() end) end
	end
	FlyStates = {}

	for _, l in pairs(LoopStates) do
		if l.conn then pcall(function() l.conn:Disconnect() end) end
	end
	LoopStates = {}

	for _, p in ipairs(Players:GetPlayers()) do
		local pg = p:FindFirstChild("PlayerGui")
		if pg then
			for _, name in ipairs({
				"AdminUI", "AdminNotification", "AdminBlindUI",
				"GeminiAdminUI", "OfflineAuthsUI", "BanListUI",
				"AdminMenu", "AdminAnnouncementUI", "AdminFlyHUD"
			}) do
				local g = pg:FindFirstChild(name)
				if g then g:Destroy() end
			end
		end
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local bv = p.Character.HumanoidRootPart:FindFirstChild("NovaFlyBV")
			if bv then bv:Destroy() end
		end
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:sub(1, 10) == "AdminJail_" then
			pcall(function() obj:Destroy() end)
		end
	end

	_G.AdminSystemActive = false
end

--------------------------------------------------
-- ⚙️ AYARLAR & NOVA TEMA
--------------------------------------------------
local WEBHOOK_PROXY = "https://discord.yeesen.dev/api/webhooks/1462420401455108249/dq07O3ou2D9alDCD-g7n1nnMtk_OicB7aNkoa4oeTIzjT7_gcPvcZTkoWwI8DFrHRTdp"
local HARDCODED_AUTHS = {
	2507778459, 1745742223, 1610781899, 6190404805, 9209160512, 9175877984,
	7042237640, 7095830112, 9175880109, 9175938624, 9175939614, 9175347392,
	9176118791, 9176330808, 9176025834, 4886943325, 3265448865
}

local PLACE_ID = game.PlaceId
local GAME_LINK = "https://www.roblox.com/games/" .. tostring(PLACE_ID)
local ICON_URL = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. tostring(PLACE_ID) .. "&width=256&height=256&format=png"
local MAX_PLAYERS = Players.MaxPlayers
local BUILD_VERSION = "v18.2.0-NovaEdition"
local ServerLocked = false

local THEME = {
	Bg0 = Color3.fromRGB(10, 11, 16),
	Bg1 = Color3.fromRGB(16, 18, 26),
	Bg2 = Color3.fromRGB(23, 26, 38),
	Bg3 = Color3.fromRGB(32, 37, 52),
	Bg4 = Color3.fromRGB(44, 50, 70),
	Border = Color3.fromRGB(48, 56, 80),
	TextPrimary = Color3.fromRGB(244, 247, 255),
	TextSecondary = Color3.fromRGB(172, 182, 206),
	TextMuted = Color3.fromRGB(115, 126, 152),
	Accent = Color3.fromRGB(56, 189, 248),
	AccentDark = Color3.fromRGB(14, 116, 164),
	Success = Color3.fromRGB(34, 197, 134),
	Warning = Color3.fromRGB(245, 168, 42),
	Danger = Color3.fromRGB(239, 68, 82),
	Gold = Color3.fromRGB(250, 204, 52),
	Purple = Color3.fromRGB(147, 102, 255),
}

local cachedGameName = game.Name ~= "" and game.Name or "Roblox Oyunu"
local gameNameLoaded = false

local function ensureGameNameLoaded()
	if gameNameLoaded then return cachedGameName end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(PLACE_ID)
	end)
	if ok and info and info.Name and info.Name ~= "" then
		cachedGameName = info.Name
	end
	gameNameLoaded = true
	return cachedGameName
end

--------------------------------------------------
-- 📊 SUNUCU İSTATİSTİKLERİ, FPS & CANLI LOG AKIŞI
--------------------------------------------------
local ServerStats = {
	totalJoins = 0,
	peakPlayers = #Players:GetPlayers(),
	sessionKicks = 0,
	sessionBans = 0,
	serverFPS = 60,
	lastLockedBy = nil,
	lastLockedAt = nil,
}

local ActivityLogs = {}
local MAX_ACTIVITY_LOGS = 25

local function addActivityLog(icon, text, color)
	table.insert(ActivityLogs, 1, {
		time = os.date("%H:%M:%S"),
		icon = icon or "•",
		text = text,
		color = color or THEME.TextSecondary
	})
	if #ActivityLogs > MAX_ACTIVITY_LOGS then
		table.remove(ActivityLogs)
	end
end

addActivityLog("⚡", "Sistem başlatıldı (" .. BUILD_VERSION .. " • " .. LOAD_SOURCE .. ")", THEME.Accent)

-- Sunucu FPS Ölçer
local fpsFrameCount = 0
local fpsElapsed = 0
trackConnection(RunService.Heartbeat:Connect(function(dt)
	fpsFrameCount += 1
	fpsElapsed += dt
	if fpsElapsed >= 1 then
		ServerStats.serverFPS = math.clamp(math.floor((fpsFrameCount / fpsElapsed) + 0.5), 1, 60)
		fpsFrameCount = 0
		fpsElapsed = 0
	end
end))

--------------------------------------------------
-- 📛 KULLANICI ADI ÖNBELLEĞİ (Online + Offline)
--------------------------------------------------
local UsernameCache = {}

local function getUsernameAsync(userId, callback)
	local numId = tonumber(userId)
	if not numId then
		if callback then callback("Bilinmiyor") end
		return "Bilinmiyor"
	end

	local onlinePlr = Players:GetPlayerByUserId(numId)
	if onlinePlr then
		UsernameCache[numId] = onlinePlr.Name
		if callback then callback(onlinePlr.Name) end
		return onlinePlr.Name
	end

	if UsernameCache[numId] then
		if callback then callback(UsernameCache[numId]) end
		return UsernameCache[numId]
	end

	task.spawn(function()
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(numId)
		end)
		local resolved = (ok and name and name ~= "") and name or ("Kullanıcı_" .. tostring(numId))
		UsernameCache[numId] = resolved
		if callback then callback(resolved) end
	end)

	return "Yükleniyor..."
end

task.spawn(function()
	for _, id in ipairs(HARDCODED_AUTHS) do
		getUsernameAsync(id)
		task.wait(0.12)
	end
end)

--------------------------------------------------
-- 🖱️ PENCERE SÜRÜKLEME (Sadece Frame'ler için)
--------------------------------------------------
local function makeWindowDraggable(frame)
	frame.Active = true
	local ok = pcall(function()
		local detector = Instance.new("UIDragDetector")
		detector.Name = "NovaDragDetector"
		detector.DragStyle = Enum.UIDragDetectorDragStyle.TranslatePlane
		detector.ResponseStyle = Enum.UIDragDetectorResponseStyle.Offset
		detector.Parent = frame
	end)
	if not ok then
		pcall(function() frame.Draggable = true end)
	end
end

--------------------------------------------------
-- 👑 YETKİ SİSTEMİ
--------------------------------------------------
local DynamicAuths = {}
local AdminDataStore = (function()
	local ok, ds = pcall(function() return DataStoreService:GetDataStore("AdminSystem_AUTHS_v5") end)
	return ok and ds or nil
end)()

task.spawn(function()
	if not AdminDataStore then return end
	local ok, data = pcall(function() return AdminDataStore:GetAsync("AuthorizedUsers") end)
	if ok and type(data) == "table" then
		DynamicAuths = data
		for _, item in ipairs(DynamicAuths) do
			if item.id then getUsernameAsync(item.id) end
		end
	end
end)

local function saveDynamicAuths()
	if AdminDataStore then
		pcall(function() AdminDataStore:SetAsync("AuthorizedUsers", DynamicAuths) end)
	end
end

local function isHardcodedAuth(userId)
	for _, id in ipairs(HARDCODED_AUTHS) do
		if userId == id then return true end
	end
	return false
end

local function getPlayerRole(userId)
	if isHardcodedAuth(userId) then return "Kurucu" end
	for _, data in ipairs(DynamicAuths) do
		if data.id == userId then return data.role end
	end
	return nil
end

local function isAuthorized(player)
	return getPlayerRole(player.UserId) ~= nil
end

local function setPlayerRole(targetUserId, newRole)
	for i = #DynamicAuths, 1, -1 do
		if DynamicAuths[i].id == targetUserId then
			table.remove(DynamicAuths, i)
		end
	end
	if newRole and newRole ~= "None" then
		table.insert(DynamicAuths, { id = targetUserId, role = newRole })
	end
	saveDynamicAuths()
end

--------------------------------------------------
-- 🚫 GELİŞMİŞ BAN SİSTEMİ (Kim, Ne Zaman, Kim Banladı)
--------------------------------------------------
local BanDataStore = (function()
	local ok, ds = pcall(function() return DataStoreService:GetDataStore("AdminSystem_BANS_v3") end)
	return ok and ds or nil
end)()
local GlobalBans = {}
local ServerBans = {}

task.spawn(function()
	if not BanDataStore then return end
	local ok, data = pcall(function() return BanDataStore:GetAsync("GlobalBannedUsers") end)
	if ok and type(data) == "table" then
		GlobalBans = data
		for uidStr in pairs(GlobalBans) do
			getUsernameAsync(tonumber(uidStr))
		end
	end
end)

local function saveGlobalBans()
	if BanDataStore then
		pcall(function() BanDataStore:SetAsync("GlobalBannedUsers", GlobalBans) end)
	end
end

local function formatRemainingBanTime(expireTimestamp)
	if not expireTimestamp or expireTimestamp == 0 then
		return "Kalıcı"
	end
	local rem = expireTimestamp - os.time()
	if rem <= 0 then
		return "Süresi Doldu"
	end
	local days = math.floor(rem / 86400)
	local hours = math.floor((rem % 86400) / 3600)
	local mins = math.floor((rem % 3600) / 60)
	if days > 0 then
		return string.format("%d gün %d sa", days, hours)
	elseif hours > 0 then
		return string.format("%d sa %d dk", hours, mins)
	else
		return string.format("%d dk", math.max(1, mins))
	end
end

local function checkBanStatus(userId)
	local srvBan = ServerBans[userId]
	if srvBan then
		if type(srvBan) == "table" then
			return true, srvBan.reason or "Bu sunucudan yasaklandınız."
		end
		return true, tostring(srvBan)
	end
	local banData = GlobalBans[tostring(userId)]
	if banData then
		if banData.expire == 0 or banData.expire > os.time() then
			return true, banData.reason
		else
			GlobalBans[tostring(userId)] = nil
			saveGlobalBans()
		end
	end
	return false, nil
end

local function banUserServer(userId, reason, bannedByPlayer, targetName)
	local adminName = bannedByPlayer and bannedByPlayer.Name or "Sistem"
	local tName = targetName or UsernameCache[userId] or ("ID: " .. tostring(userId))
	ServerBans[userId] = {
		reason = reason or "Kurallara Uymamak",
		date = os.date("%d/%m/%Y %H:%M"),
		timestamp = os.time(),
		bannedBy = adminName,
		bannedById = bannedByPlayer and bannedByPlayer.UserId or 0,
		targetName = tName
	}
	ServerStats.sessionBans += 1
	addActivityLog("⛔", adminName .. " → " .. tName .. " (Sunucu Ban: " .. (reason or "?") .. ")", THEME.Danger)
end

local function banUserGlobal(userId, reason, durationSeconds, bannedByPlayer, targetName)
	local expireTime = (durationSeconds == 0) and 0 or (os.time() + durationSeconds)
	local adminName = bannedByPlayer and bannedByPlayer.Name or "Sistem"
	local tName = targetName or UsernameCache[userId] or nil
	GlobalBans[tostring(userId)] = {
		reason = reason or "Kurallara Uymamak",
		expire = expireTime,
		date = os.date("%d/%m/%Y %H:%M"),
		timestamp = os.time(),
		bannedBy = adminName,
		bannedById = bannedByPlayer and bannedByPlayer.UserId or 0,
		targetName = tName
	}
	saveGlobalBans()
	ServerStats.sessionBans += 1
	local durText = (durationSeconds == 0) and "Kalıcı" or formatRemainingBanTime(expireTime)
	addActivityLog("💥", adminName .. " → " .. (tName or tostring(userId)) .. " (" .. durText .. " Ban)", THEME.Danger)
end

--------------------------------------------------
-- 📦 REQUIRE ÇALIŞTIRICI
--------------------------------------------------
local function runRequire(player, msg)
	if not isAuthorized(player) then return end
	local id, method, arg = msg:match('require%((%d+)%)%.([%w_]+)%("?(.-)"?%)')
	if id then
		id = tonumber(id)
		local ok, mod = pcall(function() return require(id) end)
		if ok then
			pcall(function()
				if typeof(mod) == "function" then
					mod(arg)
				elseif typeof(mod) == "table" and mod[method] then
					mod[method](arg)
				end
			end)
		end
		return
	end
	id, arg = msg:match('require%((%d+)%)%("?(.-)"?%)')
	if id then
		id = tonumber(id)
		local ok, mod = pcall(function() return require(id) end)
		if ok then
			pcall(function()
				if typeof(mod) == "function" then
					mod(arg)
				elseif typeof(mod) == "table" then
					for _, v in pairs(mod) do
						if typeof(v) == "function" then v(arg) break end
					end
				end
			end)
		end
	end
end

--------------------------------------------------
-- 📡 DISCORD LOG SİSTEMİ (Sade & Temiz)
--------------------------------------------------
local startTime = os.time()
local statusMessageId = nil

local function formatUptime()
	local diff = os.time() - startTime
	return string.format("%02d:%02d:%02d", math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

local function getAdminList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if isAuthorized(p) then table.insert(list, p.Name) end
	end
	return (#list > 0 and table.concat(list, ", ")) or "Yok"
end

local function updateServerStatusLog(playerCount)
	task.spawn(function()
		ensureGameNameLoaded()
		local count = math.max(0, playerCount or #Players:GetPlayers())
		local embedData = {
			username = "Server Monitor",
			avatar_url = ICON_URL,
			embeds = {{
				title = "🎮 " .. cachedGameName,
				url = GAME_LINK,
				color = (count == 0 and 0x64748B) or (count >= MAX_PLAYERS and 0xEF4452) or 0x38BDF8,
				thumbnail = { url = ICON_URL },
				fields = {
					{ name = "👥 Oyuncular", value = tostring(count) .. " / " .. tostring(MAX_PLAYERS), inline = true },
					{ name = "🆔 Oyun ID", value = "`" .. tostring(PLACE_ID) .. "`", inline = true },
					{ name = "⏱️ Süre", value = formatUptime(), inline = true },
					{ name = "👑 Aktif Yetkililer", value = getAdminList(), inline = false }
				},
				footer = { text = "Nova Admin V18.2 • Sunucu Durumu" },
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}
		local json = HttpService:JSONEncode(embedData)
		pcall(function()
			if statusMessageId then
				HttpService:RequestAsync({
					Url = WEBHOOK_PROXY .. "/messages/" .. statusMessageId,
					Method = "PATCH",
					Headers = { ["Content-Type"] = "application/json" },
					Body = json
				})
			else
				local response = HttpService:PostAsync(WEBHOOK_PROXY .. "?wait=true", json, Enum.HttpContentType.ApplicationJson)
				local decoded = HttpService:JSONDecode(response)
				if decoded and decoded.id then
					statusMessageId = decoded.id
				end
			end
		end)
	end)
end

local function sendAdminJoinLog(adminPlayer)
	task.spawn(function()
		ensureGameNameLoaded()
		local count = #Players:GetPlayers()
		local role = getPlayerRole(adminPlayer.UserId) or "Yetkili"
		local embedData = {
			username = "Admin Log",
			avatar_url = ICON_URL,
			embeds = {{
				title = "🎮 " .. cachedGameName,
				url = GAME_LINK,
				description = "👑 **" .. adminPlayer.Name .. "** (`" .. tostring(adminPlayer.UserId) .. "`) oyuna katıldı • `[" .. role .. "]`",
				color = 0xFACC34,
				thumbnail = { url = ICON_URL },
				fields = {
					{ name = "👥 Oyuncular", value = tostring(count) .. " / " .. tostring(MAX_PLAYERS), inline = true },
					{ name = "🆔 Oyun ID", value = "`" .. tostring(PLACE_ID) .. "`", inline = true }
				},
				footer = { text = "Nova Admin V18.2" },
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}
		pcall(function()
			HttpService:PostAsync(WEBHOOK_PROXY, HttpService:JSONEncode(embedData), Enum.HttpContentType.ApplicationJson)
		end)
	end)
end

--------------------------------------------------
-- 🔔 DURUM, BİLDİRİM & 3 SANİYELİK SİYAH DUYURU
--------------------------------------------------
local AdminStates = {}
local function getAdminState(player)
	if not AdminStates[player.UserId] then
		AdminStates[player.UserId] = {
			selectedReason = "Kurallara Uymamak",
			selectedTab = "📊 Durum",
			menuOpen = false,
			minimized = false,
			selectedPlayerName = nil,
			selectedPlayerId = nil,
			selectedScripts = {},
			playerFilter = "Tümü",
			awaitingAnnouncement = false
		}
	end
	return AdminStates[player.UserId]
end

local function showNotification(player, text, color)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local oldNotif = playerGui:FindFirstChild("AdminNotification")
	if oldNotif then oldNotif:Destroy() end

	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "AdminNotification"
	notifGui.ResetOnSpawn = false
	notifGui.DisplayOrder = 10050
	notifGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 44)
	frame.Position = UDim2.new(0.5, -200, 0, -64)
	frame.BackgroundColor3 = THEME.Bg1
	frame.Parent = notifGui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = color or THEME.Accent
	stroke.Thickness = 1.5

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, -14)
	accentBar.Position = UDim2.new(0, 8, 0, 7)
	accentBar.BackgroundColor3 = color or THEME.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = frame
	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -26, 1, 0)
	lbl.Position = UDim2.new(0, 18, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = THEME.TextPrimary
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = frame

	frame:TweenPosition(UDim2.new(0.5, -200, 0, 18), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
	task.delay(3, function()
		if frame and frame.Parent then
			frame:TweenPosition(UDim2.new(0.5, -200, 0, -70), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.28, true)
			task.wait(0.3)
			if notifGui and notifGui.Parent then notifGui:Destroy() end
		end
	end)
end

local function showBlackoutAnnouncement(messageText, senderName)
	if not messageText or messageText == "" then return end
	addActivityLog("📢", (senderName or "Admin") .. " duyuru yaptı: \"" .. messageText:sub(1, 36) .. "\"", THEME.Gold)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local pg = p:FindFirstChild("PlayerGui")
			if not pg then return end
			local old = pg:FindFirstChild("AdminAnnouncementUI")
			if old then old:Destroy() end

			local gui = Instance.new("ScreenGui")
			gui.Name = "AdminAnnouncementUI"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = true
			gui.DisplayOrder = 100000
			gui.Parent = pg

			local blackBg = Instance.new("Frame")
			blackBg.Size = UDim2.new(1, 0, 1, 0)
			blackBg.Position = UDim2.new(0, 0, 0, 0)
			blackBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			blackBg.BackgroundTransparency = 1
			blackBg.BorderSizePixel = 0
			blackBg.Parent = gui

			local msgLbl = Instance.new("TextLabel")
			msgLbl.Size = UDim2.new(0.84, 0, 0.55, 0)
			msgLbl.Position = UDim2.new(0.08, 0, 0.225, 0)
			msgLbl.BackgroundTransparency = 1
			msgLbl.Text = messageText
			msgLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			msgLbl.Font = Enum.Font.GothamBlack
			msgLbl.TextSize = 36
			msgLbl.TextWrapped = true
			msgLbl.TextTransparency = 1
			msgLbl.Parent = blackBg

			TweenService:Create(blackBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(msgLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

			task.wait(3)

			if gui and gui.Parent then
				TweenService:Create(blackBg, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(msgLbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
				task.wait(0.38)
				if gui and gui.Parent then gui:Destroy() end
			end
		end)
	end
end

local function createButton(parent, text, color, pos, size, callback)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = THEME.TextPrimary
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.TextWrapped = true
	b.AutoButtonColor = false
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

	local baseColor = color
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.new(
				math.min(baseColor.R + 0.08, 1),
				math.min(baseColor.G + 0.08, 1),
				math.min(baseColor.B + 0.08, 1)
			)
		}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = baseColor }):Play()
	end)
	if callback then
		b.MouseButton1Click:Connect(callback)
	end
	return b
end

--------------------------------------------------
-- 🕊️ GERÇEK ÇALIŞAN FLY MOTORU (WASD + Space + Mini HUD)
--------------------------------------------------
local function destroyFlyHUD(target)
	local pg = target:FindFirstChild("PlayerGui")
	if pg then
		local hud = pg:FindFirstChild("AdminFlyHUD")
		if hud then hud:Destroy() end
	end
end

local function createFlyHUD(target, fState, stopCallback)
	destroyFlyHUD(target)
	local pg = target:FindFirstChild("PlayerGui")
	if not pg then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminFlyHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10020
	gui.Parent = pg

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 390, 0, 44)
	bar.Position = UDim2.new(0.5, -195, 1, -72)
	bar.BackgroundColor3 = THEME.Bg0
	bar.Parent = gui
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke", bar)
	st.Color = THEME.Accent
	st.Thickness = 1.5

	local upBtn, holdBtn, downBtn, spdBtn

	local function refreshColors()
		if upBtn then upBtn.BackgroundColor3 = (fState.verticalMode == 1) and THEME.Success or THEME.Bg2 end
		if holdBtn then holdBtn.BackgroundColor3 = (fState.verticalMode == 0) and THEME.AccentDark or THEME.Bg2 end
		if downBtn then downBtn.BackgroundColor3 = (fState.verticalMode == -1) and THEME.Warning or THEME.Bg2 end
		if spdBtn then spdBtn.Text = "⚡ " .. tostring(fState.speed) end
	end

	upBtn = createButton(bar, "▲ Yüksel", THEME.Bg2, UDim2.new(0, 6, 0, 6), UDim2.new(0, 82, 0, 32), function()
		fState.verticalMode = (fState.verticalMode == 1) and 0 or 1
		refreshColors()
	end)
	holdBtn = createButton(bar, "■ Sabit", THEME.AccentDark, UDim2.new(0, 94, 0, 6), UDim2.new(0, 72, 0, 32), function()
		fState.verticalMode = 0
		refreshColors()
	end)
	downBtn = createButton(bar, "▼ Alçal", THEME.Bg2, UDim2.new(0, 172, 0, 6), UDim2.new(0, 82, 0, 32), function()
		fState.verticalMode = (fState.verticalMode == -1) and 0 or -1
		refreshColors()
	end)
	spdBtn = createButton(bar, "⚡ " .. tostring(fState.speed), THEME.Bg3, UDim2.new(0, 260, 0, 6), UDim2.new(0, 66, 0, 32), function()
		local speeds = { 45, 75, 115, 170 }
		local nextSpd = speeds[1]
		for i, s in ipairs(speeds) do
			if fState.speed < s then nextSpd = s break end
			if i == #speeds then nextSpd = speeds[1] end
		end
		fState.speed = nextSpd
		refreshColors()
	end)
	createButton(bar, "✕", THEME.Danger, UDim2.new(1, -54, 0, 6), UDim2.new(0, 48, 0, 32), function()
		stopCallback()
	end)

	refreshColors()
end

local function setFly(target, state, speed)
	if not target or not target.Parent then return end
	local uid = target.UserId

	if state then
		if FlyStates[uid] and FlyStates[uid].conn then
			FlyStates[uid].conn:Disconnect()
		end

		local fState = {
			active = true,
			speed = tonumber(speed) or 75,
			verticalMode = 0,
			conn = nil
		}
		FlyStates[uid] = fState

		createFlyHUD(target, fState, function()
			setFly(target, false)
		end)

		fState.conn = RunService.Heartbeat:Connect(function()
			if not target.Parent or not fState.active then
				setFly(target, false)
				return
			end
			local char = target.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum or hum.Health <= 0 then return end

			if hum.Sit then hum.Sit = false end

			local bv = hrp:FindFirstChild("NovaFlyBV")
			if not bv then
				bv = Instance.new("BodyVelocity")
				bv.Name = "NovaFlyBV"
				bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
				bv.P = 12500
				bv.Velocity = Vector3.zero
				bv.Parent = hrp
			end

			local moveDir = hum.MoveDirection
			local horiz = Vector3.new(moveDir.X, 0, moveDir.Z)
			if horiz.Magnitude > 0.05 then
				horiz = horiz.Unit * fState.speed
			else
				horiz = Vector3.zero
			end

			local vy = 0
			if hum.Jump or fState.verticalMode == 1 then
				vy = fState.speed * 0.85
			elseif fState.verticalMode == -1 then
				vy = -fState.speed * 0.85
			end

			bv.Velocity = Vector3.new(horiz.X, vy, horiz.Z)
		end)
	else
		local fState = FlyStates[uid]
		if fState then
			fState.active = false
			if fState.conn then pcall(function() fState.conn:Disconnect() end) end
			FlyStates[uid] = nil
		end
		destroyFlyHUD(target)
		if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local bv = target.Character.HumanoidRootPart:FindFirstChild("NovaFlyBV")
			if bv then bv:Destroy() end
		end
	end
end

local function isFlying(target)
	return FlyStates[target.UserId] ~= nil and FlyStates[target.UserId].active == true
end

--------------------------------------------------
-- ✨ GEMINI STATE, KAFES (JAIL) & KÖRLÜK
--------------------------------------------------
local GeminiTab = {}
local function getGeminiState(player)
	if not GeminiStates[player.UserId] then
		GeminiStates[player.UserId] = {
			noclip = false, noclipConn = nil,
			invisible = false, fullbright = false,
			antiAfk = false, antiAfkConn = nil,
			godMode = false
		}
	end
	return GeminiStates[player.UserId]
end

local function setNoclip(player, state)
	local st = getGeminiState(player)
	if state then
		if st.noclipConn then st.noclipConn:Disconnect() end
		st.noclip = true
		st.noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if not char then return end
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = false end
			end
		end)
	else
		if st.noclipConn then st.noclipConn:Disconnect() st.noclipConn = nil end
		st.noclip = false
		local char = player.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = true end
			end
		end
	end
end

local function setAntiAfk(player, state)
	local st = getGeminiState(player)
	if state then
		st.antiAfk = true
		if st.antiAfkConn then st.antiAfkConn:Disconnect() end
		st.antiAfkConn = player.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	else
		st.antiAfk = false
		if st.antiAfkConn then st.antiAfkConn:Disconnect() st.antiAfkConn = nil end
	end
end

local function setInvisible(player, state)
	local st = getGeminiState(player)
	st.invisible = state
	local char = player.Character
	if not char then return end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then v.Transparency = state and 1 or 0 end
		if v:IsA("Decal") then v.Transparency = state and 1 or 0 end
	end
	if char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Transparency = 1 end
end

local function setFullbright(player, state)
	local st = getGeminiState(player)
	st.fullbright = state
	Lighting.Brightness = state and 2 or 1
	if state then Lighting.ClockTime = 14 end
	Lighting.FogEnd = state and 100000 or 1000
	Lighting.GlobalShadows = not state
end

local function jailPlayer(target)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	local old = workspace:FindFirstChild("AdminJail_" .. target.UserId)
	if old then old:Destroy() end

	local hrp = target.Character.HumanoidRootPart
	local center = hrp.Position
	local model = Instance.new("Model")
	model.Name = "AdminJail_" .. target.UserId
	model.Parent = workspace

	local parts = {
		{ size = Vector3.new(8, 0.5, 8), offset = Vector3.new(0, -3.5, 0) },
		{ size = Vector3.new(8, 0.5, 8), offset = Vector3.new(0, 5.5, 0) },
		{ size = Vector3.new(8, 9, 0.5), offset = Vector3.new(0, 1, 4) },
		{ size = Vector3.new(8, 9, 0.5), offset = Vector3.new(0, 1, -4) },
		{ size = Vector3.new(0.5, 9, 8), offset = Vector3.new(4, 1, 0) },
		{ size = Vector3.new(0.5, 9, 8), offset = Vector3.new(-4, 1, 0) },
	}
	for _, spec in ipairs(parts) do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = true
		p.Material = Enum.Material.ForceField
		p.Color = THEME.Accent
		p.Transparency = 0.45
		p.Size = spec.size
		p.CFrame = CFrame.new(center + spec.offset)
		p.Parent = model
	end
	hrp.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
end

local function unjailPlayer(target)
	if not target then return end
	local jail = workspace:FindFirstChild("AdminJail_" .. target.UserId)
	if jail then jail:Destroy() end
end

local function setBlind(target, state)
	if not target then return end
	local pg = target:FindFirstChild("PlayerGui")
	if not pg then return end
	local existing = pg:FindFirstChild("AdminBlindUI")
	if state then
		if not existing then
			local bGui = Instance.new("ScreenGui")
			bGui.Name = "AdminBlindUI"
			bGui.ResetOnSpawn = false
			bGui.IgnoreGuiInset = true
			bGui.DisplayOrder = 99999
			local bFrame = Instance.new("Frame")
			bFrame.Size = UDim2.new(1, 0, 1, 0)
			bFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			bFrame.BorderSizePixel = 0
			bFrame.Parent = bGui
			bGui.Parent = pg
		end
	else
		if existing then existing:Destroy() end
	end
end

--------------------------------------------------
-- 🔍 GELİŞMİŞ HEDEF BULUCU (İlk 3 harf / Kısmi / me / all / others)
--------------------------------------------------
local function isAllKeyword(str)
	local l = string.lower(str or "")
	return l == "all" or l == "herkes" or l == "herkez"
end

local function isOthersKeyword(str)
	local l = string.lower(str or "")
	return l == "others" or l == "other" or l == "digerleri" or l == "diğerleri" or l == "diger" or l == "diğer"
end

local function isMeKeyword(str)
	local l = string.lower(str or "")
	return l == "me" or l == "ben"
end

local function findPlayerByPartial(name)
	if not name or name == "" then return nil end
	local query = string.lower(name)
	local qLen = #query

	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == query or string.lower(p.DisplayName) == query then
			return p
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		local pName = string.lower(p.Name)
		local pDisp = string.lower(p.DisplayName)
		if pName:sub(1, qLen) == query or pDisp:sub(1, qLen) == query then
			return p
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name):find(query, 1, true) or string.lower(p.DisplayName):find(query, 1, true) then
			return p
		end
	end

	local numId = tonumber(name)
	if numId then
		local byId = Players:GetPlayerByUserId(numId)
		if byId then return byId end
	end

	return nil
end

local function splitArgs(str)
	local args = {}
	for word in string.gmatch(str or "", "%S+") do table.insert(args, word) end
	return args
end

local function canAffect(sender, target, myRole)
	local tRole = getPlayerRole(target.UserId)
	if tRole == "Kurucu" and myRole ~= "Kurucu" and target.UserId ~= sender.UserId then
		return false
	end
	return true
end

local function canAffectUserId(sender, targetUserId, myRole)
	local tRole = getPlayerRole(targetUserId)
	if tRole == "Kurucu" and myRole ~= "Kurucu" and targetUserId ~= sender.UserId then
		return false
	end
	return true
end

local function resolveTargets(player, nameArg, myRole, silent)
	if not nameArg or nameArg == "" then
		if not silent then
			showNotification(player, "Hedef belirtilmedi! Örn: /fly all, /fly others, /kill ahm", THEME.Warning)
		end
		return {}
	end

	local list = {}

	if isMeKeyword(nameArg) then
		return { player }
	elseif isAllKeyword(nameArg) then
		for _, p in ipairs(Players:GetPlayers()) do
			if canAffect(player, p, myRole) then table.insert(list, p) end
		end
		if #list == 0 and not silent then
			showNotification(player, "İşlem yapılabilecek oyuncu yok!", THEME.Warning)
		end
		return list
	elseif isOthersKeyword(nameArg) then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and canAffect(player, p, myRole) then table.insert(list, p) end
		end
		if #list == 0 and not silent then
			showNotification(player, "Senden başka işlem yapılabilecek oyuncu yok!", THEME.Warning)
		end
		return list
	end

	local t = findPlayerByPartial(nameArg)
	if not t then
		if not silent then
			showNotification(player, "Oyuncu bulunamadı: " .. nameArg, THEME.Danger)
		end
		return {}
	end
	if not canAffect(player, t, myRole) then
		if not silent then
			showNotification(player, "Kurucuya işlem yapamazsın!", THEME.Danger)
		end
		return {}
	end
	return { t }
end

local function getDynamicLoopTargets(player, nameArg, myRole, fixedTargets)
	if isAllKeyword(nameArg) then
		local res = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if canAffect(player, p, myRole) then table.insert(res, p) end
		end
		return res
	elseif isOthersKeyword(nameArg) then
		local res = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and canAffect(player, p, myRole) then table.insert(res, p) end
		end
		return res
	end
	return fixedTargets
end

--------------------------------------------------
-- ⚔️ KOMUT MOTORU
--------------------------------------------------
local function stopLoop(player)
	local key = player.UserId
	if LoopStates[key] and LoopStates[key].conn then
		LoopStates[key].conn:Disconnect()
		LoopStates[key] = nil
	end
end

local function handleAdonisCommand(player, cmd, args, rawRest)
	local myRole = getPlayerRole(player.UserId)
	if not myRole then return false end
	cmd = string.lower(cmd)

	-- CANLI GITHUB GÜNCELLEME
	if cmd == "guncelle" or cmd == "güncelle" or cmd == "update" or cmd == "reload" then
		showNotification(player, "🔄 GitHub'dan güncelleme kontrol ediliyor...", THEME.Accent)
		task.spawn(function()
			local ok = tryLoadFromGitHub(true)
			if ok then
				showNotification(player, "✅ GitHub'dan başarıyla güncellendi!", THEME.Success)
			else
				showNotification(player, "❌ GitHub çekilemedi veya kod hatalı! Mevcut sürüm aktif.", THEME.Danger)
			end
		end)
		return true

	-- SUNUCU DURUMU SEKMESİNİ AÇ
	elseif cmd == "durum" or cmd == "status" or cmd == "serverstatus" then
		local state = getAdminState(player)
		state.selectedTab = "📊 Durum"
		state.menuOpen = true
		if _G.__adminOpenMenu then _G.__adminOpenMenu(player) end
		return true

	-- AKILLI BAN (Online kısmi + Offline tam isim/ID + all/others)
	elseif cmd == "ban" then
		local targetArg = args[1]
		if not targetArg or targetArg == "" then
			showNotification(player, "Kullanım: /ban <hedef/kullanıcıadı> [sebep]", THEME.Warning)
			return true
		end
		local reason = rawRest:match("^%S+%s+(.+)$") or getAdminState(player).selectedReason

		if isMeKeyword(targetArg) or isAllKeyword(targetArg) or isOthersKeyword(targetArg) then
			local targets = resolveTargets(player, targetArg, myRole)
			local bannedCount = 0
			for _, t in ipairs(targets) do
				if not (isAllKeyword(targetArg) and t == player) then
					banUserGlobal(t.UserId, reason, 0, player, t.Name)
					t:Kick(reason)
					bannedCount += 1
				end
			end
			if bannedCount > 0 then
				showNotification(player, "🚫 " .. bannedCount .. " oyuncu KALICI BANLANDI!", THEME.Danger)
			end
			return true
		end

		local onlineTarget = findPlayerByPartial(targetArg)
		if onlineTarget then
			if not canAffect(player, onlineTarget, myRole) then
				showNotification(player, "Kurucuya işlem yapamazsın!", THEME.Danger)
				return true
			end
			banUserGlobal(onlineTarget.UserId, reason, 0, player, onlineTarget.Name)
			onlineTarget:Kick(reason)
			showNotification(player, "🚫 " .. onlineTarget.Name .. " KALICI BANLANDI!", THEME.Danger)
			return true
		end

		showNotification(player, "🔍 '" .. targetArg .. "' sunucuda yok, çevrimdışı aranıyor...", THEME.Warning)
		task.spawn(function()
			local targetUserId = tonumber(targetArg)
			local resolvedName = targetArg

			if not targetUserId then
				local okId, fetchedId = pcall(function()
					return Players:GetUserIdFromNameAsync(targetArg)
				end)
				if okId and fetchedId then
					targetUserId = fetchedId
				end
			end

			if not targetUserId then
				showNotification(player, "❌ Roblox'ta '" .. targetArg .. "' adında kullanıcı bulunamadı!", THEME.Danger)
				return
			end

			if not canAffectUserId(player, targetUserId, myRole) then
				showNotification(player, "Kurucuya işlem yapamazsın!", THEME.Danger)
				return
			end

			local okName, fetchedName = pcall(function()
				return Players:GetNameFromUserIdAsync(targetUserId)
			end)
			if okName and fetchedName and fetchedName ~= "" then
				resolvedName = fetchedName
				UsernameCache[targetUserId] = fetchedName
			end

			banUserGlobal(targetUserId, reason, 0, player, resolvedName)
			local maybeOnline = Players:GetPlayerByUserId(targetUserId)
			if maybeOnline then
				maybeOnline:Kick(reason)
			end
			showNotification(player, "🚫 " .. resolvedName .. " (ID: " .. tostring(targetUserId) .. ") ÇEVRİMDIŞI BANLANDI!", THEME.Danger)
		end)
		return true

	elseif cmd == "kick" then
		local reason = rawRest:match("^%S+%s+(.+)$") or getAdminState(player).selectedReason
		local targets = resolveTargets(player, args[1], myRole)
		local kickedCount = 0
		for _, t in ipairs(targets) do
			if not (isAllKeyword(args[1]) and t == player) then
				t:Kick(reason)
				kickedCount += 1
				ServerStats.sessionKicks += 1
				addActivityLog("⚠️", player.Name .. " → " .. t.Name .. " kicklendi", THEME.Warning)
			end
		end
		if kickedCount > 0 then showNotification(player, kickedCount .. " oyuncu kicklendi!", THEME.Warning) end
		return true

	elseif cmd == "unban" then
		local targetName = args[1]
		if not targetName then
			showNotification(player, "Kullanım: /unban <isim veya id>", THEME.Warning)
			return true
		end
		local found = false
		local unbannedLabel = targetName
		local numId = tonumber(targetName)

		if numId and ServerBans[numId] then
			ServerBans[numId] = nil
			found = true
		end

		if GlobalBans[targetName] then
			unbannedLabel = GlobalBans[targetName].targetName or targetName
			GlobalBans[targetName] = nil
			found = true
		else
			for userIdStr, bData in pairs(GlobalBans) do
				local name = bData.targetName or UsernameCache[tonumber(userIdStr)]
				if not name then
					local ok, fetched = pcall(function() return Players:GetNameFromUserIdAsync(tonumber(userIdStr)) end)
					if ok and fetched then name = fetched end
				end
				if name and string.lower(name):find(string.lower(targetName), 1, true) then
					unbannedLabel = name
					GlobalBans[userIdStr] = nil
					ServerBans[tonumber(userIdStr)] = nil
					found = true
					break
				end
			end
		end

		if found then
			saveGlobalBans()
			addActivityLog("✅", player.Name .. " → " .. unbannedLabel .. " banını kaldırdı", THEME.Success)
			showNotification(player, unbannedLabel .. " banı kaldırıldı!", THEME.Success)
		else
			showNotification(player, "Banlı kullanıcı bulunamadı!", THEME.Warning)
		end
		return true

	-- DUYURU (3 saniye simsiyah ekran + beyaz yazı)
	elseif cmd == "duyuru" or cmd == "announce" or cmd == "m" or cmd == "mesaj" then
		if not rawRest or rawRest == "" then
			showNotification(player, "Kullanım: /duyuru <mesaj>", THEME.Warning)
			return true
		end
		showBlackoutAnnouncement(rawRest, player.Name)
		return true

	-- KONTROL, JAIL & KÖRLÜK
	elseif cmd == "freeze" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				t.Character.HumanoidRootPart.Anchored = true
			end
		end
		if #targets > 0 then showNotification(player, "Donduruldu (" .. #targets .. ")", THEME.Accent) end
		return true

	elseif cmd == "thaw" or cmd == "unfreeze" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				t.Character.HumanoidRootPart.Anchored = false
			end
		end
		if #targets > 0 then showNotification(player, "Çözüldü (" .. #targets .. ")", THEME.Warning) end
		return true

	elseif cmd == "jail" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			jailPlayer(t)
			addActivityLog("🔒", player.Name .. " → " .. t.Name .. " hapse atıldı", THEME.Purple)
		end
		if #targets > 0 then showNotification(player, "Hapse atıldı (" .. #targets .. ")", THEME.Purple) end
		return true

	elseif cmd == "unjail" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do unjailPlayer(t) end
		if #targets > 0 then showNotification(player, "Hapisten çıkarıldı (" .. #targets .. ")", THEME.Success) end
		return true

	elseif cmd == "blind" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do setBlind(t, true) end
		if #targets > 0 then showNotification(player, "Kör edildi (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	elseif cmd == "unblind" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do setBlind(t, false) end
		if #targets > 0 then showNotification(player, "Körlük açıldı (" .. #targets .. ")", THEME.Success) end
		return true

	elseif cmd == "fling" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
				bv.Velocity = Vector3.new(math.random(-150, 150), 220, math.random(-150, 150))
				bv.Parent = t.Character.HumanoidRootPart
				task.delay(0.35, function() if bv and bv.Parent then bv:Destroy() end end)
			end
		end
		if #targets > 0 then showNotification(player, "Fırlatıldı (" .. #targets .. ")!", THEME.Danger) end
		return true

	-- SAĞLIK & GOD & FF
	elseif cmd == "heal" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.Health = t.Character.Humanoid.MaxHealth
			end
		end
		if #targets > 0 then showNotification(player, "İyileştirildi (" .. #targets .. ")", THEME.Success) end
		return true

	elseif cmd == "kill" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.Health = 0
			end
		end
		if #targets > 0 then showNotification(player, "Öldürüldü (" .. #targets .. ")", THEME.Danger) end
		return true

	elseif cmd == "god" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.MaxHealth = math.huge
				t.Character.Humanoid.Health = math.huge
			end
		end
		if #targets > 0 then showNotification(player, "GOD MODE aktif (" .. #targets .. ")", THEME.Gold) end
		return true

	elseif cmd == "ungod" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.MaxHealth = 100
				t.Character.Humanoid.Health = 100
			end
		end
		if #targets > 0 then showNotification(player, "GOD MODE kapatıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	elseif cmd == "ff" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character then
				local ff = Instance.new("ForceField")
				ff.Parent = t.Character
			end
		end
		if #targets > 0 then showNotification(player, "ForceField verildi (" .. #targets .. ")", THEME.Accent) end
		return true

	elseif cmd == "unff" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character then
				for _, v in ipairs(t.Character:GetChildren()) do
					if v:IsA("ForceField") then v:Destroy() end
				end
			end
		end
		if #targets > 0 then showNotification(player, "ForceField kaldırıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	-- HIZ / ZIPLAMA / GERÇEK FLY / NOCLIP
	elseif cmd == "speed" or cmd == "ws" then
		local targets = resolveTargets(player, args[1], myRole)
		local spd = tonumber(args[2]) or 16
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.WalkSpeed = spd
			end
		end
		if #targets > 0 then showNotification(player, "Hız: " .. spd .. " (" .. #targets .. ")", THEME.Accent) end
		return true

	elseif cmd == "jump" or cmd == "jp" then
		local targets = resolveTargets(player, args[1], myRole)
		local jp = tonumber(args[2]) or 50
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.UseJumpPower = true
				t.Character.Humanoid.JumpPower = jp
			end
		end
		if #targets > 0 then showNotification(player, "Zıplama: " .. jp .. " (" .. #targets .. ")", THEME.Purple) end
		return true

	elseif cmd == "fly" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		local spd = tonumber(args[2]) or 75
		for _, t in ipairs(targets) do
			setFly(t, true, spd)
		end
		if #targets > 0 then showNotification(player, "🕊️ Fly açıldı (" .. #targets .. ")! (WASD + Space + Alt Bar)", THEME.Success) end
		return true

	elseif cmd == "unfly" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			setFly(t, false)
		end
		if #targets > 0 then showNotification(player, "Fly kapatıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	elseif cmd == "noclip" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do setNoclip(t, true) end
		if #targets > 0 then showNotification(player, "Noclip açıldı (" .. #targets .. ")", THEME.Accent) end
		return true

	elseif cmd == "clip" or cmd == "unnoclip" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do setNoclip(t, false) end
		if #targets > 0 then showNotification(player, "Noclip kapatıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	-- IŞINLANMA & RESPAWN
	elseif cmd == "tp" or cmd == "goto" or cmd == "to" then
		local targets = resolveTargets(player, args[1], myRole)
		local dest = nil
		for _, t in ipairs(targets) do
			if t ~= player then dest = t break end
		end
		dest = dest or targets[1]
		if dest and dest.Character and dest.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = dest.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
			showNotification(player, dest.Name .. " yanına gidildi!", THEME.Purple)
		end
		return true

	elseif cmd == "tp2" then
		local targets1 = resolveTargets(player, args[1], myRole)
		local t2 = resolveTargets(player, args[2], myRole)[1]
		if #targets1 > 0 and t2 and t2.Character and t2.Character:FindFirstChild("HumanoidRootPart") then
			local baseCF = t2.Character.HumanoidRootPart.CFrame
			local moved = 0
			for idx, t1 in ipairs(targets1) do
				if t1 ~= t2 and t1.Character and t1.Character:FindFirstChild("HumanoidRootPart") then
					t1.Character.HumanoidRootPart.CFrame = baseCF * CFrame.new((idx - 1) * 3, 0, -4)
					moved += 1
				end
			end
			if moved > 0 then
				showNotification(player, moved .. " oyuncu → " .. t2.Name .. " ışınlandı!", THEME.Purple)
			end
		end
		return true

	elseif cmd == "bring" then
		local targets = resolveTargets(player, args[1], myRole)
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local baseCF = player.Character.HumanoidRootPart.CFrame
			local brought = 0
			for _, t in ipairs(targets) do
				if t ~= player and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
					brought += 1
					t.Character.HumanoidRootPart.CFrame = baseCF * CFrame.new((brought - 1) * 3, 0, -4)
				end
			end
			if brought > 0 then showNotification(player, brought .. " oyuncu yanına çekildi!", THEME.Purple) end
		end
		return true

	elseif cmd == "respawn" or cmd == "re" or cmd == "refresh" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do t:LoadCharacter() end
		if #targets > 0 then showNotification(player, "Respawn (" .. #targets .. ")", THEME.Accent) end
		return true

	-- GÖRÜNÜM & EFEKTLER
	elseif cmd == "invisible" or cmd == "invis" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do setInvisible(t, true) end
		if #targets > 0 then showNotification(player, "Görünmez yapıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	elseif cmd == "visible" or cmd == "vis" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do setInvisible(t, false) end
		if #targets > 0 then showNotification(player, "Görünür yapıldı (" .. #targets .. ")", THEME.TextSecondary) end
		return true

	elseif cmd == "fire" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") and not t.Character.HumanoidRootPart:FindFirstChild("AdminFire") then
				local fire = Instance.new("Fire") fire.Name = "AdminFire" fire.Size = 8 fire.Parent = t.Character.HumanoidRootPart
			end
		end
		if #targets > 0 then showNotification(player, "Ateş eklendi (" .. #targets .. ")!", THEME.Warning) end
		return true

	elseif cmd == "unfire" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				local fire = t.Character.HumanoidRootPart:FindFirstChild("AdminFire")
				if fire then fire:Destroy() end
			end
		end
		if #targets > 0 then showNotification(player, "Ateş kaldırıldı (" .. #targets .. ")!", THEME.TextSecondary) end
		return true

	elseif cmd == "smoke" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") and not t.Character.HumanoidRootPart:FindFirstChild("AdminSmoke") then
				local smoke = Instance.new("Smoke") smoke.Name = "AdminSmoke" smoke.Size = 8 smoke.Parent = t.Character.HumanoidRootPart
			end
		end
		if #targets > 0 then showNotification(player, "Duman eklendi (" .. #targets .. ")!", THEME.TextSecondary) end
		return true

	elseif cmd == "sparkles" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") and not t.Character.HumanoidRootPart:FindFirstChild("AdminSparkle") then
				local sp = Instance.new("Sparkles") sp.Name = "AdminSparkle" sp.SparkleColor = Color3.fromRGB(255, 220, 100) sp.Parent = t.Character.HumanoidRootPart
			end
		end
		if #targets > 0 then showNotification(player, "Kıvılcım eklendi (" .. #targets .. ")!", THEME.Gold) end
		return true

	elseif cmd == "cleareffects" or cmd == "uneffects" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				for _, efName in ipairs({ "AdminFire", "AdminSmoke", "AdminSparkle" }) do
					local ef = t.Character.HumanoidRootPart:FindFirstChild(efName)
					if ef then ef:Destroy() end
				end
			end
		end
		if #targets > 0 then showNotification(player, "Efektler temizlendi (" .. #targets .. ")!", THEME.Success) end
		return true

	elseif cmd == "explode" then
		local targets = resolveTargets(player, args[1], myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				local exp = Instance.new("Explosion")
				exp.Position = t.Character.HumanoidRootPart.Position
				exp.BlastRadius = 20
				exp.BlastPressure = 500000
				exp.Parent = workspace
			end
		end
		if #targets > 0 then showNotification(player, "Patlatıldı (" .. #targets .. ")!", THEME.Danger) end
		return true

	elseif cmd == "size" then
		local targets = resolveTargets(player, args[1], myRole)
		local sz = math.clamp(tonumber(args[2]) or 1, 0.2, 10)
		for _, t in ipairs(targets) do
			if t.Character then pcall(function() t.Character:ScaleTo(sz) end) end
		end
		if #targets > 0 then showNotification(player, "Boyut: " .. sz .. "x (" .. #targets .. ")", THEME.Purple) end
		return true

	elseif cmd == "sit" then
		local targets = resolveTargets(player, args[1] or "me", myRole)
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("Humanoid") then
				t.Character.Humanoid.Sit = true
			end
		end
		if #targets > 0 then showNotification(player, "Oturtuldu (" .. #targets .. ")!", THEME.Warning) end
		return true

	-- LOOP KOMUTLARI
	elseif cmd == "loopkill" then
		local targetArg = args[1]
		local targets = resolveTargets(player, targetArg, myRole)
		if #targets > 0 then
			stopLoop(player)
			showNotification(player, "LOOP KILL başladı (" .. #targets .. " hedef)!", THEME.Danger)
			LoopStates[player.UserId] = {
				conn = RunService.Heartbeat:Connect(function()
					for _, t in ipairs(getDynamicLoopTargets(player, targetArg, myRole, targets)) do
						if t.Parent and t.Character and t.Character:FindFirstChild("Humanoid") then
							t.Character.Humanoid.Health = 0
						end
					end
				end)
			}
		end
		return true

	elseif cmd == "loopheal" then
		local targetArg = args[1] or "me"
		local targets = resolveTargets(player, targetArg, myRole)
		if #targets > 0 then
			stopLoop(player)
			showNotification(player, "LOOP HEAL başladı (" .. #targets .. " hedef)!", THEME.Success)
			LoopStates[player.UserId] = {
				conn = RunService.Heartbeat:Connect(function()
					for _, t in ipairs(getDynamicLoopTargets(player, targetArg, myRole, targets)) do
						if t.Parent and t.Character and t.Character:FindFirstChild("Humanoid") then
							t.Character.Humanoid.Health = t.Character.Humanoid.MaxHealth
						end
					end
				end)
			}
		end
		return true

	elseif cmd == "loopfreeze" then
		local targetArg = args[1]
		local targets = resolveTargets(player, targetArg, myRole)
		if #targets > 0 then
			stopLoop(player)
			showNotification(player, "LOOP FREEZE başladı (" .. #targets .. " hedef)!", THEME.Accent)
			LoopStates[player.UserId] = {
				conn = RunService.Heartbeat:Connect(function()
					for _, t in ipairs(getDynamicLoopTargets(player, targetArg, myRole, targets)) do
						if t.Parent and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
							t.Character.HumanoidRootPart.Anchored = true
						end
					end
				end)
			}
		end
		return true

	elseif cmd == "stoploop" or cmd == "unloop" then
		stopLoop(player)
		showNotification(player, "Loop durduruldu!", THEME.TextSecondary)
		return true

	-- SUNUCU KOMUTLARI
	elseif cmd == "time" then
		local hr = tonumber(args[1]) or 12
		Lighting.ClockTime = hr
		showNotification(player, "Saat: " .. hr, THEME.Warning)
		return true

	elseif cmd == "gravity" or cmd == "grav" then
		local g = tonumber(args[1]) or 196.2
		workspace.Gravity = g
		showNotification(player, "Yerçekimi: " .. g, THEME.Accent)
		return true

	elseif cmd == "slock" then
		ServerLocked = true
		ServerStats.lastLockedBy = player.Name
		ServerStats.lastLockedAt = os.date("%H:%M:%S")
		addActivityLog("🔒", player.Name .. " sunucuyu kilitledi (SLock)", THEME.Danger)
		showNotification(player, "🔒 Sunucu kilitlendi!", THEME.Danger)
		return true

	elseif cmd == "unslock" then
		ServerLocked = false
		addActivityLog("🔓", player.Name .. " sunucu kilidini açtı", THEME.Success)
		showNotification(player, "🔓 Sunucu kilidi açıldı!", THEME.Success)
		return true

	elseif cmd == "cleanup" then
		local count = 0
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("Tool") or v:IsA("Accessory") then
				if v.Parent then v:Destroy() count += 1 end
			end
		end
		addActivityLog("🧹", player.Name .. " " .. count .. " eşya temizledi", THEME.Success)
		showNotification(player, count .. " eşya temizlendi!", THEME.Success)
		return true

	elseif cmd == "rejoin" then
		showNotification(player, "Yeniden bağlanıyor...", THEME.Accent)
		task.wait(0.4)
		TeleportService:Teleport(PLACE_ID, player)
		return true

	elseif cmd == "newserver" or cmd == "hop" then
		showNotification(player, "Yeni sunucu aranıyor...", THEME.Accent)
		pcall(function()
			local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100")
			local data = HttpService:JSONDecode(raw)
			for _, s in ipairs(data.data or {}) do
				if s.playing < s.maxPlayers and s.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, player)
					return
				end
			end
			TeleportService:Teleport(PLACE_ID, player)
		end)
		return true

	elseif cmd == "serverinfo" or cmd == "info" then
		showNotification(player, "👥 " .. #Players:GetPlayers() .. "/" .. MAX_PLAYERS .. " | ⏱️ " .. formatUptime() .. " | " .. cachedGameName, THEME.Accent)
		return true

	elseif cmd == "admin" or cmd == "admins" then
		showNotification(player, "Aktif Yetkililer: " .. getAdminList(), THEME.Gold)
		return true

	elseif cmd == "help" or cmd == "cmds" or cmd == "cmd" then
		local state = getAdminState(player)
		state.selectedTab = "💬 Komutlar"
		state.menuOpen = true
		if _G.__adminOpenMenu then _G.__adminOpenMenu(player) end
		return true
	end

	return false
end

--------------------------------------------------
-- 💬 CHAT HANDLER
--------------------------------------------------
local function onPlayerChatted(player, message)
	if not isAuthorized(player) then return end
	local state = getAdminState(player)
	local lowerMsg = string.lower(message)

	if state.awaitingAnnouncement then
		state.awaitingAnnouncement = false
		if lowerMsg == "/iptal" or lowerMsg == "iptal" then
			showNotification(player, "Duyuru iptal edildi.", THEME.TextSecondary)
			return
		end
		showBlackoutAnnouncement(message, player.Name)
		return
	end

	if lowerMsg == "/panel" or lowerMsg == "/menu" then
		if state.menuOpen then
			state.menuOpen = false
			if _G.__adminCloseMenu then _G.__adminCloseMenu(player) end
		else
			state.menuOpen = true
			if _G.__adminOpenMenu then _G.__adminOpenMenu(player) end
		end
		return
	elseif string.sub(lowerMsg, 1, 7) == "/sebep " then
		local customReason = string.sub(message, 8)
		if customReason and customReason ~= "" then
			state.selectedReason = customReason
			showNotification(player, "Aktif Sebep: " .. customReason, THEME.Accent)
		end
		return
	elseif lowerMsg == "/gemini" then
		if _G.__adminCreateGemini then _G.__adminCreateGemini(player) end
		return
	elseif lowerMsg == "/bans" then
		if _G.__adminCreateBanList then _G.__adminCreateBanList(player) end
		return
	elseif lowerMsg == "/auths" then
		if _G.__adminCreateAuths then _G.__adminCreateAuths(player) end
		return
	end

	local prefix = string.sub(message, 1, 1)
	if prefix == "/" or prefix == ":" then
		local body = string.sub(message, 2)
		local cmd, rest = body:match("^(%S+)%s*(.*)$")
		if cmd then
			local args = splitArgs(rest)
			if handleAdonisCommand(player, cmd, args, rest) then return end
		end
	end

	runRequire(player, message)
end

--------------------------------------------------
-- ✨ GEMİNİ PANELİ
--------------------------------------------------
local createGeminiPanel
createGeminiPanel = function(player)
	if not isAuthorized(player) then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local old = playerGui:FindFirstChild("GeminiAdminUI")
	if old then old:Destroy() end

	local st = getGeminiState(player)
	GeminiTab[player.UserId] = GeminiTab[player.UserId] or "Hareket"

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "GeminiAdminUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 9999
	ScreenGui.Parent = playerGui

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 410, 0, 500)
	MainFrame.Position = UDim2.new(0.5, -205, 0.5, -250)
	MainFrame.BackgroundColor3 = THEME.Bg0
	MainFrame.Parent = ScreenGui
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
	Instance.new("UIStroke", MainFrame).Color = THEME.Accent
	makeWindowDraggable(MainFrame)

	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 46)
	Header.BackgroundColor3 = THEME.Bg1
	Header.Parent = MainFrame
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -60, 1, 0)
	Title.Position = UDim2.new(0, 16, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "✨ GEMİNİ PANELİ  •  V18.2"
	Title.TextColor3 = THEME.Accent
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header

	createButton(Header, "✕", THEME.Danger, UDim2.new(1, -40, 0, 8), UDim2.new(0, 30, 0, 30), function()
		ScreenGui:Destroy()
	end)

	local TabsFrame = Instance.new("Frame")
	TabsFrame.Size = UDim2.new(1, -20, 0, 32)
	TabsFrame.Position = UDim2.new(0, 10, 0, 54)
	TabsFrame.BackgroundColor3 = THEME.Bg1
	TabsFrame.Parent = MainFrame
	Instance.new("UICorner", TabsFrame).CornerRadius = UDim.new(0, 8)

	local tabNames = { "Hareket", "Sağlık", "Görünüm", "Ekstra" }
	local tabWidth = 1 / #tabNames

	local Content = Instance.new("ScrollingFrame")
	Content.Size = UDim2.new(1, -20, 1, -104)
	Content.Position = UDim2.new(0, 10, 0, 94)
	Content.BackgroundColor3 = THEME.Bg1
	Content.BorderSizePixel = 0
	Content.ScrollBarThickness = 4
	Content.ScrollBarImageColor3 = THEME.Accent
	Content.CanvasSize = UDim2.new(0, 0, 0, 0)
	Content.Parent = MainFrame
	Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", Content).Color = THEME.Border
	local CL = Instance.new("UIListLayout", Content)
	CL.Padding = UDim.new(0, 7)
	local CP = Instance.new("UIPadding", Content)
	CP.PaddingTop = UDim.new(0, 10)
	CP.PaddingLeft = UDim.new(0, 8)

	local function addBtn(text, color, cb)
		createButton(Content, text, color, UDim2.new(0, 0, 0, 0), UDim2.new(1, -16, 0, 34), cb)
	end
	local function addSplitBtn(b1, b2)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -16, 0, 34)
		row.BackgroundTransparency = 1
		row.Parent = Content
		createButton(row, b1.text, b1.color, UDim2.new(0, 0, 0, 0), UDim2.new(0.49, 0, 1, 0), b1.cb)
		createButton(row, b2.text, b2.color, UDim2.new(0.51, 0, 0, 0), UDim2.new(0.49, 0, 1, 0), b2.cb)
	end
	local function getHumanoid()
		return player.Character and player.Character:FindFirstChild("Humanoid")
	end
	local function getHRP()
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	end

	local renderContent
	renderContent = function()
		for _, c in ipairs(Content:GetChildren()) do
			if c:IsA("GuiButton") or c:IsA("Frame") then c:Destroy() end
		end
		local tab = GeminiTab[player.UserId]

		if tab == "Hareket" then
			addSplitBtn(
				{ text = "⚡ Hız 50", color = THEME.AccentDark, cb = function() local h = getHumanoid() if h then h.WalkSpeed = 50 showNotification(player, "Hız: 50", THEME.Accent) end end },
				{ text = "⚡ Hız 120", color = THEME.AccentDark, cb = function() local h = getHumanoid() if h then h.WalkSpeed = 120 showNotification(player, "Hız: 120", THEME.Accent) end end }
			)
			addSplitBtn(
				{ text = "🚀 Hız 200", color = THEME.Accent, cb = function() local h = getHumanoid() if h then h.WalkSpeed = 200 showNotification(player, "Hız: 200", THEME.Accent) end end },
				{ text = "🚶 Hız 16", color = THEME.Bg3, cb = function() local h = getHumanoid() if h then h.WalkSpeed = 16 showNotification(player, "Hız: 16", THEME.TextSecondary) end end }
			)
			addSplitBtn(
				{ text = "🦘 Zıpla 110", color = THEME.Purple, cb = function() local h = getHumanoid() if h then h.UseJumpPower = true h.JumpPower = 110 showNotification(player, "Zıplama: 110", THEME.Purple) end end },
				{ text = "👟 Zıpla 50", color = THEME.Bg3, cb = function() local h = getHumanoid() if h then h.UseJumpPower = true h.JumpPower = 50 showNotification(player, "Zıplama: 50", THEME.TextSecondary) end end }
			)
			local flyingNow = isFlying(player)
			addBtn(flyingNow and "🪂 FLY KAPAT" or "🕊️ FLY AÇ (WASD + Space)",
				flyingNow and THEME.Danger or Color3.fromRGB(20, 155, 110), function()
					setFly(player, not isFlying(player), 75)
					showNotification(player, isFlying(player) and "Fly aktif!" or "Fly kapatıldı!", THEME.Success)
					renderContent()
				end)
			addBtn(st.noclip and "🧱 NOCLIP KAPAT" or "👻 NOCLIP AÇ",
				st.noclip and THEME.Danger or Color3.fromRGB(20, 155, 110), function()
					setNoclip(player, not st.noclip)
					showNotification(player, st.noclip and "Noclip aktif!" or "Noclip kapatıldı!", THEME.Success)
					renderContent()
				end)

		elseif tab == "Sağlık" then
			addBtn("❤️ Can Doldur", Color3.fromRGB(25, 160, 95), function() local h = getHumanoid() if h then h.Health = h.MaxHealth showNotification(player, "Can full!", THEME.Success) end end)
			addBtn(st.godMode and "🛡️ GOD MODE KAPAT" or "👑 GOD MODE AÇ",
				st.godMode and THEME.Bg3 or Color3.fromRGB(190, 145, 20), function()
					local h = getHumanoid()
					if h then
						st.godMode = not st.godMode
						h.MaxHealth = st.godMode and math.huge or 100
						h.Health = st.godMode and math.huge or 100
						showNotification(player, st.godMode and "God Mode AÇIK" or "God Mode KAPALI", THEME.Gold)
						renderContent()
					end
				end)
			addBtn("🔄 Pozisyonu Koruyarak Yenile", THEME.AccentDark, function()
				local hrp = getHRP()
				local cf = hrp and hrp.CFrame
				player:LoadCharacter()
				task.spawn(function()
					local char = player.Character or player.CharacterAdded:Wait()
					local h = char:WaitForChild("HumanoidRootPart", 5)
					if h and cf then task.wait(0.1) h.CFrame = cf end
				end)
			end)
			addSplitBtn(
				{ text = "❄️ Dondur", color = THEME.AccentDark, cb = function() local h = getHRP() if h then h.Anchored = true end end },
				{ text = "🔥 Çöz", color = THEME.Warning, cb = function() local h = getHRP() if h then h.Anchored = false end end }
			)

		elseif tab == "Görünüm" then
			addBtn(st.invisible and "👁️ GÖRÜNÜR YAP" or "👻 GÖRÜNMEZ YAP", THEME.Bg3, function()
				setInvisible(player, not st.invisible)
				renderContent()
			end)
			addBtn(st.fullbright and "🌙 FULLBRIGHT KAPAT" or "☀️ FULLBRIGHT AÇ",
				st.fullbright and Color3.fromRGB(45, 55, 135) or Color3.fromRGB(185, 130, 15), function()
					setFullbright(player, not st.fullbright)
					renderContent()
				end)
			addSplitBtn(
				{ text = "🎨 Neon Kırmızı", color = THEME.Danger, cb = function()
					local char = player.Character if not char then return end
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then v.Material = Enum.Material.Neon v.Color = Color3.fromRGB(255, 50, 60) end
					end
				end },
				{ text = "🎨 Normal", color = THEME.Bg3, cb = function()
					local char = player.Character if not char then return end
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then v.Material = Enum.Material.Plastic end
					end
				end }
			)

		elseif tab == "Ekstra" then
			addBtn(st.antiAfk and "🤖 ANTI-AFK KAPAT" or "🤖 ANTI-AFK AÇ",
				st.antiAfk and THEME.Danger or Color3.fromRGB(25, 155, 100), function()
					setAntiAfk(player, not st.antiAfk)
					renderContent()
				end)
			addBtn("🎁 Rastgele Tool Ver", THEME.Purple, function()
				local backpack = player:FindFirstChild("Backpack")
				if not backpack then return end
				local tools = {}
				for _, v in ipairs(game:GetService("ServerStorage"):GetDescendants()) do
					if v:IsA("Tool") then table.insert(tools, v) end
				end
				if #tools > 0 then
					local tool = tools[math.random(1, #tools)]:Clone()
					tool.Parent = backpack
					showNotification(player, "Tool: " .. tool.Name, THEME.Purple)
				else
					showNotification(player, "ServerStorage'da Tool yok!", THEME.Warning)
				end
			end)
			addBtn("📍 Spawn'a Dön", THEME.AccentDark, function()
				local hrp = getHRP()
				local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
				if hrp and spawn then hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0) end
			end)
		end

		task.wait()
		Content.CanvasSize = UDim2.new(0, 0, 0, CL.AbsoluteContentSize.Y + 20)
	end

	for i, tn in ipairs(tabNames) do
		local tBtn = Instance.new("TextButton")
		tBtn.Size = UDim2.new(tabWidth - 0.02, 0, 1, -4)
		tBtn.Position = UDim2.new((i - 1) * tabWidth + 0.01, 0, 0, 2)
		tBtn.BackgroundColor3 = GeminiTab[player.UserId] == tn and THEME.Bg3 or THEME.Bg2
		tBtn.Text = tn
		tBtn.TextColor3 = GeminiTab[player.UserId] == tn and THEME.Accent or THEME.TextSecondary
		tBtn.Font = Enum.Font.GothamBold
		tBtn.TextSize = 11
		tBtn.AutoButtonColor = false
		tBtn.Parent = TabsFrame
		Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
		tBtn.MouseButton1Click:Connect(function()
			GeminiTab[player.UserId] = tn
			for _, t in ipairs(TabsFrame:GetChildren()) do
				if t:IsA("TextButton") then
					t.BackgroundColor3 = THEME.Bg2
					t.TextColor3 = THEME.TextSecondary
				end
			end
			tBtn.BackgroundColor3 = THEME.Bg3
			tBtn.TextColor3 = THEME.Accent
			renderContent()
		end)
	end

	renderContent()
end
_G.__adminCreateGemini = createGeminiPanel

--------------------------------------------------
-- 👑 KAYITLI YETKİLİLER PENCERESİ (Ad + ID)
--------------------------------------------------
local createOfflineAuthsGUI = function(player)
	if not isAuthorized(player) then return end
	local myRole = getPlayerRole(player.UserId)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local old = playerGui:FindFirstChild("OfflineAuthsUI")
	if old then old:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "OfflineAuthsUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 9999
	ScreenGui.Parent = playerGui

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 480, 0, 460)
	MainFrame.Position = UDim2.new(0.5, -240, 0.5, -230)
	MainFrame.BackgroundColor3 = THEME.Bg0
	MainFrame.Parent = ScreenGui
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
	Instance.new("UIStroke", MainFrame).Color = THEME.Gold
	makeWindowDraggable(MainFrame)

	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 46)
	Header.BackgroundColor3 = THEME.Bg1
	Header.Parent = MainFrame
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -60, 1, 0)
	Title.Position = UDim2.new(0, 16, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "👑 KAYITLI YETKİLİLER (AD & ID)"
	Title.TextColor3 = THEME.Gold
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header
	createButton(Header, "✕", THEME.Danger, UDim2.new(1, -40, 0, 8), UDim2.new(0, 30, 0, 30), function() ScreenGui:Destroy() end)

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -20, 1, -64)
	Scroll.Position = UDim2.new(0, 10, 0, 54)
	Scroll.BackgroundColor3 = THEME.Bg1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 5
	Scroll.ScrollBarImageColor3 = THEME.Gold
	Scroll.Parent = MainFrame
	Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 10)
	local UIList = Instance.new("UIListLayout", Scroll)
	UIList.Padding = UDim.new(0, 6)
	local Pad = Instance.new("UIPadding", Scroll)
	Pad.PaddingTop = UDim.new(0, 8)
	Pad.PaddingLeft = UDim.new(0, 8)
	Pad.PaddingRight = UDim.new(0, 8)

	local function addAuthItem(id, roleType)
		local online = Players:GetPlayerByUserId(id) and "🟢" or "⚪"
		local roleColor = (roleType == "Kurucu" and THEME.Gold) or (roleType == "Full" and THEME.Success) or THEME.Accent

		local Item = Instance.new("Frame")
		Item.Size = UDim2.new(1, -4, 0, 48)
		Item.BackgroundColor3 = THEME.Bg2
		Item.Parent = Scroll
		Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", Item).Color = roleColor

		local Av = Instance.new("ImageLabel")
		Av.Size = UDim2.new(0, 34, 0, 34)
		Av.Position = UDim2.new(0, 8, 0.5, -17)
		Av.BackgroundColor3 = THEME.Bg3
		Av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=60&h=60"
		Av.Parent = Item
		Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

		local NameLbl = Instance.new("TextLabel")
		NameLbl.Size = UDim2.new(1, -145, 0, 20)
		NameLbl.Position = UDim2.new(0, 50, 0, 6)
		NameLbl.BackgroundTransparency = 1
		NameLbl.Text = online .. " " .. (UsernameCache[id] or "Yükleniyor...")
		NameLbl.TextColor3 = THEME.TextPrimary
		NameLbl.Font = Enum.Font.GothamBold
		NameLbl.TextSize = 12
		NameLbl.TextXAlignment = Enum.TextXAlignment.Left
		NameLbl.Parent = Item

		local IdLbl = Instance.new("TextLabel")
		IdLbl.Size = UDim2.new(1, -145, 0, 16)
		IdLbl.Position = UDim2.new(0, 50, 0, 26)
		IdLbl.BackgroundTransparency = 1
		IdLbl.Text = "🆔 ID: " .. tostring(id)
		IdLbl.TextColor3 = THEME.TextSecondary
		IdLbl.Font = Enum.Font.Gotham
		IdLbl.TextSize = 10
		IdLbl.TextXAlignment = Enum.TextXAlignment.Left
		IdLbl.Parent = Item

		local Badge = Instance.new("TextLabel")
		Badge.Size = UDim2.new(0, 74, 0, 22)
		Badge.Position = UDim2.new(1, -84, 0.5, -11)
		Badge.BackgroundColor3 = THEME.Bg3
		Badge.Text = string.upper(roleType)
		Badge.TextColor3 = roleColor
		Badge.Font = Enum.Font.GothamBlack
		Badge.TextSize = 9
		Badge.Parent = Item
		Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 6)

		getUsernameAsync(id, function(resolvedName)
			if NameLbl and NameLbl.Parent then
				NameLbl.Text = online .. " " .. resolvedName
			end
		end)
	end

	if myRole == "Basic" then
		addAuthItem(player.UserId, myRole)
	else
		for _, id in ipairs(HARDCODED_AUTHS) do addAuthItem(id, "Kurucu") end
		for _, data in ipairs(DynamicAuths) do addAuthItem(data.id, data.role) end
	end

	task.wait()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end
_G.__adminCreateAuths = createOfflineAuthsGUI

--------------------------------------------------
-- 🚫 DETAYLI BAN LİSTESİ PENCERESİ (Kim, Ne Zaman, Kim Banladı)
--------------------------------------------------
local createBanListGUI
createBanListGUI = function(player)
	if not isAuthorized(player) then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local old = playerGui:FindFirstChild("BanListUI")
	if old then old:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BanListUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 9999
	ScreenGui.Parent = playerGui

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 520, 0, 470)
	MainFrame.Position = UDim2.new(0.5, -260, 0.5, -235)
	MainFrame.BackgroundColor3 = THEME.Bg0
	MainFrame.Parent = ScreenGui
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
	Instance.new("UIStroke", MainFrame).Color = THEME.Danger
	makeWindowDraggable(MainFrame)

	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 46)
	Header.BackgroundColor3 = THEME.Bg1
	Header.Parent = MainFrame
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -60, 1, 0)
	Title.Position = UDim2.new(0, 16, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "🚫 YASAKLI KULLANICILAR (DETAYLI)"
	Title.TextColor3 = THEME.Danger
	Title.Font = Enum.Font.GothamBlack
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header
	createButton(Header, "✕", THEME.Danger, UDim2.new(1, -40, 0, 8), UDim2.new(0, 30, 0, 30), function() ScreenGui:Destroy() end)

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -20, 1, -64)
	Scroll.Position = UDim2.new(0, 10, 0, 54)
	Scroll.BackgroundColor3 = THEME.Bg1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 5
	Scroll.ScrollBarImageColor3 = THEME.Danger
	Scroll.Parent = MainFrame
	Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 10)
	local UIList = Instance.new("UIListLayout", Scroll)
	UIList.Padding = UDim.new(0, 7)
	local Pad = Instance.new("UIPadding", Scroll)
	Pad.PaddingTop = UDim.new(0, 8)
	Pad.PaddingLeft = UDim.new(0, 8)
	Pad.PaddingRight = UDim.new(0, 8)

	local count = 0
	for userIdStr, data in pairs(GlobalBans) do
		count += 1
		local uid = tonumber(userIdStr)
		local Item = Instance.new("Frame")
		Item.Size = UDim2.new(1, -4, 0, 68)
		Item.BackgroundColor3 = THEME.Bg2
		Item.Parent = Scroll
		Instance.new("UICorner", Item).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", Item).Color = Color3.fromRGB(165, 45, 58)

		local Av = Instance.new("ImageLabel")
		Av.Size = UDim2.new(0, 38, 0, 38)
		Av.Position = UDim2.new(0, 8, 0.5, -19)
		Av.BackgroundColor3 = THEME.Bg3
		Av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userIdStr .. "&w=60&h=60"
		Av.Parent = Item
		Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

		local NameLbl = Instance.new("TextLabel")
		NameLbl.Size = UDim2.new(1, -155, 0, 18)
		NameLbl.Position = UDim2.new(0, 54, 0, 6)
		NameLbl.BackgroundTransparency = 1
		NameLbl.Text = "👤 " .. (data.targetName or UsernameCache[uid] or "Yükleniyor...") .. "  (ID: " .. userIdStr .. ")"
		NameLbl.TextColor3 = THEME.TextPrimary
		NameLbl.Font = Enum.Font.GothamBold
		NameLbl.TextSize = 11
		NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		NameLbl.TextXAlignment = Enum.TextXAlignment.Left
		NameLbl.Parent = Item

		local MetaLbl = Instance.new("TextLabel")
		MetaLbl.Size = UDim2.new(1, -155, 0, 16)
		MetaLbl.Position = UDim2.new(0, 54, 0, 26)
		MetaLbl.BackgroundTransparency = 1
		MetaLbl.Text = "🔨 Banlayan: " .. (data.bannedBy or "Bilinmiyor") .. "  •  📅 " .. (data.date or "?") .. "  •  ⏳ " .. formatRemainingBanTime(data.expire)
		MetaLbl.TextColor3 = THEME.Warning
		MetaLbl.Font = Enum.Font.GothamBold
		MetaLbl.TextSize = 9
		MetaLbl.TextTruncate = Enum.TextTruncate.AtEnd
		MetaLbl.TextXAlignment = Enum.TextXAlignment.Left
		MetaLbl.Parent = Item

		local ReasonLbl = Instance.new("TextLabel")
		ReasonLbl.Size = UDim2.new(1, -155, 0, 16)
		ReasonLbl.Position = UDim2.new(0, 54, 0, 44)
		ReasonLbl.BackgroundTransparency = 1
		ReasonLbl.Text = "📌 Sebep: " .. (data.reason or "?")
		ReasonLbl.TextColor3 = THEME.TextSecondary
		ReasonLbl.Font = Enum.Font.Gotham
		ReasonLbl.TextSize = 10
		ReasonLbl.TextTruncate = Enum.TextTruncate.AtEnd
		ReasonLbl.TextXAlignment = Enum.TextXAlignment.Left
		ReasonLbl.Parent = Item

		if not data.targetName then
			getUsernameAsync(uid, function(resolvedName)
				if NameLbl and NameLbl.Parent then
					NameLbl.Text = "👤 " .. resolvedName .. "  (ID: " .. userIdStr .. ")"
				end
			end)
		end

		createButton(Item, "Kaldır", Color3.fromRGB(25, 165, 95), UDim2.new(1, -92, 0.5, -15), UDim2.new(0, 82, 0, 30), function()
			GlobalBans[userIdStr] = nil
			ServerBans[uid] = nil
			saveGlobalBans()
			addActivityLog("✅", player.Name .. " → ID " .. userIdStr .. " banını kaldırdı", THEME.Success)
			showNotification(player, "ID " .. userIdStr .. " banı kaldırıldı!", THEME.Success)
			createBanListGUI(player)
		end)
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 42)
		empty.BackgroundTransparency = 1
		empty.Text = "🚫 Veritabanında yasaklı oyuncu bulunmuyor."
		empty.TextColor3 = THEME.TextMuted
		empty.Font = Enum.Font.GothamBold
		empty.TextSize = 12
		empty.Parent = Scroll
	end

	task.wait()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end
_G.__adminCreateBanList = createBanListGUI

--------------------------------------------------
-- 🖥️ NOVA V18.2 ANA PANELİ (820 x 540 • Sunucu Durumu Dashboard Dahil)
--------------------------------------------------
local MENU_WIDTH = 820
local MENU_HEIGHT = 540

local function syncToggleVisual(player, isOpen)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	local ui = pg:FindFirstChild("AdminUI")
	if not ui then return end
	local btn = ui:FindFirstChild("ToggleButton")
	if btn then
		btn.Text = isOpen and "✕  KAPAT" or "⚡  PANEL"
		btn.TextColor3 = isOpen and THEME.Danger or THEME.Accent
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then st.Color = isOpen and THEME.Danger or THEME.Accent end
	end
end

local function closeMenu(player)
	syncToggleVisual(player, false)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local menu = playerGui:FindFirstChild("AdminMenu")
	if menu then
		local frame = menu:FindFirstChild("MenuFrame")
		if frame then
			TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0)
			}):Play()
			task.wait(0.18)
		end
		menu:Destroy()
	end
end
_G.__adminCloseMenu = closeMenu

local openMenu
openMenu = function(player)
	if not isAuthorized(player) then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local oldMenu = playerGui:FindFirstChild("AdminMenu")
	if oldMenu then oldMenu:Destroy() end

	local state = getAdminState(player)
	local myRole = getPlayerRole(player.UserId) or "Yetkili"
	syncToggleVisual(player, true)

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdminMenu"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 9998
	ScreenGui.Parent = playerGui

	local MenuFrame = Instance.new("Frame")
	MenuFrame.Name = "MenuFrame"
	MenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MenuFrame.Size = UDim2.new(0, 0, 0, 0)
	MenuFrame.BackgroundColor3 = THEME.Bg0
	MenuFrame.BorderSizePixel = 0
	MenuFrame.ClipsDescendants = true
	MenuFrame.Parent = ScreenGui
	Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 16)

	local stroke = Instance.new("UIStroke", MenuFrame)
	stroke.Color = THEME.Accent
	stroke.Thickness = 1.6

	makeWindowDraggable(MenuFrame)

	TweenService:Create(MenuFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, MENU_WIDTH, 0, state.minimized and 52 or MENU_HEIGHT)
	}):Play()

	-- ÜST BAR
	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 52)
	TopBar.BackgroundColor3 = THEME.Bg1
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MenuFrame
	Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

	local HeaderLine = Instance.new("Frame")
	HeaderLine.Size = UDim2.new(1, 0, 0, 1)
	HeaderLine.Position = UDim2.new(0, 0, 1, -1)
	HeaderLine.BackgroundColor3 = THEME.Border
	HeaderLine.BorderSizePixel = 0
	HeaderLine.Parent = TopBar

	local Brand = Instance.new("TextLabel")
	Brand.Size = UDim2.new(0, 200, 1, 0)
	Brand.Position = UDim2.new(0, 16, 0, 0)
	Brand.BackgroundTransparency = 1
	Brand.Text = "⚡ NOVA ADMIN  •  V18.2"
	Brand.TextColor3 = THEME.Accent
	Brand.Font = Enum.Font.GothamBlack
	Brand.TextSize = 15
	Brand.TextXAlignment = Enum.TextXAlignment.Left
	Brand.Parent = TopBar

	local RoleBadge = Instance.new("TextLabel")
	RoleBadge.Size = UDim2.new(0, 74, 0, 22)
	RoleBadge.Position = UDim2.new(0, 218, 0.5, -11)
	RoleBadge.BackgroundColor3 = (myRole == "Kurucu" and Color3.fromRGB(68, 54, 14)) or (myRole == "Full" and Color3.fromRGB(14, 62, 46)) or Color3.fromRGB(16, 48, 76)
	RoleBadge.Text = string.upper(myRole)
	RoleBadge.TextColor3 = (myRole == "Kurucu" and THEME.Gold) or (myRole == "Full" and THEME.Success) or THEME.Accent
	RoleBadge.Font = Enum.Font.GothamBlack
	RoleBadge.TextSize = 10
	RoleBadge.Parent = TopBar
	Instance.new("UICorner", RoleBadge).CornerRadius = UDim.new(0, 6)

	local HeaderInfo = Instance.new("TextLabel")
	HeaderInfo.Size = UDim2.new(0, 330, 1, 0)
	HeaderInfo.Position = UDim2.new(0, 304, 0, 0)
	HeaderInfo.BackgroundTransparency = 1
	HeaderInfo.Text = "👥 " .. #Players:GetPlayers() .. "/" .. MAX_PLAYERS .. "  •  " .. LOAD_SOURCE .. "  •  🎮 " .. cachedGameName
	HeaderInfo.TextColor3 = THEME.TextSecondary
	HeaderInfo.Font = Enum.Font.GothamBold
	HeaderInfo.TextSize = 11
	HeaderInfo.TextTruncate = Enum.TextTruncate.AtEnd
	HeaderInfo.TextXAlignment = Enum.TextXAlignment.Left
	HeaderInfo.Parent = TopBar

	local MinBtn
	MinBtn = createButton(TopBar, state.minimized and "▢" or "—", THEME.Bg3, UDim2.new(1, -86, 0.5, -14), UDim2.new(0, 32, 0, 28), function()
		state.minimized = not state.minimized
		MinBtn.Text = state.minimized and "▢" or "—"
		TweenService:Create(MenuFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, MENU_WIDTH, 0, state.minimized and 52 or MENU_HEIGHT)
		}):Play()
	end)

	createButton(TopBar, "✕", Color3.fromRGB(175, 42, 54), UDim2.new(1, -46, 0.5, -14), UDim2.new(0, 32, 0, 28), function()
		state.menuOpen = false
		closeMenu(player)
	end)

	-- SOL NAVİGASYON
	local Sidebar = Instance.new("Frame")
	Sidebar.Size = UDim2.new(0, 168, 1, -68)
	Sidebar.Position = UDim2.new(0, 10, 0, 60)
	Sidebar.BackgroundColor3 = THEME.Bg1
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MenuFrame
	Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", Sidebar).Color = THEME.Border

	local SideList = Instance.new("UIListLayout", Sidebar)
	SideList.Padding = UDim.new(0, 5)
	local SidePad = Instance.new("UIPadding", Sidebar)
	SidePad.PaddingTop = UDim.new(0, 10)
	SidePad.PaddingLeft = UDim.new(0, 8)
	SidePad.PaddingRight = UDim.new(0, 8)

	local categories = {
		{ name = "📊 Durum",       color = Color3.fromRGB(56, 220, 195) },
		{ name = "⚡ Kontrol",     color = THEME.Danger },
		{ name = "🚀 Hareket",     color = THEME.Accent },
		{ name = "🛡️ Sağlık",      color = THEME.Success },
		{ name = "🌍 Sunucu",      color = THEME.Warning },
		{ name = "👑 Yetkililer",  color = THEME.Gold },
		{ name = "📜 Scriptler",   color = THEME.Purple },
		{ name = "💬 Komutlar",    color = Color3.fromRGB(140, 190, 255) }
	}

	-- ORTA İÇERİK KONTEYNERİ
	local ContentFrame = Instance.new("ScrollingFrame")
	ContentFrame.Size = UDim2.new(1, -412, 1, -68)
	ContentFrame.Position = UDim2.new(0, 186, 0, 60)
	ContentFrame.BackgroundColor3 = THEME.Bg1
	ContentFrame.BorderSizePixel = 0
	ContentFrame.ScrollBarThickness = 4
	ContentFrame.ScrollBarImageColor3 = THEME.Accent
	ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ContentFrame.Parent = MenuFrame
	Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", ContentFrame).Color = THEME.Border

	local ContentList = Instance.new("UIListLayout", ContentFrame)
	ContentList.Padding = UDim.new(0, 8)
	ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local ContentPad = Instance.new("UIPadding", ContentFrame)
	ContentPad.PaddingTop = UDim.new(0, 12)
	ContentPad.PaddingBottom = UDim.new(0, 18)

	-- SAĞ OYUNCU SEÇİCİ
	local RightPanel = Instance.new("Frame")
	RightPanel.Size = UDim2.new(0, 208, 1, -68)
	RightPanel.Position = UDim2.new(1, -218, 0, 60)
	RightPanel.BackgroundColor3 = THEME.Bg1
	RightPanel.BorderSizePixel = 0
	RightPanel.Parent = MenuFrame
	Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", RightPanel).Color = THEME.Border

	local TargetCard = Instance.new("Frame")
	TargetCard.Size = UDim2.new(1, -14, 0, 62)
	TargetCard.Position = UDim2.new(0, 7, 0, 8)
	TargetCard.BackgroundColor3 = THEME.Bg2
	TargetCard.Parent = RightPanel
	Instance.new("UICorner", TargetCard).CornerRadius = UDim.new(0, 10)
	local TargetStroke = Instance.new("UIStroke", TargetCard)
	TargetStroke.Color = THEME.Border

	local TargetAvatar = Instance.new("ImageLabel")
	TargetAvatar.Size = UDim2.new(0, 40, 0, 40)
	TargetAvatar.Position = UDim2.new(0, 8, 0.5, -20)
	TargetAvatar.BackgroundColor3 = THEME.Bg3
	TargetAvatar.Parent = TargetCard
	Instance.new("UICorner", TargetAvatar).CornerRadius = UDim.new(1, 0)

	local TargetGroupIcon = Instance.new("TextLabel")
	TargetGroupIcon.Size = UDim2.new(1, 0, 1, 0)
	TargetGroupIcon.BackgroundTransparency = 1
	TargetGroupIcon.Text = ""
	TargetGroupIcon.TextColor3 = THEME.TextPrimary
	TargetGroupIcon.Font = Enum.Font.GothamBlack
	TargetGroupIcon.TextSize = 20
	TargetGroupIcon.Parent = TargetAvatar

	local TargetNameLbl = Instance.new("TextLabel")
	TargetNameLbl.Size = UDim2.new(1, -58, 0, 20)
	TargetNameLbl.Position = UDim2.new(0, 54, 0, 12)
	TargetNameLbl.BackgroundTransparency = 1
	TargetNameLbl.Font = Enum.Font.GothamBold
	TargetNameLbl.TextSize = 12
	TargetNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	TargetNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	TargetNameLbl.Parent = TargetCard

	local TargetIdLbl = Instance.new("TextLabel")
	TargetIdLbl.Size = UDim2.new(1, -58, 0, 16)
	TargetIdLbl.Position = UDim2.new(0, 54, 0, 34)
	TargetIdLbl.BackgroundTransparency = 1
	TargetIdLbl.TextColor3 = THEME.TextMuted
	TargetIdLbl.Font = Enum.Font.Gotham
	TargetIdLbl.TextSize = 10
	TargetIdLbl.TextXAlignment = Enum.TextXAlignment.Left
	TargetIdLbl.Parent = TargetCard

	local PlayerScroll = Instance.new("ScrollingFrame")
	PlayerScroll.Size = UDim2.new(1, -14, 1, -146)
	PlayerScroll.Position = UDim2.new(0, 7, 0, 138)
	PlayerScroll.BackgroundColor3 = THEME.Bg0
	PlayerScroll.BorderSizePixel = 0
	PlayerScroll.ScrollBarThickness = 4
	PlayerScroll.ScrollBarImageColor3 = THEME.Accent
	PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	PlayerScroll.Parent = RightPanel
	Instance.new("UICorner", PlayerScroll).CornerRadius = UDim.new(0, 8)
	local PlayerListLayout = Instance.new("UIListLayout", PlayerScroll)
	PlayerListLayout.Padding = UDim.new(0, 4)
	local PPad = Instance.new("UIPadding", PlayerScroll)
	PPad.PaddingTop = UDim.new(0, 5)
	PPad.PaddingLeft = UDim.new(0, 5)
	PPad.PaddingRight = UDim.new(0, 5)

	local renderSidebar, renderPlayerList, renderContent
	local btnMe, btnAll, btnOthers

	local function refreshTargetHeader()
		if btnMe then btnMe.BackgroundColor3 = (state.selectedPlayerName == player.Name) and THEME.Success or THEME.Bg3 end
		if btnAll then btnAll.BackgroundColor3 = (state.selectedPlayerName == "__ALL__") and THEME.Warning or THEME.Bg3 end
		if btnOthers then btnOthers.BackgroundColor3 = (state.selectedPlayerName == "__OTHERS__") and THEME.Purple or THEME.Bg3 end

		if state.selectedPlayerName == "__ALL__" then
			TargetCard.BackgroundColor3 = Color3.fromRGB(58, 42, 16)
			TargetStroke.Color = THEME.Warning
			TargetNameLbl.Text = "HERKES (All)"
			TargetNameLbl.TextColor3 = THEME.Warning
			TargetIdLbl.Text = "Tüm oyuncular (" .. tostring(#Players:GetPlayers()) .. ")"
			TargetAvatar.Image = ""
			TargetGroupIcon.Text = "🌍"
		elseif state.selectedPlayerName == "__OTHERS__" then
			TargetCard.BackgroundColor3 = Color3.fromRGB(40, 26, 68)
			TargetStroke.Color = THEME.Purple
			TargetNameLbl.Text = "DİĞERLERİ (Others)"
			TargetNameLbl.TextColor3 = THEME.Purple
			TargetIdLbl.Text = "Sen hariç (" .. tostring(math.max(0, #Players:GetPlayers() - 1)) .. ")"
			TargetAvatar.Image = ""
			TargetGroupIcon.Text = "👥"
		elseif state.selectedPlayerName then
			TargetCard.BackgroundColor3 = Color3.fromRGB(16, 46, 40)
			TargetStroke.Color = THEME.Success
			TargetNameLbl.Text = state.selectedPlayerName
			TargetNameLbl.TextColor3 = THEME.Success
			TargetIdLbl.Text = "ID: " .. tostring(state.selectedPlayerId or "?")
			TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(state.selectedPlayerId or 1) .. "&w=100&h=100"
			TargetGroupIcon.Text = ""
		else
			TargetCard.BackgroundColor3 = THEME.Bg2
			TargetStroke.Color = THEME.Border
			TargetNameLbl.Text = "Hedef Seçilmedi"
			TargetNameLbl.TextColor3 = THEME.TextSecondary
			TargetIdLbl.Text = "Aşağıdan tıkla"
			TargetAvatar.Image = ""
			TargetGroupIcon.Text = "🎯"
		end
	end

	btnMe = createButton(RightPanel, "👤 Ben", THEME.Bg3, UDim2.new(0, 7, 0, 76), UDim2.new(0, 56, 0, 26), function()
		state.selectedPlayerName = player.Name
		state.selectedPlayerId = player.UserId
		refreshTargetHeader()
		renderPlayerList()
	end)
	btnAll = createButton(RightPanel, "🌍 All", THEME.Bg3, UDim2.new(0, 67, 0, 76), UDim2.new(0, 62, 0, 26), function()
		state.selectedPlayerName = "__ALL__"
		state.selectedPlayerId = nil
		refreshTargetHeader()
		renderPlayerList()
	end)
	btnOthers = createButton(RightPanel, "👥 Diğer", THEME.Bg3, UDim2.new(0, 133, 0, 76), UDim2.new(0, 68, 0, 26), function()
		state.selectedPlayerName = "__OTHERS__"
		state.selectedPlayerId = nil
		refreshTargetHeader()
		renderPlayerList()
	end)

	local filterAllBtn, filterAdminBtn
	local function updateFilterBtns()
		if filterAllBtn then filterAllBtn.BackgroundColor3 = (state.playerFilter == "Tümü") and THEME.AccentDark or THEME.Bg2 end
		if filterAdminBtn then filterAdminBtn.BackgroundColor3 = (state.playerFilter == "Yetkili") and THEME.AccentDark or THEME.Bg2 end
	end
	filterAllBtn = createButton(RightPanel, "Tümü", THEME.AccentDark, UDim2.new(0, 7, 0, 108), UDim2.new(0, 74, 0, 24), function()
		state.playerFilter = "Tümü"
		updateFilterBtns()
		renderPlayerList()
	end)
	filterAdminBtn = createButton(RightPanel, "Yetkililer", THEME.Bg2, UDim2.new(0, 85, 0, 108), UDim2.new(0, 78, 0, 24), function()
		state.playerFilter = "Yetkili"
		updateFilterBtns()
		renderPlayerList()
	end)
	createButton(RightPanel, "🔄", THEME.Bg3, UDim2.new(0, 167, 0, 108), UDim2.new(0, 34, 0, 24), function()
		HeaderInfo.Text = "👥 " .. #Players:GetPlayers() .. "/" .. MAX_PLAYERS .. "  •  " .. LOAD_SOURCE .. "  •  🎮 " .. cachedGameName
		refreshTargetHeader()
		renderPlayerList()
		if state.selectedTab == "📊 Durum" then renderContent() end
	end)
	updateFilterBtns()

	renderPlayerList = function()
		for _, c in ipairs(PlayerScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local plist = Players:GetPlayers()
		table.sort(plist, function(a, b)
			local aAuth = getPlayerRole(a.UserId) ~= nil
			local bAuth = getPlayerRole(b.UserId) ~= nil
			if aAuth ~= bAuth then return aAuth end
			return a.Name < b.Name
		end)

		for _, p in ipairs(plist) do
			local pRole = getPlayerRole(p.UserId)
			if state.playerFilter == "Tümü" or pRole ~= nil then
				local isSel = (p.Name == state.selectedPlayerName)
				local pb = Instance.new("TextButton")
				pb.Size = UDim2.new(1, -2, 0, 40)
				pb.BackgroundColor3 = isSel and Color3.fromRGB(16, 56, 48) or THEME.Bg2
				pb.Text = ""
				pb.AutoButtonColor = false
				pb.Parent = PlayerScroll
				Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 7)
				if isSel then Instance.new("UIStroke", pb).Color = THEME.Success end

				local av = Instance.new("ImageLabel")
				av.Size = UDim2.new(0, 26, 0, 26)
				av.Position = UDim2.new(0, 6, 0.5, -13)
				av.BackgroundColor3 = THEME.Bg3
				av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=60&h=60"
				av.Parent = pb
				Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

				local nLbl = Instance.new("TextLabel")
				nLbl.Size = UDim2.new(1, -40, 0, 18)
				nLbl.Position = UDim2.new(0, 38, 0, 4)
				nLbl.BackgroundTransparency = 1
				nLbl.Text = (pRole and ("[" .. pRole .. "] ") or "") .. p.Name
				nLbl.TextColor3 = isSel and THEME.Success or (pRole == "Kurucu" and THEME.Gold or THEME.TextPrimary)
				nLbl.Font = Enum.Font.GothamBold
				nLbl.TextSize = 10
				nLbl.TextTruncate = Enum.TextTruncate.AtEnd
				nLbl.TextXAlignment = Enum.TextXAlignment.Left
				nLbl.Parent = pb

				local idSub = Instance.new("TextLabel")
				idSub.Size = UDim2.new(1, -40, 0, 14)
				idSub.Position = UDim2.new(0, 38, 0, 22)
				idSub.BackgroundTransparency = 1
				idSub.Text = "ID: " .. tostring(p.UserId)
				idSub.TextColor3 = THEME.TextMuted
				idSub.Font = Enum.Font.Gotham
				idSub.TextSize = 9
				idSub.TextXAlignment = Enum.TextXAlignment.Left
				idSub.Parent = pb

				pb.MouseButton1Click:Connect(function()
					state.selectedPlayerName = p.Name
					state.selectedPlayerId = p.UserId
					refreshTargetHeader()
					renderPlayerList()
				end)
			end
		end
		task.wait()
		PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, PlayerListLayout.AbsoluteContentSize.Y + 10)
	end

	local function addSection(title, color)
		local h = Instance.new("Frame")
		h.Size = UDim2.new(0.94, 0, 0, 22)
		h.BackgroundTransparency = 1
		h.Parent = ContentFrame
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 0, 15)
		bar.Position = UDim2.new(0, 0, 0.5, -7)
		bar.BackgroundColor3 = color or THEME.Accent
		bar.BorderSizePixel = 0
		bar.Parent = h
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -14, 1, 0)
		lbl.Position = UDim2.new(0, 12, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = color or THEME.Accent
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = h
	end

	local function addRow(btns, height)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(0.94, 0, 0, height or 36)
		row.BackgroundTransparency = 1
		row.Parent = ContentFrame
		local n = #btns
		if n == 1 then
			createButton(row, btns[1].text, btns[1].color, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), btns[1].callback)
		else
			local w = 1 / n
			for i, b in ipairs(btns) do
				createButton(row, b.text, b.color, UDim2.new((i - 1) * w, 0, 0, 0), UDim2.new(w - 0.015, 0, 1, 0), b.callback)
			end
		end
	end

	local function addStatPair(c1, c2)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(0.94, 0, 0, 62)
		row.BackgroundTransparency = 1
		row.Parent = ContentFrame

		local function buildCard(cfg, posX)
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0.49, 0, 1, 0)
			card.Position = UDim2.new(posX, 0, 0, 0)
			card.BackgroundColor3 = THEME.Bg2
			card.Parent = row
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
			Instance.new("UIStroke", card).Color = cfg.color or THEME.Border

			local strip = Instance.new("Frame")
			strip.Size = UDim2.new(0, 4, 1, -14)
			strip.Position = UDim2.new(0, 6, 0, 7)
			strip.BackgroundColor3 = cfg.color or THEME.Accent
			strip.BorderSizePixel = 0
			strip.Parent = card
			Instance.new("UICorner", strip).CornerRadius = UDim.new(1, 0)

			local tLbl = Instance.new("TextLabel")
			tLbl.Size = UDim2.new(1, -20, 0, 15)
			tLbl.Position = UDim2.new(0, 16, 0, 6)
			tLbl.BackgroundTransparency = 1
			tLbl.Text = cfg.title
			tLbl.TextColor3 = THEME.TextMuted
			tLbl.Font = Enum.Font.GothamBold
			tLbl.TextSize = 9
			tLbl.TextXAlignment = Enum.TextXAlignment.Left
			tLbl.Parent = card

			local vLbl = Instance.new("TextLabel")
			vLbl.Size = UDim2.new(1, -20, 0, 22)
			vLbl.Position = UDim2.new(0, 16, 0, 21)
			vLbl.BackgroundTransparency = 1
			vLbl.Text = cfg.value
			vLbl.TextColor3 = cfg.valueColor or THEME.TextPrimary
			vLbl.Font = Enum.Font.GothamBlack
			vLbl.TextSize = 14
			vLbl.TextTruncate = Enum.TextTruncate.AtEnd
			vLbl.TextXAlignment = Enum.TextXAlignment.Left
			vLbl.Parent = card

			local sLbl = Instance.new("TextLabel")
			sLbl.Size = UDim2.new(1, -20, 0, 14)
			sLbl.Position = UDim2.new(0, 16, 0, 44)
			sLbl.BackgroundTransparency = 1
			sLbl.Text = cfg.sub or ""
			sLbl.TextColor3 = THEME.TextSecondary
			sLbl.Font = Enum.Font.Gotham
			sLbl.TextSize = 9
			sLbl.TextTruncate = Enum.TextTruncate.AtEnd
			sLbl.TextXAlignment = Enum.TextXAlignment.Left
			sLbl.Parent = card
		end

		buildCard(c1, 0)
		buildCard(c2, 0.51)
	end

	local function getSelectedTargetArg()
		if not state.selectedPlayerName then
			showNotification(player, "Önce sağ listeden bir hedef seç (veya All / Diğer)!", THEME.Warning)
			return nil
		end
		if state.selectedPlayerName == "__ALL__" then return "all" end
		if state.selectedPlayerName == "__OTHERS__" then return "others" end
		return state.selectedPlayerName
	end

	local function getTargets()
		local arg = getSelectedTargetArg()
		if not arg then return {} end
		return resolveTargets(player, arg, myRole)
	end

	renderSidebar = function()
		for _, c in ipairs(Sidebar:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, cat in ipairs(categories) do
			local isActive = (state.selectedTab == cat.name)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 34)
			btn.BackgroundColor3 = isActive and THEME.Bg3 or THEME.Bg2
			btn.Text = "   " .. cat.name
			btn.TextColor3 = isActive and THEME.TextPrimary or THEME.TextSecondary
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.AutoButtonColor = false
			btn.Parent = Sidebar
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			if isActive then
				Instance.new("UIStroke", btn).Color = cat.color
				local pill = Instance.new("Frame")
				pill.Size = UDim2.new(0, 4, 0, 20)
				pill.Position = UDim2.new(0, 2, 0.5, -10)
				pill.BackgroundColor3 = cat.color
				pill.BorderSizePixel = 0
				pill.Parent = btn
				Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
			end
			btn.MouseButton1Click:Connect(function()
				state.selectedTab = cat.name
				renderSidebar()
				renderContent()
			end)
		end
	end

	renderContent = function()
		for _, c in ipairs(ContentFrame:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
		end
		ContentFrame.CanvasPosition = Vector2.new(0, 0)
		local tab = state.selectedTab

		-- ==================== 📊 SUNUCU DURUMU PANELİ ====================
		if tab == "📊 Durum" then
			local allPlayers = Players:GetPlayers()
			local totalPlrCount = #allPlayers
			local adminCount = 0
			local normalCount = 0
			local onlineAdmins = {}

			for _, p in ipairs(allPlayers) do
				local r = getPlayerRole(p.UserId)
				if r then
					adminCount += 1
					table.insert(onlineAdmins, p.Name .. " [" .. r .. "]")
				else
					normalCount += 1
				end
			end

			local globalBanCount = 0
			for _ in pairs(GlobalBans) do globalBanCount += 1 end
			local serverBanCount = 0
			for _ in pairs(ServerBans) do serverBanCount += 1 end
			local totalBanCount = globalBanCount + serverBanCount

			local activeFlyCount = 0
			for _, f in pairs(FlyStates) do if f.active then activeFlyCount += 1 end end
			local activeLoopCount = 0
			for _ in pairs(LoopStates) do activeLoopCount += 1 end
			local jailedCount = 0
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj.Name:sub(1, 10) == "AdminJail_" then jailedCount += 1 end
			end

			local memOk, memMb = pcall(function() return math.floor(StatsService:GetTotalMemoryUsageMb()) end)
			local memText = memOk and (tostring(memMb) .. " MB RAM") or "RAM: ?"
			local wsObjCount = #workspace:GetDescendants()

			addSection("CANLI SUNUCU DURUMU", Color3.fromRGB(56, 220, 195))

			-- Hızlı Yenile & Kilit Değiştir Satırı
			addRow({
				{ text = "🔄 Verileri Yenile", color = THEME.AccentDark, callback = function()
					HeaderInfo.Text = "👥 " .. #Players:GetPlayers() .. "/" .. MAX_PLAYERS .. "  •  " .. LOAD_SOURCE .. "  •  🎮 " .. cachedGameName
					renderPlayerList()
					renderContent()
				end },
				{ text = ServerLocked and "🔓 Kilidi Aç" or "🔒 Sunucuyu Kilitle", color = ServerLocked and Color3.fromRGB(26, 155, 95) or Color3.fromRGB(185, 48, 58), callback = function()
					if ServerLocked then
						handleAdonisCommand(player, "unslock", {}, "")
					else
						handleAdonisCommand(player, "slock", {}, "")
					end
					renderContent()
				end }
			}, 32)

			-- 6'lı İstatistik Kartları
			addStatPair(
				{
					title = "🔒 SUNUCU KİLİDİ",
					value = ServerLocked and "KİLİTLİ (AÇIK)" or "AÇIK (KİLİTSİZ)",
					valueColor = ServerLocked and THEME.Danger or THEME.Success,
					sub = ServerLocked and ("Kitleyen: " .. (ServerStats.lastLockedBy or "Admin")) or "Herkes sunucuya girebilir",
					color = ServerLocked and THEME.Danger or THEME.Success
				},
				{
					title = "👥 TOPLAM OYUNCU",
					value = tostring(totalPlrCount) .. " / " .. tostring(MAX_PLAYERS),
					valueColor = THEME.Accent,
					sub = "Zirve: " .. tostring(ServerStats.peakPlayers) .. "  •  Toplam Giriş: " .. tostring(ServerStats.totalJoins),
					color = THEME.Accent
				}
			)

			addStatPair(
				{
					title = "👑 AKTİF ADMİN",
					value = tostring(adminCount) .. " Yetkili",
					valueColor = THEME.Gold,
					sub = "Kayıtlı: " .. tostring(#HARDCODED_AUTHS + #DynamicAuths) .. " yetkili",
					color = THEME.Gold
				},
				{
					title = "👤 NORMAL OYUNCU",
					value = tostring(normalCount) .. " Oyuncu",
					valueColor = THEME.TextPrimary,
					sub = (totalPlrCount > 0) and ("%" .. tostring(math.floor((normalCount / totalPlrCount) * 100)) .. " normal oyuncu") or "Sunucu boş",
					color = THEME.Purple
				}
			)

			addStatPair(
				{
					title = "🚫 BANLI OYUNCULAR",
					value = tostring(totalBanCount) .. " Yasaklı",
					valueColor = THEME.Danger,
					sub = tostring(globalBanCount) .. " Global  •  " .. tostring(serverBanCount) .. " Sunucu",
					color = THEME.Danger
				},
				{
					title = "⚡ PERFORMANS",
					value = tostring(ServerStats.serverFPS) .. " FPS",
					valueColor = (ServerStats.serverFPS >= 50 and THEME.Success) or (ServerStats.serverFPS >= 35 and THEME.Warning) or THEME.Danger,
					sub = memText .. "  •  ⏱️ " .. formatUptime(),
					color = THEME.Success
				}
			)

			-- Doluluk & Admin/Normal Oranı Barı
			local barCard = Instance.new("Frame")
			barCard.Size = UDim2.new(0.94, 0, 0, 56)
			barCard.BackgroundColor3 = THEME.Bg2
			barCard.Parent = ContentFrame
			Instance.new("UICorner", barCard).CornerRadius = UDim.new(0, 9)
			Instance.new("UIStroke", barCard).Color = THEME.Border

			local fillPct = math.clamp(totalPlrCount / math.max(1, MAX_PLAYERS), 0, 1)
			local barTitle = Instance.new("TextLabel")
			barTitle.Size = UDim2.new(1, -20, 0, 18)
			barTitle.Position = UDim2.new(0, 10, 0, 6)
			barTitle.BackgroundTransparency = 1
			barTitle.Text = "📈 Sunucu Doluluğu: %" .. tostring(math.floor(fillPct * 100)) .. "   |   👑 " .. adminCount .. " Admin  •  👤 " .. normalCount .. " Oyuncu"
			barTitle.TextColor3 = THEME.TextSecondary
			barTitle.Font = Enum.Font.GothamBold
			barTitle.TextSize = 10
			barTitle.TextXAlignment = Enum.TextXAlignment.Left
			barTitle.Parent = barCard

			local barBg = Instance.new("Frame")
			barBg.Size = UDim2.new(1, -20, 0, 10)
			barBg.Position = UDim2.new(0, 10, 0, 28)
			barBg.BackgroundColor3 = THEME.Bg0
			barBg.BorderSizePixel = 0
			barBg.Parent = barCard
			Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

			local adminRatio = (totalPlrCount > 0) and (adminCount / math.max(1, MAX_PLAYERS)) or 0
			local normalRatio = (totalPlrCount > 0) and (normalCount / math.max(1, MAX_PLAYERS)) or 0

			if adminRatio > 0 then
				local adminFill = Instance.new("Frame")
				adminFill.Size = UDim2.new(math.clamp(adminRatio, 0, 1), 0, 1, 0)
				adminFill.BackgroundColor3 = THEME.Gold
				adminFill.BorderSizePixel = 0
				adminFill.Parent = barBg
				Instance.new("UICorner", adminFill).CornerRadius = UDim.new(1, 0)
			end
			if normalRatio > 0 then
				local normFill = Instance.new("Frame")
				normFill.Size = UDim2.new(math.clamp(normalRatio, 0, 1 - adminRatio), 0, 1, 0)
				normFill.Position = UDim2.new(math.clamp(adminRatio, 0, 1), 0, 0, 0)
				normFill.BackgroundColor3 = THEME.Accent
				normFill.BorderSizePixel = 0
				normFill.Parent = barBg
				Instance.new("UICorner", normFill).CornerRadius = UDim.new(1, 0)
			end

			local legendLbl = Instance.new("TextLabel")
			legendLbl.Size = UDim2.new(1, -20, 0, 14)
			legendLbl.Position = UDim2.new(0, 10, 0, 40)
			legendLbl.BackgroundTransparency = 1
			legendLbl.Text = "🟡 Adminler: " .. (#onlineAdmins > 0 and table.concat(onlineAdmins, ", ") or "Yok")
			legendLbl.TextColor3 = THEME.Gold
			legendLbl.Font = Enum.Font.Gotham
			legendLbl.TextSize = 9
			legendLbl.TextTruncate = Enum.TextTruncate.AtEnd
			legendLbl.TextXAlignment = Enum.TextXAlignment.Left
			legendLbl.Parent = barCard

			-- TEKNİK & DÜNYA BİLGİSİ
			addSection("TEKNİK & AKTİF SİSTEM ÖZETİ", THEME.Accent)
			local techCard = Instance.new("Frame")
			techCard.Size = UDim2.new(0.94, 0, 0, 96)
			techCard.BackgroundColor3 = THEME.Bg2
			techCard.Parent = ContentFrame
			Instance.new("UICorner", techCard).CornerRadius = UDim.new(0, 9)
			Instance.new("UIStroke", techCard).Color = THEME.Border

			local shortJobId = (game.JobId and game.JobId ~= "") and (game.JobId:sub(1, 18) .. "...") or "Studio Test"
			local techLbl = Instance.new("TextLabel")
			techLbl.Size = UDim2.new(1, -20, 1, -12)
			techLbl.Position = UDim2.new(0, 10, 0, 6)
			techLbl.BackgroundTransparency = 1
			techLbl.Text =
				"📦 Kaynak: " .. LOAD_SOURCE .. "  (" .. BUILD_VERSION .. ")\n" ..
				"🆔 Place ID: " .. tostring(PLACE_ID) .. "   •   JobId: " .. shortJobId .. "\n" ..
				"🕊️ Aktif Fly: " .. activeFlyCount .. "   •   🔒 Hapiste: " .. jailedCount .. "   •   🔁 Loop: " .. activeLoopCount .. "\n" ..
				"🌍 Saat: " .. string.format("%.1f", Lighting.ClockTime) .. "   •   Yerçekimi: " .. math.floor(workspace.Gravity) .. "   •   Objeler: " .. wsObjCount .. "\n" ..
				"📊 Bu Oturumda: " .. ServerStats.sessionKicks .. " Kick   •   " .. ServerStats.sessionBans .. " Ban"
			techLbl.TextColor3 = THEME.TextSecondary
			techLbl.Font = Enum.Font.GothamBold
			techLbl.TextSize = 10
			techLbl.TextXAlignment = Enum.TextXAlignment.Left
			techLbl.TextYAlignment = Enum.TextYAlignment.Top
			techLbl.Parent = techCard

			-- DETAYLI BAN KAYITLARI
			addSection("BAN KAYITLARI (" .. tostring(totalBanCount) .. " YASAKLI)", THEME.Danger)

			-- Önce Sunucu Banları (Geçici)
			for uid, sData in pairs(ServerBans) do
				local info = type(sData) == "table" and sData or { reason = tostring(sData), date = "Bu oturum", bannedBy = "Admin" }
				local bCard = Instance.new("Frame")
				bCard.Size = UDim2.new(0.94, 0, 0, 64)
				bCard.BackgroundColor3 = Color3.fromRGB(36, 20, 28)
				bCard.Parent = ContentFrame
				Instance.new("UICorner", bCard).CornerRadius = UDim.new(0, 8)
				Instance.new("UIStroke", bCard).Color = THEME.Warning

				local av = Instance.new("ImageLabel")
				av.Size = UDim2.new(0, 34, 0, 34)
				av.Position = UDim2.new(0, 8, 0.5, -17)
				av.BackgroundColor3 = THEME.Bg3
				av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(uid) .. "&w=60&h=60"
				av.Parent = bCard
				Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

				local nLbl = Instance.new("TextLabel")
				nLbl.Size = UDim2.new(1, -125, 0, 18)
				nLbl.Position = UDim2.new(0, 48, 0, 5)
				nLbl.BackgroundTransparency = 1
				nLbl.Text = "⛔ [SUNUCU] " .. (info.targetName or UsernameCache[uid] or tostring(uid)) .. " (ID: " .. tostring(uid) .. ")"
				nLbl.TextColor3 = THEME.TextPrimary
				nLbl.Font = Enum.Font.GothamBold
				nLbl.TextSize = 10
				nLbl.TextTruncate = Enum.TextTruncate.AtEnd
				nLbl.TextXAlignment = Enum.TextXAlignment.Left
				nLbl.Parent = bCard

				local mLbl = Instance.new("TextLabel")
				mLbl.Size = UDim2.new(1, -125, 0, 15)
				mLbl.Position = UDim2.new(0, 48, 0, 24)
				mLbl.BackgroundTransparency = 1
				mLbl.Text = "🔨 Banlayan: " .. (info.bannedBy or "?") .. "  •  📅 " .. (info.date or "?")
				mLbl.TextColor3 = THEME.Warning
				mLbl.Font = Enum.Font.GothamBold
				mLbl.TextSize = 9
				mLbl.TextTruncate = Enum.TextTruncate.AtEnd
				mLbl.TextXAlignment = Enum.TextXAlignment.Left
				mLbl.Parent = bCard

				local rLbl = Instance.new("TextLabel")
				rLbl.Size = UDim2.new(1, -125, 0, 15)
				rLbl.Position = UDim2.new(0, 48, 0, 41)
				rLbl.BackgroundTransparency = 1
				rLbl.Text = "📌 Sebep: " .. (info.reason or "?")
				rLbl.TextColor3 = THEME.TextSecondary
				rLbl.Font = Enum.Font.Gotham
				rLbl.TextSize = 9
				rLbl.TextTruncate = Enum.TextTruncate.AtEnd
				rLbl.TextXAlignment = Enum.TextXAlignment.Left
				rLbl.Parent = bCard

				createButton(bCard, "Kaldır", Color3.fromRGB(24, 155, 92), UDim2.new(1, -68, 0.5, -13), UDim2.new(0, 60, 0, 26), function()
					ServerBans[uid] = nil
					addActivityLog("✅", player.Name .. " → ID " .. tostring(uid) .. " sunucu banını kaldırdı", THEME.Success)
					showNotification(player, "Sunucu banı kaldırıldı!", THEME.Success)
					renderContent()
				end)
			end

			-- Global Banlar (Kalıcı / Süreli)
			local globalList = {}
			for uidStr, data in pairs(GlobalBans) do
				table.insert(globalList, { uidStr = uidStr, data = data, ts = data.timestamp or 0 })
			end
			table.sort(globalList, function(a, b) return a.ts > b.ts end)

			for idx, entry in ipairs(globalList) do
				if idx <= 20 then
					local uidStr = entry.uidStr
					local uid = tonumber(uidStr)
					local data = entry.data

					local bCard = Instance.new("Frame")
					bCard.Size = UDim2.new(0.94, 0, 0, 64)
					bCard.BackgroundColor3 = THEME.Bg2
					bCard.Parent = ContentFrame
					Instance.new("UICorner", bCard).CornerRadius = UDim.new(0, 8)
					Instance.new("UIStroke", bCard).Color = Color3.fromRGB(165, 45, 58)

					local av = Instance.new("ImageLabel")
					av.Size = UDim2.new(0, 34, 0, 34)
					av.Position = UDim2.new(0, 8, 0.5, -17)
					av.BackgroundColor3 = THEME.Bg3
					av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. uidStr .. "&w=60&h=60"
					av.Parent = bCard
					Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

					local nLbl = Instance.new("TextLabel")
					nLbl.Size = UDim2.new(1, -125, 0, 18)
					nLbl.Position = UDim2.new(0, 48, 0, 5)
					nLbl.BackgroundTransparency = 1
					nLbl.Text = "💥 " .. (data.targetName or UsernameCache[uid] or "Yükleniyor...") .. "  (ID: " .. uidStr .. ")"
					nLbl.TextColor3 = THEME.TextPrimary
					nLbl.Font = Enum.Font.GothamBold
					nLbl.TextSize = 10
					nLbl.TextTruncate = Enum.TextTruncate.AtEnd
					nLbl.TextXAlignment = Enum.TextXAlignment.Left
					nLbl.Parent = bCard

					local mLbl = Instance.new("TextLabel")
					mLbl.Size = UDim2.new(1, -125, 0, 15)
					mLbl.Position = UDim2.new(0, 48, 0, 24)
					mLbl.BackgroundTransparency = 1
					mLbl.Text = "🔨 " .. (data.bannedBy or "Bilinmiyor") .. "  •  📅 " .. (data.date or "?") .. "  •  ⏳ " .. formatRemainingBanTime(data.expire)
					mLbl.TextColor3 = THEME.Warning
					mLbl.Font = Enum.Font.GothamBold
					mLbl.TextSize = 9
					mLbl.TextTruncate = Enum.TextTruncate.AtEnd
					mLbl.TextXAlignment = Enum.TextXAlignment.Left
					mLbl.Parent = bCard

					local rLbl = Instance.new("TextLabel")
					rLbl.Size = UDim2.new(1, -125, 0, 15)
					rLbl.Position = UDim2.new(0, 48, 0, 41)
					rLbl.BackgroundTransparency = 1
					rLbl.Text = "📌 Sebep: " .. (data.reason or "?")
					rLbl.TextColor3 = THEME.TextSecondary
					rLbl.Font = Enum.Font.Gotham
					rLbl.TextSize = 9
					rLbl.TextTruncate = Enum.TextTruncate.AtEnd
					rLbl.TextXAlignment = Enum.TextXAlignment.Left
					rLbl.Parent = bCard

					if not data.targetName then
						getUsernameAsync(uid, function(resolvedName)
							if nLbl and nLbl.Parent then
								nLbl.Text = "💥 " .. resolvedName .. "  (ID: " .. uidStr .. ")"
							end
						end)
					end

					createButton(bCard, "Kaldır", Color3.fromRGB(24, 155, 92), UDim2.new(1, -68, 0.5, -13), UDim2.new(0, 60, 0, 26), function()
						GlobalBans[uidStr] = nil
						ServerBans[uid] = nil
						saveGlobalBans()
						addActivityLog("✅", player.Name .. " → ID " .. uidStr .. " global banını kaldırdı", THEME.Success)
						showNotification(player, "Ban kaldırıldı!", THEME.Success)
						renderContent()
					end)
				end
			end

			if totalBanCount == 0 then
				local noBanCard = Instance.new("Frame")
				noBanCard.Size = UDim2.new(0.94, 0, 0, 36)
				noBanCard.BackgroundColor3 = THEME.Bg2
				noBanCard.Parent = ContentFrame
				Instance.new("UICorner", noBanCard).CornerRadius = UDim.new(0, 8)
				local nbLbl = Instance.new("TextLabel")
				nbLbl.Size = UDim2.new(1, 0, 1, 0)
				nbLbl.BackgroundTransparency = 1
				nbLbl.Text = "✅ Şu anda kayıtlı yasaklı oyuncu bulunmuyor."
				nbLbl.TextColor3 = THEME.Success
				nbLbl.Font = Enum.Font.GothamBold
				nbLbl.TextSize = 10
				nbLbl.Parent = noBanCard
			end

			-- CANLI SUNUCU HAREKET AKIŞI (LOGLAR)
			addSection("SON SUNUCU HAREKETLERİ", THEME.Purple)
			for idx, logItem in ipairs(ActivityLogs) do
				if idx <= 15 then
					local logRow = Instance.new("Frame")
					logRow.Size = UDim2.new(0.94, 0, 0, 26)
					logRow.BackgroundColor3 = THEME.Bg2
					logRow.Parent = ContentFrame
					Instance.new("UICorner", logRow).CornerRadius = UDim.new(0, 6)

					local tLbl = Instance.new("TextLabel")
					tLbl.Size = UDim2.new(0, 56, 1, 0)
					tLbl.Position = UDim2.new(0, 8, 0, 0)
					tLbl.BackgroundTransparency = 1
					tLbl.Text = "[" .. logItem.time .. "]"
					tLbl.TextColor3 = THEME.TextMuted
					tLbl.Font = Enum.Font.GothamBold
					tLbl.TextSize = 9
					tLbl.TextXAlignment = Enum.TextXAlignment.Left
					tLbl.Parent = logRow

					local msgLbl = Instance.new("TextLabel")
					msgLbl.Size = UDim2.new(1, -72, 1, 0)
					msgLbl.Position = UDim2.new(0, 66, 0, 0)
					msgLbl.BackgroundTransparency = 1
					msgLbl.Text = logItem.icon .. " " .. logItem.text
					msgLbl.TextColor3 = logItem.color or THEME.TextSecondary
					msgLbl.Font = Enum.Font.Gotham
					msgLbl.TextSize = 10
					msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
					msgLbl.TextXAlignment = Enum.TextXAlignment.Left
					msgLbl.Parent = logRow
				end
			end

		-- ==================== ⚡ KONTROL ====================
		elseif tab == "⚡ Kontrol" then
			addSection("CEZA İŞLEMLERİ", THEME.Danger)
			addRow({
				{ text = "⚠️ Kick", color = Color3.fromRGB(185, 115, 25), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "kick", { arg }, arg) end
				end },
				{ text = "⛔ Server Ban", color = Color3.fromRGB(170, 50, 62), callback = function()
					local targets = getTargets()
					local count = 0
					for _, t in ipairs(targets) do
						if not (state.selectedPlayerName == "__ALL__" and t == player) then
							banUserServer(t.UserId, state.selectedReason, player, t.Name)
							t:Kick(state.selectedReason)
							count += 1
						end
					end
					if count > 0 then showNotification(player, count .. " oyuncu sunucudan banlandı!", THEME.Danger) end
				end }
			})
			addRow({
				{ text = "🕒 1 Gün Ban", color = Color3.fromRGB(145, 45, 95), callback = function()
					local targets = getTargets()
					local count = 0
					for _, t in ipairs(targets) do
						if not (state.selectedPlayerName == "__ALL__" and t == player) then
							banUserGlobal(t.UserId, state.selectedReason, 86400, player, t.Name)
							t:Kick(state.selectedReason)
							count += 1
						end
					end
					if count > 0 then showNotification(player, count .. " oyuncu 1 gün banlandı!", THEME.Danger) end
				end },
				{ text = "💥 Kalıcı Ban", color = Color3.fromRGB(205, 36, 48), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "ban", { arg }, arg) end
				end }
			})

			addSection("KONTROL & HAPİS", THEME.Accent)
			addRow({
				{ text = "❄️ Dondur", color = THEME.AccentDark, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "freeze", { arg }, arg) end
				end },
				{ text = "🔥 Çöz", color = Color3.fromRGB(195, 110, 20), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "thaw", { arg }, arg) end
				end }
			})
			addRow({
				{ text = "🔒 Hapse At", color = Color3.fromRGB(110, 58, 190), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "jail", { arg }, arg) end
				end },
				{ text = "🔓 Hapisten Çıkar", color = Color3.fromRGB(25, 145, 95), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "unjail", { arg }, arg) end
				end }
			})
			addRow({
				{ text = "🌑 Kör Et", color = THEME.Bg3, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "blind", { arg }, arg) end
				end },
				{ text = "☀️ Körlüğü Aç", color = THEME.Bg4, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "unblind", { arg }, arg) end
				end }
			})

			addSection("HIZLI IŞINLANMA", THEME.Purple)
			addRow({
				{ text = "📍 Yanına Çek", color = Color3.fromRGB(115, 62, 195), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "bring", { arg }, arg) end
				end },
				{ text = "🚀 Yanına Git", color = Color3.fromRGB(75, 48, 155), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "goto", { arg }, arg) end
				end },
				{ text = "🌪️ Fırlat", color = Color3.fromRGB(185, 48, 60), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "fling", { arg }, arg) end
				end }
			})

		-- ==================== 🚀 HAREKET ====================
		elseif tab == "🚀 Hareket" then
			addSection("UÇUŞ & NOCLIP (WASD + Space + Alt Bar)", THEME.Success)
			addRow({
				{ text = "🕊️ Fly Aç", color = Color3.fromRGB(22, 155, 110), callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "fly", { arg, "75" }, "") end
				end },
				{ text = "🪂 Fly Kapat", color = THEME.Bg3, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "unfly", { arg }, "") end
				end }
			})
			addRow({
				{ text = "👻 Noclip Aç", color = THEME.AccentDark, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "noclip", { arg }, "") end
				end },
				{ text = "🧱 Noclip Kapat", color = THEME.Bg3, callback = function()
					local arg = getSelectedTargetArg()
					if arg then handleAdonisCommand(player, "clip", { arg }, "") end
				end }
			})

			addSection("HIZ & ZIPLAMA", THEME.Accent)
			addRow({
				{ text = "🚶 16", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "speed", { arg, "16" }, "") end end },
				{ text = "⚡ 60", color = THEME.AccentDark, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "speed", { arg, "60" }, "") end end },
				{ text = "⚡ 120", color = THEME.AccentDark, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "speed", { arg, "120" }, "") end end },
				{ text = "🚀 200", color = THEME.Accent, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "speed", { arg, "200" }, "") end end }
			})
			addRow({
				{ text = "👟 Zıp 50", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "jump", { arg, "50" }, "") end end },
				{ text = "🦘 Zıp 110", color = Color3.fromRGB(110, 62, 185), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "jump", { arg, "110" }, "") end end },
				{ text = "🦘 Zıp 190", color = Color3.fromRGB(140, 72, 215), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "jump", { arg, "190" }, "") end end }
			})

			addSection("KARAKTER & BOYUT & EFEKT", THEME.Warning)
			addRow({
				{ text = "🪑 Oturt", color = Color3.fromRGB(185, 130, 22), callback = function()
					local targets = getTargets()
					for _, t in ipairs(targets) do
						if t.Character and t.Character:FindFirstChild("Humanoid") then t.Character.Humanoid.Sit = true end
					end
					if #targets > 0 then showNotification(player, "Oturtuldu (" .. #targets .. ")", THEME.Warning) end
				end },
				{ text = "🛌 Yatır", color = Color3.fromRGB(145, 92, 26), callback = function()
					local targets = getTargets()
					for _, t in ipairs(targets) do
						if t.Character and t.Character:FindFirstChild("Humanoid") then t.Character.Humanoid.PlatformStand = true end
					end
					if #targets > 0 then showNotification(player, "Yatırıldı (" .. #targets .. ")", THEME.Warning) end
				end },
				{ text = "🧍 Kaldır", color = Color3.fromRGB(25, 150, 88), callback = function()
					local targets = getTargets()
					for _, t in ipairs(targets) do
						if t.Character and t.Character:FindFirstChild("Humanoid") then
							t.Character.Humanoid.PlatformStand = false
							t.Character.Humanoid.Sit = false
						end
					end
					if #targets > 0 then showNotification(player, "Kaldırıldı (" .. #targets .. ")", THEME.Success) end
				end }
			})
			addRow({
				{ text = "🐜 0.5x", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "size", { arg, "0.5" }, "") end end },
				{ text = "🧍 1x", color = THEME.Bg4, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "size", { arg, "1" }, "") end end },
				{ text = "🦍 2x", color = Color3.fromRGB(115, 65, 190), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "size", { arg, "2" }, "") end end },
				{ text = "👻 Görünmez", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "invis", { arg }, "") end end },
				{ text = "👁️ Görünür", color = THEME.Bg4, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "vis", { arg }, "") end end }
			})
			addRow({
				{ text = "🔥 Ateş", color = Color3.fromRGB(195, 72, 22), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "fire", { arg }, "") end end },
				{ text = "💨 Duman", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "smoke", { arg }, "") end end },
				{ text = "✨ Kıvılcım", color = Color3.fromRGB(205, 160, 20), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "sparkles", { arg }, "") end end },
				{ text = "💥 Patlat", color = THEME.Danger, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "explode", { arg }, "") end end },
				{ text = "🧹 Temizle", color = THEME.Bg4, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "cleareffects", { arg }, "") end end }
			})

		-- ==================== 🛡️ SAĞLIK ====================
		elseif tab == "🛡️ Sağlık" then
			addSection("CAN & RESPAWN", THEME.Success)
			addRow({
				{ text = "❤️ Can Doldur", color = Color3.fromRGB(24, 160, 92), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "heal", { arg }, "") end end },
				{ text = "💀 Öldür", color = THEME.Danger, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "kill", { arg }, "") end end },
				{ text = "🔄 Respawn", color = THEME.AccentDark, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "respawn", { arg }, "") end end }
			})

			addSection("GOD MODE & KORUMA", THEME.Gold)
			addRow({
				{ text = "👑 God Mode", color = Color3.fromRGB(195, 150, 20), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "god", { arg }, "") end end },
				{ text = "🛡️ UnGod", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "ungod", { arg }, "") end end }
			})
			addRow({
				{ text = "🫧 ForceField Ver", color = THEME.AccentDark, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "ff", { arg }, "") end end },
				{ text = "❌ ForceField Al", color = THEME.Bg3, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "unff", { arg }, "") end end }
			})

			addSection("LOOP İŞLEMLERİ", THEME.Danger)
			addRow({
				{ text = "🔁 Loop Kill", color = Color3.fromRGB(185, 42, 52), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "loopkill", { arg }, "") end end },
				{ text = "🔁 Loop Heal", color = Color3.fromRGB(26, 160, 95), callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "loopheal", { arg }, "") end end },
				{ text = "🔁 Loop Freeze", color = THEME.AccentDark, callback = function() local arg = getSelectedTargetArg() if arg then handleAdonisCommand(player, "loopfreeze", { arg }, "") end end }
			})
			addRow({
				{ text = "⏹️ Aktif Loop'u Durdur", color = THEME.Bg4, callback = function() handleAdonisCommand(player, "stoploop", {}, "") end }
			})

		-- ==================== 🌍 SUNUCU ====================
		elseif tab == "🌍 Sunucu" then
			addSection("📢 SİYAH EKRAN DUYURUSU (3 SANİYE)", THEME.Gold)
			addRow({
				{ text = "📢 Duyuru Modunu Aç (Sonraki Chat Mesajın Duyuru Olur)", color = Color3.fromRGB(185, 140, 20), callback = function()
					state.awaitingAnnouncement = true
					showNotification(player, "📢 Şimdi chat'e duyuru mesajını yaz! (İptal: /iptal)", THEME.Gold)
				end }
			}, 40)

			local tipCard = Instance.new("Frame")
			tipCard.Size = UDim2.new(0.94, 0, 0, 34)
			tipCard.BackgroundColor3 = THEME.Bg2
			tipCard.Parent = ContentFrame
			Instance.new("UICorner", tipCard).CornerRadius = UDim.new(0, 8)
			local tipLbl = Instance.new("TextLabel")
			tipLbl.Size = UDim2.new(1, -16, 1, 0)
			tipLbl.Position = UDim2.new(0, 8, 0, 0)
			tipLbl.BackgroundTransparency = 1
			tipLbl.Text = "💡 Veya direkt chat'e  /duyuru <mesaj>  yazarak da gönderebilirsin."
			tipLbl.TextColor3 = THEME.TextSecondary
			tipLbl.Font = Enum.Font.Gotham
			tipLbl.TextSize = 10
			tipLbl.Parent = tipCard

			addSection("ZAMAN & ATMOSFER & YERÇEKİMİ", THEME.Accent)
			addRow({
				{ text = "☀️ Gündüz", color = Color3.fromRGB(185, 135, 18), callback = function() Lighting.ClockTime = 12 showNotification(player, "Saat: Gündüz", THEME.Warning) end },
				{ text = "🌅 Batımı", color = Color3.fromRGB(175, 88, 35), callback = function() Lighting.ClockTime = 18 showNotification(player, "Saat: Batımı", THEME.Warning) end },
				{ text = "🌙 Gece", color = Color3.fromRGB(48, 55, 145), callback = function() Lighting.ClockTime = 0 showNotification(player, "Saat: Gece", THEME.Accent) end },
				{ text = "🌫️ Sis Yok", color = THEME.Bg3, callback = function() Lighting.FogEnd = 100000 showNotification(player, "Sis kaldırıldı!", THEME.TextSecondary) end }
			})
			addRow({
				{ text = "🌑 Ay (40)", color = Color3.fromRGB(85, 65, 155), callback = function() workspace.Gravity = 40 showNotification(player, "Yerçekimi: 40", THEME.Purple) end },
				{ text = "🌍 Normal (196)", color = THEME.Bg3, callback = function() workspace.Gravity = 196.2 showNotification(player, "Yerçekimi: Normal", THEME.Accent) end },
				{ text = "🪐 Ağır (350)", color = Color3.fromRGB(135, 55, 90), callback = function() workspace.Gravity = 350 showNotification(player, "Yerçekimi: 350", THEME.Warning) end }
			})

			addSection("GÜVENLİK & TEMİZLİK & GITHUB", THEME.Danger)
			addRow({
				{ text = ServerLocked and "🔓 Kilidi Aç (UnSLock)" or "🔒 Sunucuyu Kilitle (SLock)", color = ServerLocked and Color3.fromRGB(28, 155, 95) or Color3.fromRGB(185, 48, 58), callback = function()
					if ServerLocked then
						handleAdonisCommand(player, "unslock", {}, "")
					else
						handleAdonisCommand(player, "slock", {}, "")
					end
					renderContent()
				end },
				{ text = "🔄 GitHub'dan Güncelle", color = THEME.AccentDark, callback = function()
					handleAdonisCommand(player, "guncelle", {}, "")
				end }
			})
			addRow({
				{ text = "🚗 Araçları Temizle", color = Color3.fromRGB(150, 52, 60), callback = function()
					local count = 0
					for _, v in ipairs(workspace:GetDescendants()) do
						if v:IsA("VehicleSeat") and v.Parent then v.Parent:Destroy() count += 1 end
					end
					addActivityLog("🚗", player.Name .. " " .. count .. " araç temizledi", THEME.Success)
					showNotification(player, count .. " araç temizlendi!", THEME.Success)
				end },
				{ text = "🧹 Eşyaları Temizle", color = THEME.Bg3, callback = function() handleAdonisCommand(player, "cleanup", {}, "") end }
			})
			addRow({
				{ text = "🔁 Rejoin", color = THEME.Bg3, callback = function() handleAdonisCommand(player, "rejoin", {}, "") end },
				{ text = "🚀 Başka Sunucuya Geç", color = THEME.AccentDark, callback = function() handleAdonisCommand(player, "hop", {}, "") end }
			})

		-- ==================== 👑 YETKİLİLER ====================
		elseif tab == "👑 Yetkililer" then
			if myRole == "Kurucu" or myRole == "Full" then
				addSection("SEÇİLİ OYUNCUYA / GRUBA YETKİ VER / AL", THEME.Gold)
				addRow({
					{ text = "👑 Kurucu", color = Color3.fromRGB(185, 145, 22), callback = function()
						local targets = getTargets()
						for _, t in ipairs(targets) do setPlayerRole(t.UserId, "Kurucu") end
						if #targets > 0 then showNotification(player, #targets .. " kişi → [Kurucu]", THEME.Gold) renderContent() renderPlayerList() end
					end },
					{ text = "⭐ Full", color = Color3.fromRGB(24, 155, 95), callback = function()
						local targets = getTargets()
						for _, t in ipairs(targets) do setPlayerRole(t.UserId, "Full") end
						if #targets > 0 then showNotification(player, #targets .. " kişi → [Full]", THEME.Success) renderContent() renderPlayerList() end
					end },
					{ text = "🛡️ Basic", color = THEME.AccentDark, callback = function()
						local targets = getTargets()
						for _, t in ipairs(targets) do setPlayerRole(t.UserId, "Basic") end
						if #targets > 0 then showNotification(player, #targets .. " kişi → [Basic]", THEME.Accent) renderContent() renderPlayerList() end
					end },
					{ text = "❌ Al", color = THEME.Danger, callback = function()
						local targets = getTargets()
						for _, t in ipairs(targets) do setPlayerRole(t.UserId, "None") end
						if #targets > 0 then showNotification(player, #targets .. " kişinin yetkisi alındı!", THEME.Danger) renderContent() renderPlayerList() end
					end }
				})
			end

			addSection("MEVCUT YETKİLİLER (KULLANICI ADI & ID)", THEME.Gold)

			local function addAdminCard(userId, roleType, removable)
				local tp = Players:GetPlayerByUserId(userId)
				local onlineDot = tp and "🟢" or "⚪"
				local roleColor = (roleType == "Kurucu" and THEME.Gold) or (roleType == "Full" and THEME.Success) or THEME.Accent

				local Card = Instance.new("Frame")
				Card.Size = UDim2.new(0.94, 0, 0, 48)
				Card.BackgroundColor3 = THEME.Bg2
				Card.Parent = ContentFrame
				Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)
				Instance.new("UIStroke", Card).Color = roleColor

				local Av = Instance.new("ImageLabel")
				Av.Size = UDim2.new(0, 34, 0, 34)
				Av.Position = UDim2.new(0, 8, 0.5, -17)
				Av.BackgroundColor3 = THEME.Bg3
				Av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=60&h=60"
				Av.Parent = Card
				Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

				local NameLbl = Instance.new("TextLabel")
				NameLbl.Size = UDim2.new(1, removable and -175 or -125, 0, 20)
				NameLbl.Position = UDim2.new(0, 50, 0, 6)
				NameLbl.BackgroundTransparency = 1
				NameLbl.Text = onlineDot .. " " .. (tp and tp.Name or (UsernameCache[userId] or "Yükleniyor..."))
				NameLbl.TextColor3 = THEME.TextPrimary
				NameLbl.Font = Enum.Font.GothamBold
				NameLbl.TextSize = 12
				NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
				NameLbl.TextXAlignment = Enum.TextXAlignment.Left
				NameLbl.Parent = Card

				local IdLbl = Instance.new("TextLabel")
				IdLbl.Size = UDim2.new(1, removable and -175 or -125, 0, 16)
				IdLbl.Position = UDim2.new(0, 50, 0, 26)
				IdLbl.BackgroundTransparency = 1
				IdLbl.Text = "🆔 ID: " .. tostring(userId)
				IdLbl.TextColor3 = THEME.TextSecondary
				IdLbl.Font = Enum.Font.Gotham
				IdLbl.TextSize = 10
				IdLbl.TextXAlignment = Enum.TextXAlignment.Left
				IdLbl.Parent = Card

				local RoleTag = Instance.new("TextLabel")
				RoleTag.Size = UDim2.new(0, 66, 0, 22)
				RoleTag.Position = UDim2.new(1, removable and -122 or -74, 0.5, -11)
				RoleTag.BackgroundColor3 = THEME.Bg3
				RoleTag.Text = string.upper(roleType)
				RoleTag.TextColor3 = roleColor
				RoleTag.Font = Enum.Font.GothamBlack
				RoleTag.TextSize = 9
				RoleTag.Parent = Card
				Instance.new("UICorner", RoleTag).CornerRadius = UDim.new(0, 6)

				if removable and (myRole == "Kurucu" or myRole == "Full") then
					createButton(Card, "Al", THEME.Danger, UDim2.new(1, -48, 0.5, -12), UDim2.new(0, 40, 0, 24), function()
						setPlayerRole(userId, "None")
						showNotification(player, "Yetki kaldırıldı!", THEME.Danger)
						renderContent()
						renderPlayerList()
					end)
				end

				if not tp then
					getUsernameAsync(userId, function(resolvedName)
						if NameLbl and NameLbl.Parent then
							NameLbl.Text = onlineDot .. " " .. resolvedName
						end
					end)
				end
			end

			for _, id in ipairs(HARDCODED_AUTHS) do
				addAdminCard(id, "Kurucu", false)
			end
			for _, data in ipairs(DynamicAuths) do
				addAdminCard(data.id, data.role, true)
			end

			addSection("YASAKLI OYUNCULAR & PENCERELER", THEME.Danger)
			addRow({
				{ text = "🚫 Ban Penceresini Aç", color = Color3.fromRGB(170, 45, 55), callback = function() createBanListGUI(player) end },
				{ text = "👑 Yetkili Penceresini Aç", color = Color3.fromRGB(120, 58, 185), callback = function() createOfflineAuthsGUI(player) end }
			})

		-- ==================== 📜 SCRIPTLER ====================
		elseif tab == "📜 Scriptler" then
			addSection("EKSTRA ARAÇLAR", THEME.Accent)
			addRow({
				{ text = "✨ Gemini Panelini Aç", color = THEME.AccentDark, callback = function() createGeminiPanel(player) end },
				{ text = "🔄 Pozisyonu Koruyarak Yenile", color = THEME.Bg3, callback = function()
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local cf = hrp and hrp.CFrame
					player:LoadCharacter()
					task.spawn(function()
						local char = player.Character or player.CharacterAdded:Wait()
						local h = char:WaitForChild("HumanoidRootPart", 5)
						if h and cf then task.wait(0.1) h.CFrame = cf end
					end)
				end }
			})

			addSection("REQUIRE SCRIPTLERİ (SEÇİLİ HEDEFE / GRUBA)", THEME.Purple)
			local scriptsData = {
				{ name = "💣 Bom(!!!)", cmd = 'require(7116428237).SBV4("%s")' },
				{ name = "🔧 Tools", cmd = 'require(7001260635).lctoolsreuploaded("%s")' },
				{ name = "🚁 Helikopter", cmd = 'require(9230060018).RAroblox("%s")' },
				{ name = "⛏️ Driller", cmd = 'require(11505758587).RAroblox("%s")' },
				{ name = "🚜 Excavator", cmd = 'require(16857604287)("%s")' },
				{ name = "🛡️ Adonis", cmd = 'require(5436326937)("%s")' },
				{ name = "⚙️ Admin Panel", cmd = 'require(12159842278).ADMIN("%s")' },
				{ name = "📦 Deks", cmd = 'require(14572394952)("%s")' },
				{ name = "💩 PoopTools", cmd = 'require(16052382566).PoopToolsV2("%s")' },
				{ name = "🔨 Hammer", cmd = 'require(16712454035).load("%s")' }
			}

			addRow({
				{ text = "✅ Tümünü Seç", color = THEME.Bg3, callback = function()
					for i = 1, #scriptsData do state.selectedScripts[i] = true end
					renderContent()
				end },
				{ text = "🧹 Temizle", color = THEME.Bg3, callback = function()
					state.selectedScripts = {}
					renderContent()
				end }
			}, 30)

			for i, sc in ipairs(scriptsData) do
				local isSel = state.selectedScripts[i]
				local tBtn = Instance.new("TextButton")
				tBtn.Size = UDim2.new(0.94, 0, 0, 30)
				tBtn.BackgroundColor3 = isSel and Color3.fromRGB(16, 66, 48) or THEME.Bg2
				tBtn.Text = (isSel and "  ✓  " or "     ") .. sc.name
				tBtn.TextColor3 = isSel and THEME.Success or THEME.TextSecondary
				tBtn.Font = Enum.Font.GothamBold
				tBtn.TextSize = 11
				tBtn.TextXAlignment = Enum.TextXAlignment.Left
				tBtn.AutoButtonColor = false
				tBtn.Parent = ContentFrame
				Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 7)
				if isSel then Instance.new("UIStroke", tBtn).Color = THEME.Success end
				tBtn.MouseButton1Click:Connect(function()
					state.selectedScripts[i] = not state.selectedScripts[i]
					renderContent()
				end)
			end

			addRow({
				{ text = "🚀 SEÇİLİ SCRIPTLERİ ÇALIŞTIR", color = Color3.fromRGB(22, 165, 100), callback = function()
					local targets = getTargets()
					if #targets == 0 then return end
					showNotification(player, "Scriptler çalıştırılıyor (" .. #targets .. " hedef)...", THEME.Success)
					for _, t in ipairs(targets) do
						for i, sc in ipairs(scriptsData) do
							if state.selectedScripts[i] then
								runRequire(player, string.format(sc.cmd, t.Name))
							end
						end
					end
				end }
			}, 38)

		-- ==================== 💬 KOMUTLAR ====================
		elseif tab == "💬 Komutlar" then
			addSection("CHAT KOMUT REHBERİ (/ veya : ile)", THEME.Accent)
			local helpCard = Instance.new("Frame")
			helpCard.Size = UDim2.new(0.94, 0, 0, 440)
			helpCard.BackgroundColor3 = THEME.Bg2
			helpCard.Parent = ContentFrame
			Instance.new("UICorner", helpCard).CornerRadius = UDim.new(0, 10)
			Instance.new("UIStroke", helpCard).Color = THEME.Border

			local helpLbl = Instance.new("TextLabel")
			helpLbl.Size = UDim2.new(1, -24, 1, -18)
			helpLbl.Position = UDim2.new(0, 12, 0, 9)
			helpLbl.BackgroundTransparency = 1
			helpLbl.Text =
				"🎯 Hedef Kısayolları:  me / ben  •  all / herkes  •  others / diğerleri\n" ..
				"🔎 Kısmi İsim: İsmin tamamı gerekmez, ilk 3 harf yeter! (Örn: /fly ahm)\n\n" ..
				"🌐 GITHUB & PANELLER:\n" ..
				"• /durum veya /status — Sunucu Durumu dashboard'unu aç\n" ..
				"• /guncelle — GitHub'daki en güncel kodu canlı çek ve yükle\n" ..
				"• /duyuru <mesaj> — 3 sn siyah ekran + beyaz duyuru\n" ..
				"• /sebep <yazı> — Ceza sebebini ayarla\n" ..
				"• /panel, /gemini, /bans, /auths, /cmds\n\n" ..
				"🚨 MODERASYON (Çevrimdışı Ban Dahil):\n" ..
				"• /ban <isim/kısmi/id> [sebep] — Sunucuda varsa kısmi isimle, yoksa çevrimdışı banlar\n" ..
				"• /unban <isim/id>  •  /kick <hedef> [sebep]\n" ..
				"• /freeze, /thaw, /jail, /unjail, /blind, /unblind, /fling <hedef>\n\n" ..
				"🚀 HAREKET & KARAKTER:\n" ..
				"• /fly <hedef> [hız]  •  /unfly <hedef>\n" ..
				"• /speed <hedef> <hız>  •  /jump <hedef> <güç>  •  /size <hedef> <boy>\n" ..
				"• /noclip, /clip, /sit, /invis, /vis <hedef>\n" ..
				"• /tp, /goto, /bring <hedef>  •  /tp2 <hedef1> <hedef2>\n" ..
				"• /fire, /unfire, /smoke, /sparkles, /cleareffects, /explode <hedef>\n\n" ..
				"🛡️ SAĞLIK & SUNUCU:\n" ..
				"• /heal, /kill, /god, /ungod, /ff, /unff, /respawn <hedef>\n" ..
				"• /loopkill, /loopheal, /loopfreeze <hedef>  •  /stoploop\n" ..
				"• /time <0-24>  •  /gravity <sayı>  •  /slock, /unslock  •  /cleanup  •  /hop"
			helpLbl.TextColor3 = THEME.TextSecondary
			helpLbl.Font = Enum.Font.Gotham
			helpLbl.TextSize = 10
			helpLbl.TextWrapped = true
			helpLbl.TextXAlignment = Enum.TextXAlignment.Left
			helpLbl.TextYAlignment = Enum.TextYAlignment.Top
			helpLbl.Parent = helpCard
		end

		task.wait()
		ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 24)
	end

	refreshTargetHeader()
	renderSidebar()
	renderPlayerList()
	renderContent()
end
_G.__adminOpenMenu = openMenu

--------------------------------------------------
-- ⚡ SABİT MODERN TOGGLE BUTONU
--------------------------------------------------
local function createToggleUI(player)
	if not isAuthorized(player) then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local oldToggle = playerGui:FindFirstChild("AdminUI")
	if oldToggle then oldToggle:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdminUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 10001
	ScreenGui.Parent = playerGui

	local state = getAdminState(player)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleButton"
	toggleBtn.Size = UDim2.new(0, 108, 0, 40)
	toggleBtn.Position = UDim2.new(1, -122, 0.5, -20)
	toggleBtn.BackgroundColor3 = THEME.Bg0
	toggleBtn.Text = state.menuOpen and "✕  KAPAT" or "⚡  PANEL"
	toggleBtn.TextColor3 = state.menuOpen and THEME.Danger or THEME.Accent
	toggleBtn.Font = Enum.Font.GothamBlack
	toggleBtn.TextSize = 12
	toggleBtn.AutoButtonColor = false
	toggleBtn.Parent = ScreenGui
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", toggleBtn)
	stroke.Color = state.menuOpen and THEME.Danger or THEME.Accent
	stroke.Thickness = 1.8

	toggleBtn.MouseEnter:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.14), {
			BackgroundColor3 = THEME.Bg2,
			Position = UDim2.new(1, -128, 0.5, -20)
		}):Play()
	end)
	toggleBtn.MouseLeave:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.14), {
			BackgroundColor3 = THEME.Bg0,
			Position = UDim2.new(1, -122, 0.5, -20)
		}):Play()
	end)

	toggleBtn.MouseButton1Click:Connect(function()
		local st = getAdminState(player)
		if st.menuOpen then
			st.menuOpen = false
			closeMenu(player)
		else
			st.menuOpen = true
			openMenu(player)
		end
	end)
end

--------------------------------------------------
-- 🔄 RESPAWN & OYUNCU OLAYLARI
--------------------------------------------------
local processedPlayers = {}
local respawnTokens = {}

local function forceCleanAllAdminUI(player)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	for _, uiName in ipairs({ "AdminMenu", "AdminUI", "AdminNotification", "AdminBlindUI" }) do
		local ui = playerGui:FindFirstChild(uiName)
		if ui then pcall(function() ui:Destroy() end) end
	end
end

local function rebuildAllAdminUI(player)
	if not player.Parent or not isAuthorized(player) then return end
	createToggleUI(player)
	local state = getAdminState(player)
	if state.menuOpen then openMenu(player) end
end

local function onRespawn(player)
	respawnTokens[player.UserId] = (respawnTokens[player.UserId] or 0) + 1
	local myToken = respawnTokens[player.UserId]
	task.wait(0.7)
	if respawnTokens[player.UserId] ~= myToken or not player.Parent then return end

	if isAuthorized(player) then
		forceCleanAllAdminUI(player)
		task.wait(0.15)
		if respawnTokens[player.UserId] ~= myToken or not player.Parent then return end
		rebuildAllAdminUI(player)
	end

	local st = getGeminiState(player)
	task.wait(0.4)
	if isFlying(player) then
		local spd = FlyStates[player.UserId] and FlyStates[player.UserId].speed or 75
		setFly(player, true, spd)
	end
	if st.noclip and not st.noclipConn then setNoclip(player, true) end
	if st.invisible then setInvisible(player, true) end
end

local function setupPlayer(player)
	if player.Character then task.spawn(onRespawn, player) end
	trackConnection(player.CharacterAdded:Connect(function() task.spawn(onRespawn, player) end))
	trackConnection(player.Chatted:Connect(function(msg) onPlayerChatted(player, msg) end))
end

local function onPlayerAdded(player)
	if processedPlayers[player.UserId] then return end
	processedPlayers[player.UserId] = true

	UsernameCache[player.UserId] = player.Name

	local isBanned, banReason = checkBanStatus(player.UserId)
	if isBanned then
		addActivityLog("🚫", "Banlı giriş engellendi: " .. player.Name, THEME.Danger)
		player:Kick(banReason or "Sunucudan uzaklaştırıldınız.")
		return
	end

	if ServerLocked and not isAuthorized(player) then
		addActivityLog("🔒", "Kilitli sunucu girişi engellendi: " .. player.Name, THEME.Warning)
		player:Kick("🔒 Bu sunucu şu anda yetkililer tarafından kilitlidir.")
		return
	end

	ServerStats.totalJoins += 1
	local currentCount = #Players:GetPlayers()
	if currentCount > ServerStats.peakPlayers then
		ServerStats.peakPlayers = currentCount
	end

	setupPlayer(player)

	if isAuthorized(player) then
		addActivityLog("👑", player.Name .. " [" .. (getPlayerRole(player.UserId) or "Yetkili") .. "] katıldı", THEME.Gold)
		sendAdminJoinLog(player)
		task.wait(1)
		runRequire(player, 'require(12159842278).ADMIN("' .. player.Name .. '")')
		runRequire(player, 'require(14572394952)("' .. player.Name .. '")')
	else
		addActivityLog("🟢", player.Name .. " oyuna katıldı", THEME.Success)
	end

	task.wait(0.5)
	updateServerStatusLog(#Players:GetPlayers())
end

task.spawn(function()
	ensureGameNameLoaded()
	task.wait(1.5)
	updateServerStatusLog(#Players:GetPlayers())
end)

for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
trackConnection(Players.PlayerAdded:Connect(onPlayerAdded))

trackConnection(Players.PlayerRemoving:Connect(function(player)
	addActivityLog("🔴", player.Name .. " oyundan ayrıldı", THEME.TextMuted)
	processedPlayers[player.UserId] = nil
	AdminStates[player.UserId] = nil
	respawnTokens[player.UserId] = nil
	stopLoop(player)
	setFly(player, false)
	unjailPlayer(player)
	if GeminiStates[player.UserId] then
		local st = GeminiStates[player.UserId]
		if st.noclipConn then pcall(function() st.noclipConn:Disconnect() end) end
		if st.antiAfkConn then pcall(function() st.antiAfkConn:Disconnect() end) end
		GeminiStates[player.UserId] = nil
	end
	GeminiTab[player.UserId] = nil
	task.wait(0.5)
	updateServerStatusLog(#Players:GetPlayers())
end))

task.spawn(function()
	while _G.AdminSystemActive do
		task.wait(30)
		if _G.AdminSystemActive then
			updateServerStatusLog(#Players:GetPlayers())
		end
	end
end)
