userInfo = {
	debug = 0,

	cpuLoad = 2,

	-- Điều chỉnh độ nhạy | Sensitivity adjustment
	sensitivity = {
		-- Ngắm ADS | sighting mirror
		ADS = 100,
		-- Bắn hông | take aim
		Aim = 0.55,
		-- Scope 2x | twice scope
		scopeX2 = 1.3,
		-- Scope 3x | trebling scope
		scopeX3 = 1.3,
		-- Scope 4x | quadruple scope
		scopeX4 = 3.9,
		-- Scope 6x | sixfold scope
		scopeX6 = 2.3,
	},

	-- Tự động bắn hông, nếu không dùng thì để trống, nếu dùng thì đặt phím trên bàn phím
	-- Auto aim, leave blank without auto aim, set as the key on the keyboard when using.
	autoPressAimKey = "",

	-- Điều khiển bật/tắt (capslock - dùng phím Caps Lock | numlock - dùng Num Lock | G_bind - dùng lệnh) | Start up control
	startControl = "G_bind",

	-- Thiết lập ngắm (default - dùng thiết lập mặc định của game | recommend - dùng thiết lập khuyến nghị của script | custom - tự định nghĩa | ctrlmode - chế độ ngồi) | Aiming setting
	aimingSettings = "recommend",

	-- Khi aimingSettings = "custom", cần đặt điều kiện tự định nghĩa ở đây, thường dùng cùng IsMouseButtonPressed hoặc IsModifierPressed, cách dùng xem trong tài liệu tham khảo G-series Lua API.docx
	customAimingSettings = {
		-- Điều kiện ADS
		ADS = function ()
			return false -- Điều kiện kiểm tra, giá trị trả về là boolean
		end,
		-- Điều kiện bắn hông
		Aim = function ()
			return false -- Điều kiện kiểm tra, giá trị trả về là boolean
		end,
	},

	canUse = {
		["5.56"] = {
			-- Súng              Chế độ      Hệ số       Hệ số ngồi
			{ "M416",           1,          1,          0.8 }, -- Nòng bù giật + kính cơ bản + tay cầm tam giác + báng súng + băng mở rộng | Komp + Reddot + Triangular grip + Gunstock + Mag
		},
		["7.62"] = {
			-- Súng              Chế độ      Hệ số       Hệ số ngồi
			{ "Beryl M762",     1,          1,          0.8 }, -- Nòng bù giật + kính cơ bản + tay cầm tam giác + băng mở rộng | Komp + Reddot + Triangular grip + Mag
		},
	},

	G_bind = {
		-- G Pro Wireless:
		-- G2 = nút giữa (wheel click) -> bật/tắt script
		-- G4 = nút trái 1 -> chọn nhóm súng 5.56
		-- G5 = nút trái 2 -> chọn nhóm súng 7.62
		["G2"] = "toggle",
		["G4"] = "5.56",
		["G5"] = "7.62",
	},
}

-- internal configuration
pubg = {
	gun = {
		["5.56"] = {},
		["7.62"] = {},
	}, -- Kho súng
	gunOptions = {
		["5.56"] = {},
		["7.62"] = {},
	}, -- Kho cấu hình
	allCanUse = {}, -- Tất cả súng khả dụng
	allCanUse_index = 1, -- Chỉ số trong danh sách tất cả súng khả dụng
	allCanUse_count = 0, -- Tổng số súng khả dụng
	bulletType = "", -- Loại đạn mặc định
	gunIndex = 1,	-- Chỉ số súng đang chọn
	counter = 0, -- Bộ đếm
	xCounter = 0, -- Bộ đếm trục x
	sleep = userInfo.cpuLoad, -- Thiết lập tần suất (không được đặt 0, debug sẽ lỗi)
	sleepRandom = { userInfo.cpuLoad, userInfo.cpuLoad + 5 }, -- Độ trễ ngẫu nhiên để tránh bị phát hiện
	startTime = 0, -- Ghi thời điểm script bắt đầu khi nhấn chuột
	prevTime = 0, -- Ghi thời điểm của vòng chạy trước
	scopeX1 = 1, -- Hệ số chống giật cho ngắm cơ bản (kính trần, red dot, holo, ngắm nghiêng)
	scopeX2 = userInfo.sensitivity.scopeX2, -- Hệ số chống giật scope 2x
	scopeX3 = userInfo.sensitivity.scopeX3, -- Hệ số chống giật scope 3x
	scopeX4 = userInfo.sensitivity.scopeX4, -- Hệ số chống giật scope 4x
	scopeX6 = userInfo.sensitivity.scopeX6, -- Hệ số chống giật scope 6x
	scope_current = "scopeX2", -- Scope hiện tại
	generalSensitivityRatio = userInfo.sensitivity.ADS / 100, -- Điều chỉnh độ nhạy theo tỷ lệ
	isStart = false, -- Trạng thái đã bật hay chưa
	G1 = false, -- Trạng thái phím G1
	currentTime = 0, -- Thời điểm hiện tại
	bulletIndex = 0, -- Viên đạn thứ mấy
}

