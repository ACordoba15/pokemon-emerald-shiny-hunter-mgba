-- Pokémon Emerald Shiny Starter Hunter (mGBA)
-- Author: Andres Córdoba
-- Description: Automates starter selection until shiny is found


-- ===== CONFIG =====
local PID_ADDR = 0x020244EC
local TID_SID_ADDR = 0x020244F0

function xor(a, b)
    local res = 0
    local bit = 1
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit ~= bbit then
            res = res + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return res
end

function isShiny(pid, tid, sid)
    local high = math.floor(pid / 0x10000)
    local low = pid % 0x10000

    local val = xor(xor(tid, sid), xor(high, low))

    return val < 8
end

function waitFrames(n)
    for i = 1, n do
        emu:runFrame() 
    end
end

function mashA(frames)
    for i = 1, frames do
        if i % 2 == 0 then
            -- En frames pares, presionamos A
            emu:setKeys(1) -- El bit 0 suele ser el botón A
        else
            -- En frames impares, soltamos todo
            emu:setKeys(0)
        end
        emu:runFrame()
    end
end

function press(key, duration, waitAfter)
    emu:setKeys(key)
    waitFrames(duration or 10)   -- Mantiene presionado (10 frames por defecto)
    emu:setKeys(0)               -- SUELTA el botón
    waitFrames(waitAfter or 30)  -- Espera antes de la siguiente acción
end

function choosePkm()
    emu:setKeys(0)
    -- console:log('Iniciando secuencia de Inicial...')
    
    waitFrames(600) -- Espera inicial
    
    -- console:log('PRESS A')
    press(1, 10, 100) -- Presiona A, espera un poco
    
    -- console:log('PRESS RIGHT')
    press(16, 10, 100) -- Presiona Derecha
    
    -- console:log('MASHING A...')
    -- Para avanzar diálogos y confirmar necesitas soltar y presionar
    for i = 1, 5 do
        press(1, 6, 40) -- Presiona A rápido 5 veces con pausas entre medio
    end
    waitFrames(600) -- Aparece pkm
    press(1, 2, 100) -- Presiona A rápido 5 veces con pausas entre medio
end

for i = 1, 100 do
    attempts = i
    -- console:log("Intento #" .. attempts)
    
    emu:reset()
    
    -- 🎲 RNG variation
    local delay = math.random(300, 1200)
    waitFrames(delay)

    -- Intro
    mashA(150)

    -- Elegir Pokémon
    choosePkm()

    -- Esperar batalla estable
    waitFrames(800)

    -- Leer datos
    local pid = emu:read32(PID_ADDR)

    local otid = emu:read32(TID_SID_ADDR)
    local tid = otid % 0x10000
    local sid = math.floor(otid / 0x10000)

    if pid ~= 0 and tid ~= 0 then
        if isShiny(pid, tid, sid) then
            console:log("✨ SHINY ENCONTRADO ✨ en intento " .. attempts)
            break
        else
            console:log("No shiny...")
        end
    else
        console:log("Datos inválidos...")
    end

    emu:runFrame()
end