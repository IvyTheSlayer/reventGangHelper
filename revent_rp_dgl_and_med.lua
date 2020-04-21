script_name("get dgl + med use")
script_version_number(1)
script_description("num9 to dgl / num0 to med")
script_author("ivy")

require "lib.moonloader"
local SE = require 'samp.events'
local vkeys = require 'lib.vkeys'
-- настройки кфг --
local inicfg = require 'inicfg'
local cfg = inicfg.load(
	{
		general = {
			medpacks = 0,
			showmedpacks = 1,
		},
		location = 
		{
			pos_x = 115.0,
			pos_y = 425.0
		},
		slot = {
			deagle = 0,
			colt = 0,
			ak47 = 0,
			m4 = 0,
			shot = 0,
			rifle = 0,
			med = 0
		},
		ammo = {
			deagle = 0,
			colt = 0,
			ak47 = 0,
			m4 = 0,
			shot = 0,
			rifle = 0
		}
	},
	'med_and_ammo'
)
local weaponNames = {
	[1] = "Desert Eagle",
	[2] = "Colt 45",
	[3] = "Ak-47",
	[4] = "M4",
	[5] = "Shotgun",
	[6] = "Rifle",
	[7] = "Medkit"
}
local settings = cfg.general
local pos = cfg.location
local slot = cfg.slot
local ammo = cfg.ammo
-- курсор --
local cursorActive = false
-- td id --
local textID = 500
-- диалог ид для хоткеев
local hotkeysDialogId = 34500
-- для нажатия клавиши
local press_button = 0
local wepId = 0
-- проверка в чате
local medUseCheck = ""
-- timer
local endTime = 0
-- для добавления пт
local wepHk = {}
local wepAmmo =  {}
local autoAmmo = false
local ammoClick = false
local sendOnce = false
local ammoId = 0
local weaponId = 0
local isInvOpened = false
-- проверка показывается ли аптеки
local activeTextdraw = false
local hotkeysText = "{EEAD5F}Здесь нахуярь название кнопки полностью:\nПримеры:{E6AFAF}\nArrow Left (стрелка вверх)\nNumpad 0 (Капитан очевидность подсказывает, что это нампад 0)\nNum -\nF1\nLeft Shift\nLeft Ctrl"
local hotkeysAmmoText = "{E6AFAF}Теперь введи скок пт вкидывать в пушку, когда берешь ее со склада."
--
function SE.onServerMessage(color, text)
	local medCount = 0
	local msg = " "..sampGetPlayerNickname(getID(PLAYER_PED)).." использует аптечку"
    if text:find(msg) and not text:find(' Дождитесь приёма прошлой аптечки!') and color == -1029514752 then
		cmdSetMedpacks(settings.medpacks - 1)
	elseif text:find('Вы приобрели аптечку. В Вашем инвентаре {ed66cc}(%d+)% {ffffff}аптечек!') then
		medCount = text:match('Вы приобрели аптечку. В Вашем инвентаре {ed66cc}(%d+)% {ffffff}аптечек!')
		cmdSetMedpacks(medCount)
	elseif text:find('Вы передали (.+)% (%d+)% аптечек.') and color == -65536 then
		_, medCount = text:match('Вы передали (.+)% (%d+)% аптечек.')
		settings.medpacks = settings.medpacks - medCount
		--print(medCount.." give")
		cmdSetMedpacks(settings.medpacks)
	elseif text:find('(.+)% передал Вам (%d+)% аптечек.') and color == -65536 then
		_, medCount = text:match('(.+)% передал Вам (%d+)% аптечек.')
		settings.medpacks = settings.medpacks + medCount
		--print(medCount.." take")
		cmdSetMedpacks(settings.medpacks)
	elseif text:find('Вы положили в общак: (%d+)% аптечек') and color == 869072640 then
		medCount = text:match('Вы положили в общак: (%d+)% аптечек')
		settings.medpacks = settings.medpacks - medCount
		--print(medCount.." na sklad")
		cmdSetMedpacks(settings.medpacks)
	elseif text:find('Вы взяли с общака: (%d+)% аптечек') and color == 869072640 then
		medCount = text:match('Вы взяли с общака: (%d+)% аптечек')
		sampAddChatMessage(medCount, -1)
		settings.medpacks = settings.medpacks + medCount
		--print(medCount.." na sklad")
		cmdSetMedpacks(settings.medpacks)
	elseif text:find('Вы открыли подарочный бокс! Вам выпало: {ffffff}(%d+)% аптечек') and color = 328985855 then
		medCount = text:match('(%d+)% аптечек')
		settings.medpacks = settings.medpacks + medCount
		cmdSetMedpacks(settings.medpacks)
	end