pubg.xLengthForDebug = pubg.generalSensitivityRatio * 30 -- Độ dài đơn vị di chuyển ngang trong chế độ debug
-- Nút render
pubg.renderDom = {
	switchTable = "",
	separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n", -- Đường phân cách
	combo_key = "G-key", -- Tổ hợp phím
	cmd = "cmd", -- Lệnh
	autoLog = "No operational data yet.\n", -- Dữ liệu xuất ra trong quá trình chống giật
}

-- Có đang ngắm hay không
function pubg.isAimingState (mode)
	local switch = {

		-- ADS
		["ADS"] = function ()
			if userInfo.aimingSettings == "recommend" then
				return IsMouseButtonPressed(3) and not IsModifierPressed("lshift")
			elseif userInfo.aimingSettings == "default" then
				return not IsModifierPressed("lshift") and not IsModifierPressed("lalt")
			elseif userInfo.aimingSettings == "ctrlmode" then
				return IsMouseButtonPressed(3) and not IsModifierPressed("lshift")
			elseif userInfo.aimingSettings == "custom" then
				return userInfo.customAimingSettings.ADS()
			end
		end,

		-- Bắn hông
		["Aim"] = function ()
			if userInfo.aimingSettings == "recommend" then
				if userInfo.autoPressAimKey == "" then
					return IsModifierPressed("lctrl")
				else
					return not IsModifierPressed("lshift") and not IsModifierPressed("lalt")
				end
			elseif userInfo.aimingSettings == "default" then
				return IsMouseButtonPressed(3)
			elseif userInfo.aimingSettings == "ctrlmode" then
				return false
			elseif userInfo.aimingSettings == "custom" then
				return userInfo.customAimingSettings.Aim()
			end
		end,

	}

	return switch[mode]()
end

pubg["Beryl M762"] = function (gunName)

	return pubg.execOptions(gunName, {
		interval = 86,
		ballistic = {
			{1, 0},
			{2, 44},
			{3, 24},
			{5, 28},
			{10, 33},
			{15, 45},
			{30, 47},
			{40, 51},
		}
	})

end

pubg["M416"] = function (gunName)

	return pubg.execOptions(gunName, {
		interval = 85,
		ballistic = {
			{1, 0},
			{2, 35},
			{4, 18},
			{10, 24},
			{15, 32},
			{30, 30},
			{40, 37},
		}
	})

end

-- [[Tìm mục trong canUse theo tên súng]]
function pubg.canUseFindByGunName (gunName)
	local forList = { "5.56", "7.62" }

	for i = 1, #forList do
		local bulletType = forList[i]
		for j = 1, #userInfo.canUse[bulletType] do
			local item = userInfo.canUse[bulletType][j]
			if item[1] == gunName then
				return item
			end
		end
	end
end

