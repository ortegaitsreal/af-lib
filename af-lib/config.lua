Config = {}

Config.Defaults = {
    notification = {
        duration = 3000,
        position = 'top'
    },
    progress = {
        duration = 3000,
        canCancel = true
    },
    dialog = {
        width = 400
    },
    menu = {
        width = 350
    },
    slider = {
        min = 0,
        max = 100,
        step = 1
    }
}

-- Posisi yang tersedia:
-- top-right, top-center, top-left
-- middle-right, middle-center, middle-left
-- bottom-right, bottom-center, bottom-left

Config.Colors = {
    success = '#00d4ff',
    error = '#ff4444',
    warning = '#ffa500',
    info = '#b11414'
}