end
-- проверка в диалогах
-- 7999 диалог 24/7
-- 24350 добавление пт в дигл
-- onSendDialogResponse
-- dialogId = 7999 button = 1 listboxId = 1 input = 2. Аптечка
-- dialogId = 0
--if string.find(sampGetCurrentDialogEditboxText(), '{ffffff}Название:{FFFF00} Аптечка\n{ffffff}Описание:{7FB151} Ранен? Воспользуйся аптечкой.\n{ffffff}Количество: {139BEC}(%d+)% ед.\n') then
function SE.onShowDialog(dialogId, style, title, button1, button2, text)
	--sampAddChatMessage(dialogId, -1)
	--sampAddChatMessage(style, -1)
	if dialogId == 0 and title == "Инвентарь" then
		if string.find(sampGetDialogText(), "Название:{FFFF00} Аптечка") then
			settings.medpacks = text:match('Количество: {139BEC}(%d+)% ед.')
			print(settings.medpacks)
			cmdSetMedpacks(settings.medpacks)
		end
	end
	if autoAmmo == true and dialogId == 24350 then
		if sendOnce == false then
			sampSendDialogResponse(dialogId, 1, -1, wepAmmo[weaponId])
			--sampAddChatMessage("отправил диалог", -1)
			weaponId = 0
			autoAmmo = false
			ammoClick = false
			sendOnce = false
			ammoId = 0
			isInvOpened = false
			sampSendClickTextdraw(230)
			--sampAddChatMessage("закрыл тд", -1)
			return false
		end
	end
end

function SE.onSendDialogResponse(id, button, listboxId, input)
    --sampAddChatMessage("id = "..id.." button = "..button.." listboxId = "..listboxId.." input = "..input, -1)
	return true
end