--[[ FormatFactory ]]
function pubg.execOptions (gunName, options)

	--[[

		from

		{
			{ 5, 10 },
			{ 10, 24 },
		}

		to

		{ 10, 10, 10, 10, 10, 24, 24, 24, 24, 24 }

		to

		{ 10, 20, 30, 40, 50, 74, 98, 122, 146, 170 }

	]]

	local gunInfo = pubg.canUseFindByGunName(gunName)

	-- Temporary container
	local ballisticConfig1 = {}
	-- Temporary container (v3.0)
	local ballisticConfig2 = {}

	local ballisticIndex = 1
	for i = 1, #options.ballistic do
		local nextCount = options.ballistic[i][1]
		if i ~= 1 then
			nextCount = options.ballistic[i][1] - options.ballistic[i - 1][1]
		end
		for j = 1, nextCount do
			ballisticConfig1[ballisticIndex] =
				-- options.ballistic[i][2] * pubg.generalSensitivityRatio * options.ratio
				options.ballistic[i][2] * pubg.generalSensitivityRatio * gunInfo[3]
			ballisticIndex = ballisticIndex + 1
		end
	end

	for i = 1, #ballisticConfig1 do
		if i == 1 then
			ballisticConfig2[i] = ballisticConfig1[i]
		else
			ballisticConfig2[i] = ballisticConfig2[i - 1] + ballisticConfig1[i]
		end
	end

	-- Làm tròn lên
	-- for i = 1, #ballisticConfig2 do
	-- 	ballisticConfig2[i] = math.ceil(ballisticConfig2[i])
	-- end

	return {
		duration = options.interval * #ballisticConfig2, -- Time of duration
		amount = #ballisticConfig2, -- Number of bullets
		interval = options.interval, -- Time of each bullet
		ballistic = ballisticConfig2, -- ballistic data
		ctrlmodeRatio = gunInfo[4], -- Individual recoil coefficient for each gun when squatting
	}

end

--[[ Initialization of firearms database ]]
function pubg.init ()

	-- Clean up the firearms Depot
	local forList = { "5.56", "7.62" }

	for i = 1, #forList do

		local type = forList[i]
		local gunCount = 0

		for j = 1, #userInfo.canUse[type] do
			local gunName = userInfo.canUse[type][j][1]
			local gunState = userInfo.canUse[type][j][2]

			if gunState >= 1 then
				-- one series
				gunCount = gunCount + 1 -- Accumulative number of firearms configuration files
				pubg.gun[type][gunCount] = gunName -- Adding available firearms to the Arsenal
				pubg.gunOptions[type][gunCount] = pubg[gunName](gunName) -- Get firearms data and add it to the configuration library

				-- Thiết lập bắn liên tục riêng
				pubg.gunOptions[type][gunCount].autoContinuousFiring = ({ 0, 0, 1 })[
					math.max(1, math.min(gunState + 1, 3))
				]
				-- all canUse
				pubg.allCanUse_count = pubg.allCanUse_count + 1 -- Total plus one
				pubg.allCanUse[pubg.allCanUse_count] = gunName -- All available firearms

				if pubg.bulletType == "" then pubg.bulletType = type end -- Default Bullet type

			end

		end

	end

	-- Initial setting of random number seeds
	pubg.SetRandomseed()
	pubg.outputLogRender()
	-- console.log(pubg)

end

-- SetRandomseed
function pubg.SetRandomseed ()
	math.randomseed(GetRunningTime())
end

--[[ Before automatic press gun ]]
function pubg.auto (options)

	-- Accurate aiming press gun
	pubg.currentTime = GetRunningTime()
	pubg.bulletIndex = math.ceil(((pubg.currentTime - pubg.startTime == 0 and {1} or {pubg.currentTime - pubg.startTime})[1]) / options.interval) + 1

	if pubg.bulletIndex > options.amount then return false end
	-- Developer Debugging Mode
	local d = (IsKeyLockOn("scrolllock") and { (pubg.bulletIndex - 1) * pubg.xLengthForDebug } or { 0 })[1]
	local x = math.ceil((pubg.currentTime - pubg.startTime) / (options.interval * (pubg.bulletIndex - 1)) * d) - pubg.xCounter
	local y = math.ceil((pubg.currentTime - pubg.startTime) / (options.interval * (pubg.bulletIndex - 1)) * options.ballistic[pubg.bulletIndex]) - pubg.counter
	-- 4-fold pressure gun mode
	local realY = pubg.getRealY(options, y)
	MoveMouseRelative(x, realY)
	-- Whether to issue automatically or not
	if options.autoContinuousFiring == 1 then
		PressAndReleaseMouseButton(1)
	end

	-- Real-time operation parameters
	pubg.autoLog(options, y)
	pubg.outputLogRender()

	pubg.xCounter = pubg.xCounter + x
	pubg.counter = pubg.counter + y

	pubg.autoSleep(IsKeyLockOn("scrolllock"))

end

