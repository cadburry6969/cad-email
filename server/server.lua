local QBCore = exports["qb-core"]:GetCoreObject()

RegisterNetEvent("cad-email:SendInfo")
AddEventHandler("cad-email:SendInfo", function(data)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  local name = Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname
  local email = Player.PlayerData.charinfo.firstname.."_"..Player.PlayerData.charinfo.lastname.."@email.com"
  discord = data['primary'][1]
  subject = data['primary'][2]
  description = data['primary'][3]

  TriggerClientEvent("cad-email:mailsent", src, name, discord, subject, description, email)
end)

QBCore.Commands.Add('email', 'Send Email to Someone', {}, false, function(source, args)  
  TriggerClientEvent('cad-email:OpenNUI', source)
end)

-- / Made By Cadburry#7547 \ --