function SE.onShowTextDraw(ID, data)
	--inRPCtext = string.format("IN: RPC.SHOWTEXTDRAW\nID: %i; text: %s", ID, data.text)
	--print("textdraw ID = "..ID.." / modelID = "..data.modelId.." / data.color = "..data.color.." / letterColor = "..data.letterColor)
	if data.modelId == ammoId and autoAmmo == true then
		if ammoClick == false then
			sampSendClickTextdraw(ID)
			ammoClick = true
		elseif data.letterColor == -12098561 and ammoClick == true then
			sampSendClickTextdraw(243)
		else
			ammoClick = false
		end
	end
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	if cfg ~= nil then
		-- commands
		sampRegisterChatCommand('setmed', cmdSetMedpacks)
		sampRegisterChatCommand('showmed', cmdShowMedpacks)
		sampRegisterChatCommand('medpos', function () showCursor(true, true) cursorActive = true end)
		sampRegisterChatCommand('mpreset', cmdMedPosReset)
		sampRegisterChatCommand("medhelp", function() sampShowDialog(0000, "{417ED6}Команды", "{ffffff}При первом заходе в игру после установки скрипта или при входе в другой аккаунт, откройте инвентарь, нажмите на аптечки и кликните по 'INFO'\n{C94D4D}Может не сработать с первого раза (не считает количество аптек), но со следующего раза все должно быть ок\n {417ED6}/sethotkeys - {ffffff}настроить хоткеи для пушек и аптечки\n {417ED6}/setmed{ffffff} - выставить значение аптек\n {417ED6}/showmed{ffffff} - показать/спрятать текстдрав с аптеками\n {417ED6}/medpos{ffffff} - переместить текстдрав с аптеками\n {417ED6}/mpreset{ffffff} - вернуть текстдрав с аптеками в дефолтное место", "Похуй", "Абсолютно", 0) end)
		sampRegisterChatCommand('sethotkeys', function() local str = string.format("{EEAD5F}Пушка\t{EEAD5F}Кнопка\t{EEAD5F}Патроны\n{E6AFAF}Desert Eagle\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}Colt\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}Ak-47\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}M4\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}Shotgun\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}Rifle\t{E6AFAF}%s\t{E6AFAF}%i\n{E6AFAF}Аптека\t{E6AFAF}%s\t{E6AFAF}ты еблан?", vkeys.id_to_name(wepHk[1]), wepAmmo[1], vkeys.id_to_name(wepHk[2]), wepAmmo[2], vkeys.id_to_name(wepHk[3]), wepAmmo[3], vkeys.id_to_name(wepHk[4]), wepAmmo[4], vkeys.id_to_name(wepHk[5]), wepAmmo[5], vkeys.id_to_name(wepHk[6]), wepAmmo[6], vkeys.id_to_name(wepHk[7]))	sampShowDialog(hotkeysDialogId, "{EEAD5F}Доступные пушки для хоткеев", str, "Выбрать", "Нахуй", DIALOG_STYLE_TABLIST_HEADERS) end)
		wepHk[1] = slot.deagle
		wepHk[2] = slot.colt
		wepHk[3] = slot.ak47
		wepHk[4] = slot.m4
		wepHk[5] = slot.shot
		wepHk[6] = slot.rifle
		wepHk[7] = slot.med
		wepAmmo[1] = ammo.deagle
		wepAmmo[2] = ammo.colt
		wepAmmo[3] = ammo.ak47
		wepAmmo[4] = ammo.m4
		wepAmmo[5] = ammo.shot
		wepAmmo[6] = ammo.rifle
		print("gun taker loaded")
	end
	sampAddChatMessage('Настроить мониторинг аптечек {C94D4D}/medhelp', 0x417ED6)
	while true do
		wait(0)
		if sampIsLocalPlayerSpawned() and activeTextdraw == false then
			if settings.showmedpacks == 1 then
				showMedCount(settings.medpacks)
			end
		end
		if wasKeyPressed(wepHk[1]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[1]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun deagle %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2358, 1)
		end
		if wasKeyPressed(wepHk[2]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[1]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun colt %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2358, 2)
		end
		if wasKeyPressed(wepHk[3]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[3]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun ak47 %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2043, 3)
		end
		if wasKeyPressed(wepHk[4]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[4]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun m4 %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2043, 4)
		end
		if wasKeyPressed(wepHk[5]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[5]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun shot %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2039, 5)
		end
		if wasKeyPressed(wepHk[6]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[6]) ~= nil and press_button == 0 then
			sampSendChat(string.format("/gun rifle %i", getID(PLAYER_PED)))
			wait(300)
			addAmmoFunc(2039, 6)
		end
		if isInvOpened == false and ammoId > 0 then
			isInvOpened = true
			sampSendChat("/inv")
		end
		if wasKeyPressed(wepHk[7]) and not sampIsChatInputActive() and not sampIsDialogActive() and vkeys.id_to_name(wepHk[7]) ~= nil and press_button == 0 then
			sampSendChat("/med")
		end
		if  cursorActive == true then
			local posx, posy = getCursorPos()
			local posXC, posYC = convertWindowScreenCoordsToGameScreenCoords(posx, posy)
			sampTextdrawSetPos(textID, posXC, posYC)
			if wasKeyPressed(0x01) then
				cursorActive = false
				showCursor(false, false)
				setTDPos(posXC, posYC)
			end
		end
		if press_button >= 1 then
			local key = getDownKeys()
			if string.len(key) > 0 and key == tonumber(0x20) then
				wepHk[press_button] = 0
				wepAmmo[press_button] = 0
				press_button = 0
				wepId = 0
				saveIni()
				freezeCharPosition(PLAYER_PED, false)
				sampAddChatMessage("Хоткея больше нет =)", 0xEEAD5F)
			end
			if string.len(key) > 0 and key ~= tonumber(0x20) and key ~= tonumber(0x1B) and isHotkeyAllowed(key, wepHk[press_button]) then
				wepId = press_button
				press_button = 0
				wepHk[wepId] = key;
				sampAddChatMessage("Ты ебанул по "..vkeys.id_to_name(wepHk[wepId]), 0xEEAD5F)
				freezeCharPosition(PLAYER_PED, false)
				if wepId ~= 7 then
					sampShowDialog(hotkeysDialogId+wepId, "{EEAD5F}"..weaponNames[wepId], hotkeysAmmoText, "Выбрать", "Закрыть", 1)
					wepId = 0
				end
			end
		end
		local result, button, list, input = sampHasDialogRespond(hotkeysDialogId) -- Это ID диалога, которого мы создали
		if result then--deagle, colt, ak47, m4, shot
			if button == 1 then -- button == 1 - Левая кнопка. (Правая = 0). list == 0 - Первая строчка. (Строки начинаются с 0)
				--sampShowDialog(hotkeysDialogId+1, "{EEAD5F}Desert Eagle", hotkeysText, "Выбрать", "Закрыть", 1)
				freezeCharPosition(PLAYER_PED, true)
				sampAddChatMessage("Ебани нужный хоткей для "..weaponNames[list+1], 0xEEAD5F)
				sampAddChatMessage("Или долбани пробел, чтобы убрать h0tK3y", 0xEEAD5F)
				press_button = list + 1
			end
		end
		local result, button, list, input = sampHasDialogRespond(hotkeysDialogId+wepId) 
		if result then--deagle
			if button == 1 then 
				if tonumber(input) > 0 and tonumber(input) <= 3000 then
					wepAmmo[wepId] = tonumber(input)
					wepId = 0
				else
					sampShowDialog(hotkeysDialogId+wepId, "{EEAD5F}"..weaponNames[wepId], hotkeysAmmoText, "Выбрать", "Закрыть", 1)
				end
			end
		end
	end
