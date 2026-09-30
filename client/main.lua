local isOpen = false

---Shows or hides the mail window
---@param state boolean
local function setOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

---Loads the player's mail data and opens the window
local function openMail()
    if isOpen then return end

    local data = lib.callback.await('cad-email:getData', false)
    if not data then
        return lib.notify({ type = 'error', description = 'Could not load your mail. Try again.' })
    end

    SendNUIMessage({ action = 'load', data = data })
    setOpen(true)
end

---Asks the server to do something and hands the answer back to the window
---@param name string Server callback name
---@param payload any
---@param cb function NUI reply
local function forward(name, payload, cb)
    local result = lib.callback.await(name, false, payload)
    cb(result or { ok = false, message = 'The server did not reply. Try again.' })
end

RegisterCommand(Config.Command, openMail, false)
TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Open the mail app')

-- Lets other resources (phone, laptop, target) open the app: exports['cad-email']:open()
exports('open', openMail)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb(1)
end)

RegisterNUICallback('send', function(data, cb)
    local result = lib.callback.await('cad-email:send', false, data)
    cb(result or { ok = false, message = 'The server did not reply. Try again.' })

    if result then
        lib.notify({
            title = 'Mail',
            type = result.ok and 'success' or 'error',
            description = result.message,
        })
    end
end)

RegisterNUICallback('saveContact', function(data, cb)
    forward('cad-email:saveContact', data, cb)
end)

RegisterNUICallback('deleteContact', function(data, cb)
    forward('cad-email:deleteContact', data and data.id, cb)
end)

-- Give the mouse back if the resource restarts while the window is open
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
