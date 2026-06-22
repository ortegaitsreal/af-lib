-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local isProgressActive = false

_G.AF = {}

local dialogCallbacks = {}
local menuCallbacks = {}
local sliderCallbacks = {}
local progressCallbacks = {}
local callbackId = 0

local focusActive = false

local function SetFocus(active, cursor)
    if focusActive == active then
        return
    end
    focusActive = active
    SetNuiFocus(active, cursor)
end

-- ===== NOTIFICATION =====
function AF.Notify(title, text, type, duration, position)
    if not title or not text then
        return
    end

    SendNUIMessage({
        action = 'showNotification',
        data = {
            title = title,
            text = text,
            type = type or 'info',
            duration = duration or Config.Defaults.notification.duration,
            position = position or 'top-right'
        }
    })
end

-- ===== PROGRESS =====
function AF.Progress(label, duration, callback)
    if isProgressActive then
        AF.Notify('Error', 'Progress sudah berjalan', 'error')
        return false
    end

    isProgressActive = true

    callbackId = callbackId + 1
    local id = callbackId
    progressCallbacks[id] = callback

    SendNUIMessage({
        action = 'showProgress',
        data = {
            id = id,
            label = label or 'Processing...',
            duration = duration or Config.Defaults.progress.duration
        }
    })

    local timer = SetTimeout(duration or Config.Defaults.progress.duration, function()
        if isProgressActive then
            isProgressActive = false
            if progressCallbacks[id] then
                progressCallbacks[id](true)
                progressCallbacks[id] = nil
            end
            SetFocus(false, false)
        end
    end)

    _G._afProgressTimer = timer
    _G._afProgressId = id

    return true
end

function AF.ProgressCancel()
    if isProgressActive then
        isProgressActive = false

        if _G._afProgressTimer then
            ClearTimeout(_G._afProgressTimer)
            _G._afProgressTimer = nil
        end

        local id = _G._afProgressId
        if id and progressCallbacks[id] then
            progressCallbacks[id](false)
            progressCallbacks[id] = nil
        end

        SetFocus(false, false)
        AF.Notify('Dibatalkan', 'Progress dibatalkan', 'warning')
    end
end

-- ===== DIALOG =====
function AF.Dialog(title, inputs, callback)
    if not inputs or type(inputs) ~= 'table' then
        return
    end

    callbackId = callbackId + 1
    local id = callbackId
    dialogCallbacks[id] = callback

    local cleanInputs = {}
    for i, input in ipairs(inputs) do
        cleanInputs[i] = {
            type = input.type or 'text',
            label = input.label or '',
            placeholder = input.placeholder or '',
            options = input.options,
            rows = input.rows,
            step = input.step,
            min = input.min,
            max = input.max
        }
    end

    SendNUIMessage({
        action = 'showDialog',
        data = {
            id = id,
            title = title or 'Input',
            inputs = cleanInputs
        }
    })

    SetFocus(true, true)
end

-- ===== MENU =====
function AF.Menu(title, options, callback)
    if not options or type(options) ~= 'table' then
        return
    end

    callbackId = callbackId + 1
    local id = callbackId
    menuCallbacks[id] = callback

    local cleanOptions = {}
    for i, opt in ipairs(options) do
        cleanOptions[i] = {
            title = opt.title or '',
            description = opt.description or '',
            icon = opt.icon or 'fa-solid fa-circle',
            value = opt.value
        }
    end

    SendNUIMessage({
        action = 'showMenu',
        data = {
            id = id,
            title = title or 'Menu',
            options = cleanOptions
        }
    })

    SetFocus(true, true)
end

-- ===== SLIDER =====
function AF.Slider(title, description, min, max, step, default, callback)
    callbackId = callbackId + 1
    local id = callbackId
    sliderCallbacks[id] = callback

    SendNUIMessage({
        action = 'showSlider',
        data = {
            id = id,
            title = title or 'Slider',
            description = description or '',
            min = min or Config.Defaults.slider.min,
            max = max or Config.Defaults.slider.max,
            step = step or Config.Defaults.slider.step,
            default = default or math.floor((min or Config.Defaults.slider.min + max or Config.Defaults.slider.max) / 2)
        }
    })

    SetFocus(true, true)
