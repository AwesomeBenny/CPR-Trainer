--[[--------------------------------------------------------------------------
	*
	* Mello Trainer
	* (C) Michael Goodwin 2017
	* http://github.com/thestonedturtle/mellotrainer/releases
	*
	* This menu used the Scorpion Trainer as a framework to build off of.
	* https://github.com/pongo1231/ScorpionTrainer
	* (C) Emre Cürgül 2017
	* 
	* A lot of useful functionality has been converted from the lambda menu.
	* https://lambda.menu
	* (C) Oui 2017
	*
	* Additional Contributors:
	* WolfKnight (https://forum.fivem.net/u/WolfKnight)
	*
---------------------------------------------------------------------------]]


--[[------------------------------------------------------------

	MelloTrainer Config

--------------------------------------------------------------]]

--[[-----------------------------------------------------------
	Name: localSaving 
	Toggles the vehicle and skin saving system. 
	Options: true, false 
-------------------------------------------------------------]]
local localSaving = true

--[[-----------------------------------------------------------
	Name: steamOnly 
	Toggles steam only mode, if a player joins without a 
	steam id, it will kick them from the server.
	Options: true, false 
-------------------------------------------------------------]]
local steamOnly = true

--[[-----------------------------------------------------------
	Name: adminOnlyTrainer 
	Toggles admin only trainer, meaning only people 
	specified in the below admins table can use it. 
	Options: true, false 
-------------------------------------------------------------]]
local adminOnlyTrainer = false

--[[-----------------------------------------------------------
	Name: adminOnlyNoclip 
	Toggles if the Noclip Functionality should be
	reserved for admins only
	Options: true, false 
-------------------------------------------------------------]]
local adminOnlyNoclip = false

--[[-----------------------------------------------------------
	List of identifiers that is used to grant admin
	privledges within the trainer. MUST FOLLOW EXAMPLE FORMATS.

	How to get your Steam Hex  value:
https://forum.fivem.net/t/how-to-steam-hex-value-pictures/41071
-------------------------------------------------------------]]
local admins = {
	--"steam:11000010988531e",   -- Admin Benny
	--"steam:110000114905a96",   -- Admin JPCPT
	--"ip:0.0.0.0",            IP possible but not recommended
}










--[[------------------------------------------------------------
	Ignore below here if you don't know what you are doing
-----------------------------------------------------0--------]]




--local pvpEnabled = true
--local maxPlayers = 32

Config = {}
Config.settings = {
	
	--maxPlayers = maxPlayers,
	--pvpEnabled = pvpEnabled,
	adminOnlyTrainer = adminOnlyTrainer,
	admins = admins,
	localSaving = localSaving, 
	steamOnly = steamOnly,
	adminOnlyNoclip = adminOnlyNoclip
}


-- Get Setting from Config.settings
RegisterServerEvent("mellotrainer:getConfigSetting")
AddEventHandler("mellotrainer:getConfigSetting",function(stringname)
	local value = Config.settings[stringname]
	TriggerClientEvent("mellotrainer:receiveConfigSetting", source, stringname, value)
end)





--[[
  _    _                         __  __                                                              _   
 | |  | |                       |  \/  |                                                            | |  
 | |  | |  ___    ___   _ __    | \  / |   __ _   _ __     __ _    __ _   _ __ ___     ___   _ __   | |_ 
 | |  | | / __|  / _ \ | '__|   | |\/| |  / _` | | '_ \   / _` |  / _` | | '_ ` _ \   / _ \ | '_ \  | __|
 | |__| | \__ \ |  __/ | |      | |  | | | (_| | | | | | | (_| | | (_| | | | | | | | |  __/ | | | | | |_ 
  \____/  |___/  \___| |_|      |_|  |_|  \__,_| |_| |_|  \__,_|  \__, | |_| |_| |_|  \___| |_| |_|  \__|
                                                                   __/ |                                 
                                                                  |___/                                  
--]]



local Users = {}
-- Called whenever someone loads into the server. Users created in variables.lua
RegisterServerEvent('mellotrainer:firstJoinProper')
AddEventHandler('mellotrainer:firstJoinProper', function(id)
	local identifiers = GetPlayerIdentifiers(source)
	for i = 1, #identifiers do
		if(Users[source] == nil)then
			Users[source] = {
				name = GetPlayerName(source),
				source = id
			}
		end
	end

	TriggerClientEvent('mellotrainer:playerJoined', -1, id)
	TriggerClientEvent("mellotrainer:receiveConfigSetting", source, "adminOnlyTrainer", Config.settings.adminOnlyTrainer)
	TriggerClientEvent( "mellotrainer:receiveConfigSetting", source, "localSaving", Config.settings.localSaving )
	TriggerClientEvent( "mellotrainer:receiveConfigSetting", source, "adminOnlyNoclip", Config.settings.adminOnlyNoclip )


	-- If local saving is turned on then ensure files are created for this person.
	if(Config.settings.localSaving)then
		DATASAVE:AddPlayerToDataSave(source)
	end
end)


-- Remove User on playerDropped.
AddEventHandler('playerDropped', function()
	if(Users[source])then
		TriggerClientEvent('mellotrainer:playerLeft', -1, Users[source])
		Users[source] = nil
	end
end)







-- Admin Managment
local adminList = Config.settings.admins


--[[ Is identifier in admin list?
function isAdmin(identifier)
	local adminList = {}
	for _,v in pairs(admins) do
		adminList[v] = true
	end
	identifier = string.lower(identifier)
	identifier2 = string.upper(identifier)

	if(adminList[identifier] or adminList[identifier2])then
		return true
	else
		return false
	end
end ]]--

function isAdmin(identifier)
	local result = MySQL.Sync.fetchScalar("SELECT isAdmin FROM user_whitelist WHERE identifier = @username AND isAdmin = 1", {['@username'] = identifier})
	if result then
		return true
	end
	return false
end

-- Is user an admin? Select trainer option
RegisterServerEvent("mellotrainer:isAdmin")
AddEventHandler("mellotrainer:isAdmin",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isAdmin(identifiers[i]))then
			TriggerClientEvent("mellotrainer:adminstatus",source,true)
			found = true
			break
		end
	end
	if(not found)then
		TriggerClientEvent("mellotrainer:adminstatus",source,false)
	end
end)


-- Is user an admin?
RegisterServerEvent("mellotrainer:getAdminStatus")
AddEventHandler("mellotrainer:getAdminStatus",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isAdmin(identifiers[i]))then
			found = true
			break
		end
	end
	TriggerClientEvent("mellotrainer:adminStatusReceived",source,found)
end)

-- Cop Status
function isCop(identifier)
	local result = MySQL.Sync.fetchScalar("SELECT isCop FROM user_whitelist WHERE identifier = @username AND isCop = 1", {['@username'] = identifier})
	local result1 = MySQL.Sync.fetchScalar("SELECT isSuperMod FROM user_whitelist WHERE identifier = @username AND isSuperMod = 1", {['@username'] = identifier})
	local result2 = MySQL.Sync.fetchScalar("SELECT isAdmin FROM user_whitelist WHERE identifier = @username AND isAdmin = 1", {['@username'] = identifier})
	if (result or result1 or result2) then
		return true
	end
	return false
end

-- Is user a cop? Select trainer option
RegisterServerEvent("mellotrainer:isCop")
AddEventHandler("mellotrainer:isCop",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isCop(identifiers[i]))then
			TriggerClientEvent("mellotrainer:copstatus",source,true)
			found = true
			break
		end
	end
	if(not found)then
		TriggerClientEvent("mellotrainer:copstatus",source,false)
	end
end)

-- EMS Status
function isEMS(identifier)
	local result = MySQL.Sync.fetchScalar("SELECT isEMS FROM user_whitelist WHERE identifier = @username AND isEMS = 1", {['@username'] = identifier})
	local result1 = MySQL.Sync.fetchScalar("SELECT isSuperMod FROM user_whitelist WHERE identifier = @username AND isSuperMod = 1", {['@username'] = identifier})
	local result2 = MySQL.Sync.fetchScalar("SELECT isAdmin FROM user_whitelist WHERE identifier = @username AND isAdmin = 1", {['@username'] = identifier})
	if (result or result1 or result2) then
		return true
	end
	return false
end

-- Is user a cop? Select trainer option
RegisterServerEvent("mellotrainer:isEMS")
AddEventHandler("mellotrainer:isEMS",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isEMS(identifiers[i]))then
			TriggerClientEvent("mellotrainer:emsstatus",source,true)
			found = true
			break
		end
	end
	if(not found)then
		TriggerClientEvent("mellotrainer:emsstatus",source,false)
	end
end)