--[[ Sleep of pubg.auto ]]
function pubg.autoSleep (isTest)
	local random = 0
	if isTest then
		-- When debugging mode is turned on, Turn off random delays in preventive testing
		random = math.random(pubg.sleep, pubg.sleep)
	else
		random = math.random(pubg.sleepRandom[1], pubg.sleepRandom[2])
	end
	-- Sleep(10)
	Sleep(random)
end

--[[ get real y position ]]
function pubg.getRealY (options, y)
	local realY = y

	if pubg.isAimingState("ADS") then
		realY = y * pubg[pubg.scope_current]
	elseif pubg.isAimingState("Aim") then
		realY = y * userInfo.sensitivity.Aim * pubg.generalSensitivityRatio
	end

	if userInfo.aimingSettings == "ctrlmode" and IsModifierPressed("lctrl") then
		realY = realY * options.ctrlmodeRatio
	end

	return math.round(realY)
end

--[[ change pubg isStart status ]]
function pubg.changeIsStart (isTrue)
	pubg.isStart = isTrue
	if isTrue then
		SetBacklightColor(0, 255, 150, "kb")
		SetBacklightColor(0, 255, 150, "mouse")
	else
		SetBacklightColor(255, 0, 90, "kb")
		SetBacklightColor(255, 0, 90, "mouse")
	end
end

--[[ set bullet type ]]
function pubg.setBulletType (bulletType)
	pubg.bulletType = bulletType
	pubg.gunIndex = 1
	pubg.allCanUse_index = 0

	local forList = { "5.56", "7.62" }

	for i = 1, #forList do
		local type = forList[i]
		if type ==  bulletType then
			pubg.allCanUse_index = pubg.allCanUse_index + 1
			break
		else
			pubg.allCanUse_index = pubg.allCanUse_index + #pubg.gun[type]
		end
	end

	pubg.changeIsStart(true)
end

--[[ set current scope ]]
function pubg.setScope (scope)
	pubg.scope_current = scope
end

--[[ set current gun ]]
function pubg.setGun (gunName)

	local forList = { "5.56", "7.62" }
	local allCanUse_index = 0

	for i = 1, #forList do

		local type = forList[i]
		local gunIndex = 0
		local selected = false

		for j = 1, #userInfo.canUse[type] do
			if userInfo.canUse[type][j][2] >= 1 then
				gunIndex = gunIndex + 1
				allCanUse_index = allCanUse_index + 1
				if userInfo.canUse[type][j][1] == gunName then
					pubg.bulletType = type
					pubg.gunIndex = gunIndex
					pubg.allCanUse_index = allCanUse_index
					selected = true
					break
				end
			end
		end

		if selected then break end

	end

	pubg.changeIsStart(true)
end

--[[ Consider all available firearms as an entire list ]]
function pubg.findInCanUse (cmd)

	if "first_in_canUse" == cmd then
		pubg.allCanUse_index = 1
	elseif "next_in_canUse" == cmd then
		if pubg.allCanUse_index < #pubg.allCanUse then
			pubg.allCanUse_index = pubg.allCanUse_index + 1
		end
	elseif "last_in_canUse" == cmd then
		pubg.allCanUse_index = #pubg.allCanUse
	end

	pubg.setGun(pubg.allCanUse[pubg.allCanUse_index])
end

--[[ Switching guns in the same series ]]
function pubg.findInSeries (cmd)
	if "first" == cmd then
		pubg.gunIndex = 1
	elseif "next" == cmd then
		if pubg.gunIndex < #pubg.gun[pubg.bulletType] then
			pubg.gunIndex = pubg.gunIndex + 1
		end
	elseif "last" == cmd then
		pubg.gunIndex = #pubg.gun[pubg.bulletType]
	end

	pubg.setGun(pubg.gun[pubg.bulletType][pubg.gunIndex])
end

--[[ Script running status ]]
function pubg.runStatus ()
	if userInfo.startControl == "capslock" then
		return IsKeyLockOn("capslock")
	elseif userInfo.startControl == "numlock" then
		return IsKeyLockOn("numlock")
	elseif userInfo.startControl == "G_bind" then
		return pubg.isStart
	end
end

--[[ Độ lệch ngẫu nhiên ]]
function pubg.randomOffset (val, offsetScopePx)
	local offsetScope = (offsetScopePx or 10) / 1080 * 65535

	return math.random(
		math.ceil(val - offsetScope),
		math.ceil(val + offsetScope)
	)