end

-- ===== NUI CALLBACKS =====
RegisterNUICallback('dialogResult', function(data, cb)
    local id = data.id
    local result = data.result

    if id and dialogCallbacks[id] then
        dialogCallbacks[id](result)
        dialogCallbacks[id] = nil
    end
    SetFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('menuResult', function(data, cb)
    local id = data.id
    local result = data.result

    if id and menuCallbacks[id] then
        menuCallbacks[id](result)
        menuCallbacks[id] = nil
    end
    SetFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('sliderResult', function(data, cb)
    local id = data.id
    local result = data.result

    if id and sliderCallbacks[id] then
        sliderCallbacks[id](result)
        sliderCallbacks[id] = nil
    end
    SetFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('progressCancel', function(data, cb)
    AF.ProgressCancel()
    cb('ok')
end)

-- ===== EXPORTS =====
exports('notify', AF.Notify)
exports('progress', AF.Progress)
exports('dialog', AF.Dialog)
exports('menu', AF.Menu)
exports('slider', AF.Slider)

-- ===== COMMANDS =====
RegisterCommand('afnotif', function()
    AF.Notify('Success', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit', 'success', 20000, 'top-center')
end, false)

RegisterCommand('afnotiferror', function()
    AF.Notify('Error', 'Something went wrong, please try again', 'error', 20000, 'top-center')
end, false)

RegisterCommand('afnotifwarning', function()
    AF.Notify('Warning', 'Your session will expire in 5 minutes', 'warning', 20000, 'top-center')
end, false)

RegisterCommand('afnotifinfo', function()
    AF.Notify('Info', 'New update available v2.0.1', 'info', 20000, 'top-center')
end, false)

RegisterCommand('afprogress', function()
    AF.Progress('Memproses data...', 20000, function(success)
        -- if success then
        --     AF.Notify('Sukses', 'Progress selesai!', 'success')
        -- end
    end)
end, false)

RegisterCommand('afdialog', function()
    AF.Dialog('Input Data', {
        {type = 'input', label = 'Nama', placeholder = 'Masukkan nama'},
        {type = 'number', label = 'Umur', placeholder = 'Masukkan umur'},
        {type = 'select', label = 'Gender', options = {'Pria', 'Wanita'}}
    }, function(result)
        if result then
            AF.Notify('Data', 'Nama: ' .. result[1] .. ', Umur: ' .. result[2] .. ', Gender: ' .. result[3], 'info')
        else
            AF.Notify('Info', 'Dialog dibatalkan', 'warning')
        end
    end)
end, false)

RegisterCommand('afmenu', function()
    AF.Menu('Pilih Kendaraan', {
        {title = 'BMW M4', description = 'Supercar | Rp5.000.000', icon = 'fa-solid fa-car', value = 'bmw'},
        {title = 'Lamborghini', description = 'Supercar | Rp5.000.000', icon = 'fa-solid fa-car', value = 'lambo'},
        {title = 'Porsche 911', description = 'Sport | Rp2.500.000', icon = 'fa-solid fa-car', value = 'porsche'}
    }, function(result)
        if result then
            AF.Notify('Dipilih', 'Kendaraan: ' .. result, 'success')
        else
            AF.Notify('Info', 'Menu dibatalkan', 'warning')
        end
    end)
end, false)

RegisterCommand('afslider', function()
    AF.Slider('Pilih Volume', 'Atur volume suara', 0, 100, 5, 0, function(result)
        if result ~= nil then
            AF.Notify('Volume', 'Volume diatur ke: ' .. result, 'success')
        else
            AF.Notify('Info', 'Slider dibatalkan', 'warning')
        end
    end)
end, false)