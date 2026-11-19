-- name: Ocarina of Time System
-- description: Toque 9 melodias de Ocarina of Time e SMB1!

local lang = mod_storage_load("lang") or "pt"
local TEXT = {
    pt = {
        ok = "[Ocarina] Mod carregado! Segure L + D-Pad Baixo.",
        title = "OCARINA (B para sair)",
        notes = "Notas: ",
        played = "Voce tocou: ",
        changed = "Idioma: Portugues (PT-BR)",
        suns = "Sun's Song (Cura & Dia)",
        time = "Song of Time (Velocidade)",
        zelda = "Zelda's Lullaby (Super Pulo)",
        prelude = "Prelude of Light (Inicio)",
        smb1 = "Super Mario Bros. (1-UP + Moedas)",
        storms = "Song of Storms (Tornado)",
        saria = "Saria's Song (Invencibilidade)",
        epona = "Epona's Song (Galope Veloz)",
        bolero = "Bolero of Fire (Impulso Ardente)"
    },
    en = {
        ok = "[Ocarina] Mod loaded! Hold L + D-Pad Down.",
        title = "OCARINA (B to exit)",
        notes = "Notes: ",
        played = "You played: ",
        changed = "Language: English (EN)",
        suns = "Sun's Song (Heal & Day)",
        time = "Song of Time (Speed Boost)",
        zelda = "Zelda's Lullaby (Super Jump)",
        prelude = "Prelude of Light (Start)",
        smb1 = "Super Mario Bros. (1-UP + Coins)",
        storms = "Song of Storms (Storm Spin)",
        saria = "Saria's Song (Invincibility)",
        epona = "Epona's Song (Fast Gallop)",
        bolero = "Bolero of Fire (Fire Dash)"
    }
}

local SFX = {
    A = audio_sample_load("note_d1.ogg"),
    v = audio_sample_load("note_f.ogg"),
    [">"] = audio_sample_load("note_a.ogg"),
    ["<"] = audio_sample_load("note_b.ogg"),
    ["^"] = audio_sample_load("note_d2.ogg")
}

local active, buffer, noteTxt, songTxt, timer, curSample, welcomed = false, {}, "", "", 0, nil, false
local NOTES = {
    { btn = A_BUTTON, name = "A", p = 0.85 },
    { btn = D_CBUTTONS, name = "v", p = 1.00 },
    { btn = R_CBUTTONS, name = ">", p = 1.25 },
    { btn = L_CBUTTONS, name = "<", p = 1.40 },
    { btn = U_CBUTTONS, name = "^", p = 1.65 }
}

local SONGS = {
    { id = "suns", seq = { ">","v","^",">","v","^" }, fn = function(m) m.healCounter = 31; set_lighting_dir(0, 0); play_sound(SOUND_GENERAL_HEART_SPIN, m.marioObj.header.gfx.cameraToObject) end },
    { id = "time", seq = { ">","A","v",">","A","v" }, fn = function(m) gPlayerSyncTable[m.playerIndex].spd = 300; play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject) end },
    { id = "zelda", seq = { "<","^",">","<","^",">" }, fn = function(m) set_mario_action(m, ACT_TRIPLE_JUMP, 0); m.vel.y = 85; play_sound(SOUND_GENERAL_GRAND_STAR, m.marioObj.header.gfx.cameraToObject) end },
    { id = "prelude", seq = { "^",">","^",">","<","^" }, fn = function(m) local np = gNetworkPlayers; play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject); warp_to_level(np.currLevelNum, np.currAreaIndex, np.currActNum) end },
    { id = "smb1", seq = { "<","<","<","v","<","^","v" }, fn = function(m) m.numLives = m.numLives + 1; m.numCoins = m.numCoins + 10; play_sound(SOUND_GENERAL_COLLECT_1UP, m.marioObj.header.gfx.cameraToObject) end },
    { id = "storms", seq = { "A","v","^","A","v","^" }, fn = function(m) set_lighting_dir(1, -1); set_mario_action(m, ACT_TWIRLING, 0); m.vel.y = 75; play_sound(SOUND_GENERAL_BOWSER_BOMB_EXPLOSION, m.marioObj.header.gfx.cameraToObject) end },
    { id = "saria", seq = { "v",">","<","v",">","<" }, fn = function(m) m.invincTimer = 300; play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject) end },
    { id = "epona", seq = { "^","<",">","^","<",">" }, fn = function(m) local s = gPlayerSyncTable[m.playerIndex]; s.spd = 450; s.jmp = 450; play_sound(SOUND_GENERAL_GRAND_STAR, m.marioObj.header.gfx.cameraToObject) end },
    { id = "bolero", seq = { "v","A","v","A",">","v",">","v" }, fn = function(m) m.invincTimer = 150; set_mario_action(m, ACT_DIVE, 0); m.vel.y = 45; m.forwardVel = 85; play_sound(SOUND_MOVING_LAVA_BURN, m.marioObj.header.gfx.cameraToObject) end }
}