end

--[[ G key command binding ]]
function pubg.runCmd (cmd)
	if cmd == "" then cmd = "none" end
	local switch = {
		["none"] = function () end,
		["5.56"] = pubg.setBulletType,
		["7.62"] = pubg.setBulletType,
		["scopeX1"] = pubg.setScope,
		["scopeX2"] = pubg.setScope,
		["scopeX3"] = pubg.setScope,
		["scopeX4"] = pubg.setScope,
		["scopeX6"] = pubg.setScope,
		["M416"] = pubg.setGun,
		["Beryl M762"] = pubg.setGun,
		["toggle"] = function ()
			pubg.changeIsStart(not pubg.isStart)
		end,
		["off"] = function ()
			pubg.changeIsStart(false)
		end,
	}

	local cmdGroup = string.split(cmd, '|')

	for i = 1, #cmdGroup do
		local _cmd = cmdGroup[i]
		if switch[_cmd] then
			switch[_cmd](_cmd)
		end
	end
end

--[[ autputLog render ]]
function pubg.outputLogRender ()
	if userInfo.debug == 0 then return false end
	if not pubg.G1 then
		pubg.renderDom.switchTable = pubg.outputLogGunSwitchTable()
	end
	local resStr = table.concat({
		"\n>> [\"", pubg.renderDom.combo_key, "\"] = \"", pubg.renderDom.cmd, "\" <<\n",
		pubg.renderDom.separator,
		pubg.renderDom.switchTable,
		pubg.renderDom.separator,
		pubg.outputLogGunInfo(),
		pubg.renderDom.separator,
		pubg.renderDom.autoLog,
		pubg.renderDom.separator,
	})
	ClearLog()
	OutputLogMessage(resStr)
end

--[[ Output switching table ]]
function pubg.outputLogGunSwitchTable ()
	local forList = { "5.56", "7.62" }
	local allCount = 0
	local resStr = "      canUse_i\t      series_i\t      Series\t      ratio\t      ctrl ratio\t      Gun Name\n\n"

	for i = 1, #forList do
		local type = forList[i]
		local gunCount = 0

		for j = 1, #userInfo.canUse[type] do
			if userInfo.canUse[type][j][2] >= 1 then
				local gunName = userInfo.canUse[type][j][1]
				local tag = gunName == pubg.gun[pubg.bulletType][pubg.gunIndex] and "=> " or "      "
				gunCount = gunCount + 1
				allCount = allCount + 1
				resStr = table.concat({ resStr, tag, allCount, "\t", tag, gunCount, "\t", tag, type, "\t", tag, userInfo.canUse[type][j][3], "\t", tag, userInfo.canUse[type][j][4], "\t", tag, gunName, "\n" })
			end
		end

	end

	return resStr
end

-- output Log Gun Info
function pubg.outputLogGunInfo ()
	local k = pubg.bulletType
	local i = pubg.gunIndex
	local gunName = pubg.gun[k][i]

	return table.concat({
		"Currently scope: [ " .. pubg.scope_current .. " ]\n",
		"Currently series: [ ", k, " ]\n",
		"Currently index in series: [ ", i, " / ", #pubg.gun[k], " ]\n",
		"Currently index in canUse: [ ", pubg.allCanUse_index, " / ", pubg.allCanUse_count, " ]\n",
		"Recoil table of [ ", gunName, " ]:\n",
		pubg.outputLogRecoilTable(),
	})
end

--[[ output recoil table log ]]
function pubg.outputLogRecoilTable ()
	local k = pubg.bulletType
	local i = pubg.gunIndex
	local resStr = "{ "
	for j = 1, #pubg.gunOptions[k][i].ballistic do
		local num = pubg.gunOptions[k][i].ballistic[j]
		resStr = table.concat({ resStr, num })
		if j ~= #pubg.gunOptions[k][i].ballistic then
			resStr = table.concat({ resStr, ", " })
		end
	end

	resStr = table.concat({ resStr, " }\n" })

	return resStr
end

