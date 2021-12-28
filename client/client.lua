local QBCore = exports["qb-core"]:GetCoreObject()

-- / Functions \ --
local display = false
function OpenNUI()
  if display == false then
    display = true
    SetNuiFocus(true, true)
    SendNUIMessage({show = true})
  end
end

function CloseNUI()
  display = false
  SetNuiFocus(false)
  SendNUIMessage({show = false})
end

-- / NUI \ --
RegisterNUICallback("SendInfo", function(data)
  discord = data['primary'][1]
  subject = data['primary'][2]
  description = data['primary'][3]
  if (discord == "" or subject == "" or description == "") then    
  else
    TriggerServerEvent("cad-email:SendInfo", data)    
  end
end)

RegisterNUICallback("close", function()
	CloseNUI()
end)

-- / Events \ --
RegisterNetEvent("cad-email:OpenNUI")
AddEventHandler("cad-email:OpenNUI", function()
  OpenNUI()
end)

RegisterNetEvent("cad-email:mailsent")
AddEventHandler("cad-email:mailsent", function(name, discord, subject, description, email)
	user_id = user_id  
  SendNUIMessage({type = "mail", name = name, discord = discord, subject = subject, body = description, email = email})    
  CloseNUI()
end)

-- / Made By Cadburry#7547 \ --