local function check_songs(m)
    local c = #buffer
    for _, s in ipairs(SONGS) do
        local len = #s.seq
        if c >= len then
            local ok = true
            for i = 1, len do
                if buffer[c - len + i] ~= s.seq[i] then ok = false break end
            end
            if ok then
                if curSample then audio_sample_stop(curSample) end
                songTxt = TEXT[lang][s.id]
                timer = 100
                buffer = {}
                active = false
                set_mario_action(m, ACT_IDLE, 0)
                s.fn(m)
                return
            end
        end
    end
end

local function mario_update(m)
    if m.playerIndex == 0 and not welcomed then
        welcomed = true
        djui_chat_message_create(TEXT[lang].ok)
    end
    local s = gPlayerSyncTable[m.playerIndex]
    if s.spd and s.spd > 0 then
        s.spd = s.spd - 1
        if m.forwardVel > 10 then m.forwardVel = m.forwardVel * 1.25 end
    end
    if s.jmp and s.jmp > 0 then
        s.jmp = s.jmp - 1
        if (m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP) and m.vel.y > 0 then m.vel.y = m.vel.y + 1.2 end
    end
    if m.playerIndex ~= 0 then return end
    if not active then
        if (m.controller.buttonDown & L_TRIG) ~= 0 and (m.controller.buttonPressed & D_JPAD) ~= 0 then
            if (m.action & ACT_GROUP_MASK) == ACT_GROUP_STATIONARY then
                active = true; buffer = {}; noteTxt = ""
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
            end
        end
        return
    end
    set_mario_action(m, ACT_READING_AUTOMATIC_DIALOG, 0)
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        if curSample then audio_sample_stop(curSample) end
        active = false; set_mario_action(m, ACT_IDLE, 0); return
    end
    for _, n in ipairs(NOTES) do
        if (m.controller.buttonPressed & n.btn) ~= 0 then
            table.insert(buffer, n.name)
            if #buffer > 10 then table.remove(buffer, 1) end
            noteTxt = table.concat(buffer, " ")
            if SFX[n.name] then
                if curSample then audio_sample_stop(curSample) end
                curSample = SFX[n.name]
                audio_sample_play(curSample, gLakituState.pos, 1.0)
            else
                play_sound_with_freq_scale(SOUND_MENU_CLICK_CHANGE_VIEW, m.marioObj.header.gfx.cameraToObject, n.p)
            end
            check_songs(m)
            break
        end
    end
end

local function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)
    local w, h = djui_hud_get_screen_width(), djui_hud_get_screen_height()
    if timer > 0 then
        timer = timer - 1
        djui_hud_set_color(255, 230, 50, 255)
        local t = TEXT[lang].played .. songTxt
        djui_hud_print_text(t, (w - djui_hud_measure_text(t)) / 2, 40, 1)
    end
    if active then
        djui_hud_set_color(0, 0, 0, 180)
        djui_hud_render_rect(w / 2 - 120, h - 65, 240, 45)
        djui_hud_set_color(100, 200, 255, 255)
        djui_hud_print_text(TEXT[lang].title, w / 2 - 110, h - 60, 0.7)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(TEXT[lang].notes .. noteTxt, w / 2 - 110, h - 42, 0.9)
    end
end

hook_chat_command("ocarina", "[pt|en]", function(msg)
    local a = string.lower(msg)
    if a == "pt" or a == "en" then
        lang = a; mod_storage_save("lang", lang); djui_chat_message_create(TEXT[lang].changed); return true
    end
    djui_chat_message_create("Use: /ocarina pt ou /ocarina en"); return true
end)

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