--[[ log of pubg.auto ]]
function pubg.autoLog (options, y)
	pubg.renderDom.autoLog = table.concat({
		"----------------------------------- Automatically counteracting gun recoil -----------------------------------\n",
		"------------------------------------------------------------------------------------------------------------------------------\n",
		"bullet index: ", pubg.bulletIndex, "    target counter: ", options.ballistic[pubg.bulletIndex], "    current counter: ", pubg.counter, "\n",
		"D-value(target - current): ", options.ballistic[pubg.bulletIndex], " - ", pubg.counter, " = ", options.ballistic[pubg.bulletIndex] - pubg.counter, "\n",
		"move: math.ceil((", pubg.currentTime, " - ", pubg.startTime, ") / (", options.interval, " * (", pubg.bulletIndex, " - 1)) * ", options.ballistic[pubg.bulletIndex], ") - ", pubg.counter, " = ", y, "\n",
		"------------------------------------------------------------------------------------------------------------------------------\n",
	})
end

function pubg.PressOrRelaseAimKey (toggle)
	if userInfo.autoPressAimKey ~= "" then
		if toggle then
			PressKey(userInfo.autoPressAimKey)
		else
			ReleaseKey(userInfo.autoPressAimKey)
		end
	end
end

--[[ Automatic press gun ]]
function pubg.OnEvent_NoRecoil (event, arg, family)
	if event == "MOUSE_BUTTON_PRESSED" and arg == 1 and family == "mouse" then
		if not pubg.runStatus() then return false end
		if userInfo.aimingSettings ~= "default" and not IsMouseButtonPressed(3) then
			pubg.PressOrRelaseAimKey(true)
		end
		if pubg.isAimingState("ADS") or pubg.isAimingState("Aim") then
			pubg.startTime = GetRunningTime()
			pubg.G1 = true
			SetMKeyState(1, "kb")
		end
	end

	if event == "MOUSE_BUTTON_RELEASED" and arg == 1 and family == "mouse" then
		pubg.PressOrRelaseAimKey(false)
		pubg.G1 = false
		pubg.counter = 0 -- Initialization counter
		pubg.xCounter = 0 -- Initialization xCounter
		pubg.SetRandomseed() -- Reset random number seeds
	end

	if event == "M_PRESSED" and arg == 1 and pubg.G1 then
		pubg.auto(pubg.gunOptions[pubg.bulletType][pubg.gunIndex])
		SetMKeyState(1, "kb")
	end
end

-- [[ processing instruction ]]
function pubg.modifierHandle (modifier)
	local cmd = userInfo.G_bind[modifier]
	pubg.renderDom.combo_key = modifier -- Save combination keys

	if (cmd) then
		pubg.renderDom.cmd = cmd -- Save instruction name
		pubg.runCmd(cmd) -- Execution instructions
	else
		pubg.renderDom.cmd = ""
	end

	pubg.outputLogRender() -- Call log rendering method to output information
end

--[[ Listener method ]]
function OnEvent (event, arg, family)

	-- OutputLogMessage("event = %s, arg = %s, family = %s\n", event, arg, family)
	-- console.log("event = " .. event .. ", arg = " .. arg .. ", family = " .. family)

	pubg.OnEvent_NoRecoil(event, arg, family)

	-- Switching arsenals according to different types of ammunition
	if event == "MOUSE_BUTTON_PRESSED" and arg >=2 and arg <= 11 and family == "mouse" then
		local modifier = "G" .. arg
		local list = { "lalt", "lctrl", "lshift", "ralt", "rctrl", "rshift" }

		for i = 1, #list do
			if IsModifierPressed(list[i]) then
				modifier = list[i] .. " + " .. modifier
				break
			end
		end

		pubg.modifierHandle(modifier)
	elseif event == "G_PRESSED" and arg >=1 and arg <= 12 then
		-- if not pubg.runStatus() and userInfo.startControl ~= "G_bind" then return false end
		local modifier = "F" .. arg

		pubg.modifierHandle(modifier)
	end

	-- Script deactivated event
	if event == "PROFILE_DEACTIVATED" then
		EnablePrimaryMouseButtonEvents(false)
		ReleaseKey("lshift")
		ReleaseKey("lctrl")
		ReleaseKey("lalt")
		ReleaseKey("rshift")
		ReleaseKey("rctrl")
		ReleaseKey("ralt")
		ClearLog()
	end

end

--[[ tools ]]