-- MOD Status
function isModerador(identifier)
	local result = MySQL.Sync.fetchScalar("SELECT isMod FROM user_whitelist WHERE identifier = @username AND isMod = 1", {['@username'] = identifier})
	local result1 = MySQL.Sync.fetchScalar("SELECT isSuperMod FROM user_whitelist WHERE identifier = @username AND isSuperMod = 1", {['@username'] = identifier})
	local result2 = MySQL.Sync.fetchScalar("SELECT isAdmin FROM user_whitelist WHERE identifier = @username AND isAdmin = 1", {['@username'] = identifier})
	if (result or result1 or result2) then
		return true
	end
	return false
end

-- Is user a Mod? Select trainer option
RegisterServerEvent("mellotrainer:isModerador")
AddEventHandler("mellotrainer:isModerador",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isModerador(identifiers[i]))then
			TriggerClientEvent("mellotrainer:modstatus",source,true)
			found = true
			break
		end
	end
	if(not found)then
		TriggerClientEvent("mellotrainer:modstatus",source,false)
	end
end)

-- IC Status
function isIC(identifier)
	local result = MySQL.Sync.fetchScalar("SELECT isIC FROM user_whitelist WHERE identifier = @username AND isIC = 1", {['@username'] = identifier})
	local result2 = MySQL.Sync.fetchScalar("SELECT isAdmin FROM user_whitelist WHERE identifier = @username AND isAdmin = 1", {['@username'] = identifier})
	if (result or result1 or result2) then
		return true
	end
	return false
end

-- Is user a Mod? Select trainer option
RegisterServerEvent("mellotrainer:isIC")
AddEventHandler("mellotrainer:isIC",function()
	local identifiers = GetPlayerIdentifiers(source)
	local found = false
	for i=1,#identifiers,1 do
		if(isIC(identifiers[i]))then
			TriggerClientEvent("mellotrainer:icstatus",source,true)
			found = true
			break
		end
	end
	if(not found)then
		TriggerClientEvent("mellotrainer:icstatus",source,false)
	end
end)