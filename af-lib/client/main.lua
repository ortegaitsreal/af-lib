-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local isProgressActive = false

-- ===== DEKLARASI GLOBAL AF =====
_G.AF = {}

-- ===== STORAGE UNTUK CALLBACK =====
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
function AF.Notify(title, text, notifType, duration, position)
    if not title or not text then
        return
    end
    
    SendNUIMessage({
        action = 'showNotification',
        data = {
            title = title,
            text = text,
            type = notifType or 'info',
            duration = duration or Config.Defaults.notification.duration,
            position = position or 'top-right'
        }
    })
end

-- ===== PROGRESS =====
function AF.Progress(label, duration, callback, isLast, canCancel)
    -- Jika progress sudah aktif
    if isProgressActive then
        SendNUIMessage({
            action = 'showProgress',
            data = {
                label = label or 'Processing...',
                duration = duration or Config.Defaults.progress.duration,
                canCancel = canCancel ~= false,
                isLast = isLast or false,
                id = _G._afProgressId
            }
        })
        
        -- Set focus agar keyboard bisa menangkap event
        SetFocus(true, false)
        
        if callback then
            local id = _G._afProgressId
            if id then
                progressCallbacks[id] = callback
            end
        end
        
        return true
    end
    
    -- Progress baru
    isProgressActive = true
    
    callbackId = callbackId + 1
    local id = callbackId
    if callback then
        progressCallbacks[id] = callback
    end
    _G._afProgressId = id
    
    SendNUIMessage({
        action = 'showProgress',
        data = {
            id = id,
            label = label or 'Processing...',
            duration = duration or Config.Defaults.progress.duration,
            canCancel = canCancel ~= false,
            isLast = isLast or false
        }
    })
    
    -- Set focus agar keyboard bisa menangkap event
    SetFocus(true, false)
    
    return true
end

-- ===== FORCE HIDE PROGRESS =====
function AF.HideProgress()
    if isProgressActive then
        isProgressActive = false
        
        -- Lepas focus
        SetFocus(false, false)
        
        if _G._afProgressTimer then
            ClearTimeout(_G._afProgressTimer)
            _G._afProgressTimer = nil
        end
        SendNUIMessage({ action = 'hideProgress' })
    end
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
            local callback = progressCallbacks[id]
            progressCallbacks[id] = nil
            callback(false)
        end
        
        SendNUIMessage({ action = 'hideProgress' })
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

RegisterNUICallback('progressComplete', function(data, cb)
    local id = data.id
    local success = data.success or false
    
    isProgressActive = false
    
    -- Lepas focus setelah progress selesai
    SetFocus(false, false)
    
    if id and progressCallbacks[id] then
        local callback = progressCallbacks[id]
        progressCallbacks[id] = nil
        callback(success)
    end
    
    cb('ok')
end)

RegisterNUICallback('progressCancel', function(data, cb)
    local id = data.id
    
    if isProgressActive then
        isProgressActive = false
        
        -- Lepas focus
        SetFocus(false, false)
        
        if _G._afProgressTimer then
            ClearTimeout(_G._afProgressTimer)
            _G._afProgressTimer = nil
        end
        
        if id and progressCallbacks[id] then
            local callback = progressCallbacks[id]
            progressCallbacks[id] = nil
            callback(false)
        end
        
        AF.Notify('Dibatalkan', 'Progress dibatalkan', 'warning')
    end
    
    cb('ok')
end)

-- ===== EXPORTS =====
exports('progress', function(label, duration, callback)
    AF.Progress(label, duration, callback, true, true)
end)
exports('notify', AF.Notify)
exports('progress', AF.Progress)
exports('dialog', AF.Dialog)
exports('menu', AF.Menu)
exports('slider', AF.Slider)

-- ========================================
-- OVERRIDE QB-CORE PROGRESSBAR
-- ========================================

CreateThread(function()
    while true do
        if QBCore and QBCore.Functions then
            break
        end
        Wait(100)
    end
    
    print('^2[AF-LIB] Overriding QB-Core Progressbar...^0')
    
    -- Simpan progressbar asli jika perlu
    local originalProgressbar = QBCore.Functions.Progressbar
    
    QBCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
        -- Konversi ke AF.Progress
        AF.Progress(label, duration, function(success)
            if success then
                if onFinish then
                    onFinish()
                end
            else
                if onCancel then
                    onCancel()
                end
            end
        end, true, canCancel) -- isLast = true, canCancel = canCancel
    end
    
    print('^2[AF-LIB] QB-Core Progressbar OVERRIDDEN dengan AF-LIB^0')
end)