-- Làm tròn số #170
function math.round (num, digit)
    local decimalPlaces = 10 ^ (digit or 0)
    return math.floor((num * decimalPlaces * 10 + 5) / 10) / decimalPlaces
end

-- split function
function string.split (str, s)
	if string.find(str, s) == nil then return { str } end

	local res = {}
	local reg = "(.-)" .. s .. "()"
	local index = 0
	local last_i

	--- @diagnostic disable-next-line: undefined-field
	for n, i in string.gfind(str, reg) do
		index = index + 1
		res[index] = n
		last_i = i
	end

	res[index + 1] = string.sub(str, last_i)

	return res
end

-- Javascript Array.prototype.reduce
function table.reduce (t, c)
	local res = c(t[1], t[2])
	for i = 3, #t do res = c(res, t[i]) end
	return res
end

-- Javascript Array.prototype.map
function table.map (t, c)
	local res = {}
	for i = 1, #t do res[i] = c(t[i], i) end
	return res
end

-- Javascript Array.prototype.forEach
function table.forEach (t, c)
	for i = 1, #t do c(t[i], i) end
end

--[[
	* In table
	* @param  {any} val     giá trị đầu vào
	* @return {str}         chuỗi đã được format
]]
function table.print (val)

	local function loop (val, keyType, _indent)
		_indent = _indent or 1
		keyType = keyType or "string"
		local res = ""
		local indentStr = "     " -- Khoảng trắng thụt đầu dòng
		local indent = string.rep(indentStr, _indent)
		local end_indent = string.rep(indentStr, _indent - 1)
		local putline = function (...)
			local arr = { res, ... }
			for i = 1, #arr do
				if type(arr[i]) ~= "string" then arr[i] = tostring(arr[i]) end
			end
			res = table.concat(arr)
		end

		if type(val) == "table" then
			putline("{ ")

			if #val > 0 then
				local index = 0
				local block = false

				for i = 1, #val do
					local n = val[i]
					if type(n) == "table" or type(n) == "function" then
						block = true
						break
					end
				end

				if block then
					for i = 1, #val do
						local n = val[i]
						index = index + 1
						if index == 1 then putline("\n") end
						putline(indent, loop(n, type(i), _indent + 1), "\n")
						if index == #val then putline(end_indent) end
					end
				else
					for i = 1, #val do
						local n = val[i]
						index = index + 1
						putline(loop(n, type(i), _indent + 1))
					end
				end

			else
				putline("\n")
				for k, v in pairs(val) do
					putline(indent, k, " = ", loop(v, type(k), _indent + 1), "\n")
				end
				putline(end_indent)
			end

			putline("}, ")
		elseif type(val) == "string" then
			val = string.gsub(val, "\a", "\\a") -- Chuông (BEL)
			val = string.gsub(val, "\b", "\\b") -- Backspace (BS), đưa vị trí hiện tại lùi về một cột
			val = string.gsub(val, "\f", "\\f") -- Form feed (FF), chuyển đến đầu trang kế tiếp
			val = string.gsub(val, "\n", "\\n") -- Xuống dòng (LF), chuyển đến đầu dòng kế tiếp
			val = string.gsub(val, "\r", "\\r") -- Carriage return (CR), chuyển về đầu dòng hiện tại
			val = string.gsub(val, "\t", "\\t") -- Tab ngang (HT), nhảy tới vị trí tab kế tiếp
			val = string.gsub(val, "\v", "\\v") -- Tab dọc (VT)
			putline("\"", val, "\", ")
		elseif type(val) == "boolean" then
			putline(val and "true, " or "false, ")
		elseif type(val) == "function" then
			putline(tostring(val), ", ")
		elseif type(val) == "nil" then
			putline("nil, ")
		else
			putline(val, ", ")
		end

		return res
	end

	local res = loop(val)
	res = string.gsub(res, ",(%s*})", "%1")
	res = string.gsub(res, ",(%s*)$", "%1")
	res = string.gsub(res, "{%s+}", "{}")

	return res
end

-- console
console = {}
function console.log (str)
	OutputLogMessage(table.print(str) .. "\n")
end

--[[ Other ]]
EnablePrimaryMouseButtonEvents(true) -- Enable left mouse button event reporting
pubg.GD = GetDate -- Setting aliases
pubg.init() -- Script initialization

--[[ Script End ]]