end

function showMedCount(m) 
	settings.medpacks = m
	--print("medpacks set to "..m)
	if settings.showmedpacks >= 1 then
		customTexdraw(textID, string.format("~w~medkits: %i", settings.medpacks), pos.pos_x, pos.pos_y, 3, 3, 1, 1, 0xFF000000, 0.5, 0xFF000000)
		--print("td showed in "..pos.pos_x.."/"..pos.pos_y)
		activeTextdraw = true
	end
	return true
end

function hideMedCount(textID)
	activeTextdraw = false
	sampTextdrawDelete(textID)
end

function setTDPos(posX, posY)
	pos.pos_x = posX
	pos.pos_y = posY
	saveIni()
	print("ini saved")
	sampTextdrawSetPos(textID, posX, posY)
	--print("td showed in "..posX.."/"..posY)
end

function saveIni()
	slot.deagle = wepHk[1]
	slot.colt = wepHk[2]
	slot.ak47 = wepHk[3]
	slot.m4 = wepHk[4]
	slot.shot = wepHk[5]
	slot.rifle = wepHk[6]
	slot.med = wepHk[7]
	ammo.deagle = wepAmmo[1]
	ammo.colt = wepAmmo[2]
	ammo.ak47 = wepAmmo[3]
	ammo.m4 = wepAmmo[4]
	ammo.shot = wepAmmo[5]
	ammo.rifle = wepAmmo[6]
	inicfg.save(cfg, 'med_and_ammo')
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		saveIni()
		print("ini saved")
	end
end

function cmdSetMedpacks(param)
	param = tonumber(param)
	if param ~= nil then
		if param >= 0 and param <= 999999 then
			settings.medpacks = param
			sampTextdrawSetString(textID, string.format("~w~medkits: %i", settings.medpacks))
			saveIni()
			print("ini saved")
			--print("update medpacks = " ..settings.medpacks)
		else
			sampAddChatMessage('Ебани значение от 0 до 999999', 0x417ED6)
		end
	else
		sampAddChatMessage('Пустое значение', 0x417ED6)
	end
end

function customTexdraw(td_id, td_text, x, y, td_align, td_style, td_proportional, td_shadow, td_shadowColor, td_outline, td_outlineColor)
	sampTextdrawCreate(td_id, td_text, x, y)
	sampTextdrawSetString(td_id, td_text)
	sampTextdrawSetAlign(td_id, td_align)
	sampTextdrawSetStyle(td_id, td_style)
	sampTextdrawSetProportional(td_id, td_proportional)
	sampTextdrawSetShadow(td_id, td_shadow, td_shadowColor)
	sampTextdrawSetOutlineColor(td_id, td_outline, td_outlineColor)
end

function cmdShowMedpacks()
	if settings.showmedpacks == 1 then
		settings.showmedpacks = 0
		hideMedCount(textID)
		activeTextdraw = false
	else
		settings.showmedpacks = 1
		showMedCount(settings.medpacks)
		activeTextdraw = true
	end
	--print("showmedpacks = "..settings.showmedpacks)
end

function cmdMedPosReset() 
	setTDPos(115.0, 425.0)
	sampAddChatMessage('Позиция тексдрава сброшена', 0x417ED6)
end

function getID(m)
	local _, id = sampGetPlayerIdByCharHandle(m) -- ид игрока
	return id
end

function SE.onPlayerQuit(playerId, reason)
	if playerId == getID(playerId) and settings.showmedpacks == 1 then
		hideMedCount(textID)
	end
end

function getDownKeys()
    local keyslist = ""
    local bool =false
    for k, v in pairs(vkeys) do
        if wasKeyPressed(v) and (v == VK_MENU or v == VK_CONTROL or v == VK_SHIFT or v == VK_LMENU or v == VK_RMENU or v == VK_RCONTROL or v == VK_LCONTROL or v == VK_LSHIFT or v == VK_RSHIFT) then
            if v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT then
                keyslist = v
            end
        end
        if wasKeyPressed(v) and v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT and v ~= VK_LMENU and v ~= VK_RMENU and v ~= VK_RCONTROL and v~= VK_LCONTROL and v ~= VK_LSHIFT and v ~= VK_RSHIFT then
            if tostring(keyslist):len() == 0 then
                    keyslist = v
                else
                    keyslist = keyslist .. " " .. v
            end
            bool = true
        end
    end
    return keyslist, bool
end

function isHotkeyAllowed(key, used)
	for i = 1, 6, 1 do
		if wepHk[i] == key and used ~= key then
		return false
		end
	end
	return true
end

function addAmmoFunc(aId, wepId)
	ammoClick = false
	sendOnce = false
	autoAmmo = true
	ammoId = aId
	weaponId = wepId
	isInvOpened = false
end