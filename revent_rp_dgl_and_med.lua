script_name("get dgl + med use")
script_version_number(1)
script_description("num9 to dgl / num0 to med")
script_author("ivy")

require "lib.moonloader"
-- [00:23:45]  Вы приобрели аптечку. В Вашем инвентаре {ed66cc}5 {ffffff}аптечек!
-- настройки кфг --
local inicfg = require 'inicfg'
local cfg = inicfg.load(
	{
		general = {
			medpacks = 0,
			showmedpacks = 1,
			ammouse = 50
		},
		location = 
		{
			pos_x = 115.0,
			pos_y = 425.0
		}
	},
	'med_and_ammo'
)
local settings = cfg.general
local pos = cfg.location
-- курсор --
local cursorActive = false
-- делей на юз --
local cantUse = false
-- td id --
local textID = 500
-- проверка в чате
local medUseCheck = ""
local SE = require 'samp.events'
-- timer
local endTime = 0
-- для добавления пт
local autoAmmo = false
local ammoClick = false
local sendOnce = false
--
function SE.onServerMessage(color, text)
	local medCount = 0
	local msg = " "..sampGetPlayerNickname(getID(PLAYER_PED)).." использует аптечку"
    if text:find(msg) and not text:find(' Дождитесь приёма прошлой аптечки!') then
		cmdSetMedpacks(settings.medpacks - 1)
	elseif text:find('Вы приобрели аптечку. В Вашем инвентаре {ed66cc}(%d+)% {ffffff}аптечек!') then
		medCount = text:match('Вы приобрели аптечку. В Вашем инвентаре {ed66cc}(%d+)% {ffffff}аптечек!')
		cmdSetMedpacks(medCount)
	elseif text:find(' Вы передали (.+)% (%d+)% аптечек.') then
		_, medCount = text:match(' Вы передали (.+)% (%d+)% аптечек.')
		medCount = settings.medpacks - medCount
		--print(medCount.." give")
		cmdSetMedpacks(medCount)
	elseif text:find(' (.+)% передал Вам (%d+)% аптечек.') then
		_, medCount = text:match(' (.+)% передал Вам (%d+)% аптечек.')
		settings.medpacks = settings.medpacks + medCount
		--print(medCount.." take")
		cmdSetMedpacks(medCount)
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
			local medCount = text:match('Количество: {139BEC}(%d+)% ед.')
			cmdSetMedpacks(medCount)
		end
	end
	if autoAmmo == true and dialogId == 24350 then
		if sendOnce == false then
			sampSendDialogResponse(dialogId, 1, -1, settings.ammouse)
			--sampAddChatMessage("отправил диалог", -1)
			autoAmmo = false
			ammoClick = false
			sendOnce = false
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
	--inRPCtext = string.format("IN: RPC.SHOWTEXTDRAW\nID: %d; text: %s", ID, data.text)
	--print("textdraw ID = "..ID.." / modelID = "..data.modelId.." / data.color = "..data.color.." / letterColor = "..data.letterColor)
	if data.modelId == 2358 and autoAmmo == true then
		if ammoClick == false then
			sampSendClickTextdraw(ID)
			ammoClick = true
		else
			if data.letterColor == -12098561 then
				sampSendClickTextdraw(243)
			end
		end
	end
end
-- sampTextdrawGetModelRotationZoomVehColor
function showMedCount(m) 
	settings.medpacks = m
	--print("medpacks set to "..m)
	if settings.showmedpacks >= 1 then
		customTexdraw(textID, string.format("~w~medpacks: %i", settings.medpacks), pos.pos_x, pos.pos_y, 3, 3, 1, 1, 0xFF000000, 0.5, 0xFF000000)
		--print("td showed in "..pos.pos_x.."/"..pos.pos_y)
	end
	return true
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	if cfg ~= nil then
		-- commands
		sampRegisterChatCommand('setmed', cmdSetMedpacks)
		sampRegisterChatCommand('addammo', cmdSetAddableAmmo)
		sampRegisterChatCommand('showmed', cmdShowMedpacks)
		sampRegisterChatCommand('medpos', cmdSetMedPos)
		sampRegisterChatCommand('mpreset', cmdMedPosReset)
		sampRegisterChatCommand("medhelp", function() sampShowDialog(0000, "{417ED6}Команды", "{ffffff}При первом заходе в игру после установки скрипта или при входе в другой аккаунт, откройте инвентарь, нажмите на аптечки и кликните по 'INFO'\n{C94D4D}Может не сработать с первого раза, но потом все должно быть ок\n {417ED6}F9 - взять дигл и патроны для него\n {417ED6}/setmed{ffffff} - выставить значение аптек\n {417ED6}/showmed{ffffff} - показать/спрятать текстдрав с аптеками\n {417ED6}/medpos{ffffff} - переместить текстдрав с аптеками\n {417ED6}/mpreset{ffffff} - вернуть текстдрав с аптеками в дефолтное место\n {417ED6}/addammo{ffffff} - выставить значение сколько пт добавлять в пушку {C94D4D}(UNRELEASED)", "Похуй", "Абсолютно", 0) end)
		-- устанавливаем количество аптек и/или показываем тд с их количеством	
		showMedCount(settings.medpacks)
		print("gun taker loaded")
	end
	sampAddChatMessage('Настроить мониторинг аптечек {C94D4D}/medhelp', 0x417ED6)
	while true do
		wait(0)
		if wasKeyPressed(0x69) and not sampIsChatInputActive() then
			sampSendChat(string.format("/gun deagle %i", getID(PLAYER_PED)))
			wait(200)
			sampSendChat("/inv")
			autoAmmo = true
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
	end
end

function cmdSetMedPos()
	showCursor(true, true)
	cursorActive = true
end

function setTDPos(posX, posY)
	pos.pos_x = posX
	pos.pos_y = posY
	inicfg.save(cfg, 'med_and_ammo')
	print("ini saved")
	sampTextdrawSetPos(textID, posX, posY)
	--print("td showed in "..posX.."/"..posY)
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		inicfg.save(cfg, 'med_and_ammo')
		print("ini saved")
	end
end

function cmdSetMedpacks(param)
	param = tonumber(param)
	if param ~= nil then
		if param >= 0 or param <= 99999 then
			settings.medpacks = param
			sampTextdrawSetString(textID, string.format("~w~medpacks: %i", settings.medpacks))
			inicfg.save(cfg, 'med_and_ammo')
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
		sampTextdrawDelete(textID)
	else
		settings.showmedpacks = 1
		showMedCount(settings.medpacks)
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

function cmdSetAddableAmmo(param)
	param = tonumber(param)
	if param ~= nil then
		if param > 0 and param <= 3000 then
			--print("ammo "..param)
			settings.ammouse = param
			sampAddChatMessage('Теперь будет добавляться '..param..' пт. когда достанешься пушку', 0x417ED6)
		else
			sampAddChatMessage('А ты че охуел? Только значения в промежутке от 1 до 3000', 0x417ED6)
		end
	else
		sampAddChatMessage('Значение введи чЕл)', 0x417ED6)
	end
end