-- ========================================
-- OVERRIDE QB-CORE NOTIFY
-- ========================================

CreateThread(function()
    while true do
        if QBCore and QBCore.Functions then
            break
        end
        Wait(100)
    end
    
    print('^2[AF-LIB] Overriding QB-Core Notify...^0')
    
    QBCore.Functions.Notify = function(text, texttype, length, icon)
        local title = "Info"
        local desc = text
        local notifType = "info"
        local duration = length or 3000
        
        if type(text) == "table" then
            title = text.caption or text.title or "Info"
            desc = text.text or "Notification"
        end
        
        if texttype then
            local lowerType = string.lower(texttype)
            if lowerType == "success" or lowerType == "primary" then
                notifType = "success"
                title = "Sukses"
            elseif lowerType == "error" or lowerType == "danger" then
                notifType = "error"
                title = "Error"
            elseif lowerType == "warning" then
                notifType = "warning"
                title = "Peringatan"
            elseif lowerType == "info" then
                notifType = "info"
                title = "Info"
            else
                notifType = "info"
                title = "Info"
            end
        end
        
        AF.Notify(title, desc, notifType, duration, "top-right")
    end
    
    print('^2[AF-LIB] QB-Core Notify OVERRIDDEN dengan AF-LIB^0')
end)

-- ========================================
-- COMMANDS
-- ========================================
RegisterCommand('afnotif', function()
    AF.Notify('Success', 'Lorem ipsum dolor sit amet', 'success', 5000, 'top-center')
end, false)

RegisterCommand('afnotiferror', function()
    AF.Notify('Error', 'Something went wrong', 'error', 5000, 'top-center')
end, false)

RegisterCommand('afnotifwarning', function()
    AF.Notify('Warning', 'Session will expire', 'warning', 5000, 'top-center')
end, false)

RegisterCommand('afnotifinfo', function()
    AF.Notify('Info', 'New update available', 'info', 5000, 'top-center')
end, false)

RegisterCommand('afprogress', function()
    AF.Progress('Memproses data...', 5000, function(success)
        if success then
            AF.Notify('Sukses', 'Progress selesai!', 'success')
        end
    end)
end, false)

RegisterCommand('afprogressloop', function()
    -- Simulasi progress continuous
    local total = 10
    for i = 1, total do
        AF.Progress('Memproses item [' .. i .. '/' .. total .. ']', 2000)
        Citizen.Wait(2500)
    end
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

-- Test dengan log untuk debugging
RegisterCommand('afprogresssingle', function()
    print('^2[AF-LIB] Starting single progress test^0')
    AF.Progress('Memproses data tunggal...', 5000, function(success)
        if success then
            AF.Notify('Sukses', 'Progress single selesai!', 'success')
            print('^2[AF-LIB] Progress completed successfully^0')
        else
            AF.Notify('Dibatalkan', 'Progress dibatalkan!', 'error')
            print('^1[AF-LIB] Progress cancelled by user^0')
        end
    end, true)
end, false)

-- Multi Progress Test (10 item)
RegisterCommand('afprogressmulti', function(source, args, rawCommand)
    local total = tonumber(args[1]) or 10
    local current = 0
    
    local function processNext()
        current = current + 1
        if current > total then
            AF.Notify('Selesai', 'Semua ' .. total .. ' item berhasil diproses!', 'success')
            return
        end
        
        local isLast = (current == total)
        AF.Progress('Memproses item [' .. current .. '/' .. total .. ']', 1500, function(success)
            if success then
                processNext()
            else
                AF.Notify('Gagal', 'Proses dibatalkan', 'error')
            end
        end, isLast)
    end
    
    processNext()
end, false)

RegisterNUICallback('progressCancel', function(data, cb)
    local id = data.id
    
    if isProgressActive then
        isProgressActive = false
        
        if _G._afProgressTimer then
            ClearTimeout(_G._afProgressTimer)
            _G._afProgressTimer = nil
        end
        
        if id and progressCallbacks[id] then
            local callback = progressCallbacks[id]
            progressCallbacks[id] = nil
            callback(false) -- ← Kirim false ke callback
        end
        
        SetFocus(false, false)
        AF.Notify('Dibatalkan', 'Progress dibatalkan', 'warning')
    end
    
    cb('ok')
end)

print('^2[AF-LIB] Client loaded successfully^0')