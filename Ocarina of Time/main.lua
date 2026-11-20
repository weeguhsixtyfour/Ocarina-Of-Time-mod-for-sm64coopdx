-- name: Ocarina of Time HUD + Free Mode (ENG / PT-BR)
-- description: OoT music staff HUD with custom sounds, 9 playable songs with effects, free movement, and ENG/PT-BR support (/ocarina lang).

local idioma = "en"

local textos = {
    en = {
        modoLivre = "Free Mode (DOWN)",
        modoMusicas = "Songs Mode (L+DOWN)",
        tocou = "You played ",
        chatLivreOn = "\\#50ff50\\[Ocarina] Free Mode ENABLED! Walk and play freely.",
        chatLivreOff = "\\#ff5050\\[Ocarina] Free Mode DISABLED.",
        chatMusicasOn = "\\#ffd700\\[Ocarina] Songs Mode ENABLED! Play melodies for effects.",
        chatMusicasOff = "\\#ff5050\\[Ocarina] Songs Mode DISABLED.",
        chatLang = "\\#80d0ff\\[Ocarina] Language switched to English! (Type /ocarina lang to change)"
    },
    pt = {
        modoLivre = "Modo Livre (DOWN)",
        modoMusicas = "Modo Musicas (L+DOWN)",
        tocou = "Voce tocou ",
        chatLivreOn = "\\#50ff50\\[Ocarina] Modo Livre ATIVADO! Ande e toque livremente.",
        chatLivreOff = "\\#ff5050\\[Ocarina] Modo Livre DESATIVADO.",
        chatMusicasOn = "\\#ffd700\\[Ocarina] Modo Musicas ATIVADO! Toque melodias para ativar efeitos.",
        chatMusicasOff = "\\#ff5050\\[Ocarina] Modo Musicas DESATIVADO.",
        chatLang = "\\#80d0ff\\[Ocarina] Idioma alterado para Portugues! (Digite /ocarina lang para mudar)"
    }
}

local modoOcarina = 0
local historicoNotas = {}
local maxNotasNaTela = 8
local musicaTocadaTexto = ""
local tempoMostrarMusica = 0

local ultimoBotaoSegurado = 0
local cooldownNota = 0

local function on_ocarina_command(msg)
    if msg == "lang" or msg == "idioma" or msg == "pt" or msg == "en" then
        if msg == "pt" then
            idioma = "pt"
        elseif msg == "en" then
            idioma = "en"
        else
            idioma = (idioma == "en") and "pt" or "en"
        end
        djui_chat_message_create(textos[idioma].chatLang)
        return true
    end
    return false
end

hook_chat_command("ocarina", "[lang] - Switch language between English and Portuguese", on_ocarina_command)

local somA      = audio_sample_load("note_d1.ogg")
local somCDown  = audio_sample_load("note_f.ogg")
local somCRight = audio_sample_load("note_a.ogg")
local somCLeft  = audio_sample_load("note_b.ogg")
local somCUp    = audio_sample_load("note_d2.ogg")

local notasConfig = {
    { btn = A_BUTTON,   id = "A",  label = "A", staffY = 25, som = somA,      r = 65,  g = 150, b = 255, pitch = 1.00 },
    { btn = D_CBUTTONS, id = "CD", label = "v", staffY = 20, som = somCDown,  r = 255, g = 215, b = 40,  pitch = 1.18 },
    { btn = R_CBUTTONS, id = "CR", label = ">", staffY = 14, som = somCRight, r = 255, g = 215, b = 40,  pitch = 1.49 },
    { btn = L_CBUTTONS, id = "CL", label = "<", staffY = 9,  som = somCLeft,  r = 255, g = 215, b = 40,  pitch = 1.68 },
    { btn = U_CBUTTONS, id = "CU", label = "^", staffY = 3,  som = somCUp,    r = 255, g = 215, b = 40,  pitch = 2.00 }
}

local musicasConfig = {
    {
        nome = "Megalovania (Sans Mode)",
        seq = {"A", "A", "CU", "CR"},
        efeito = function(m)
            m.vel.y = 110.0
            m.forwardVel = 110.0
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end
    },
  
  {
        nome = "Zelda's Lullaby",
        seq = {"CL", "CU", "CR", "CL", "CU", "CR"},
        efeito = function(m)
            m.health = 0x880
        end
    },
    {
        nome = "Epona's Song",
        seq = {"CU", "CL", "CR", "CU", "CL", "CR"},
        efeito = function(m)
            m.forwardVel = 95.0
        end
    },
    {
        nome = "Saria's Song",
        seq = {"CD", "CR", "CL", "CD", "CR", "CL"},
        efeito = function(m)
            m.numCoins = m.numCoins + 10
            m.healCounter = 40
        end
    },
    {
        nome = "Sun's Song",
        seq = {"CR", "CD", "CU", "CR", "CD", "CU"},
        efeito = function(m)
            m.invincTimer = 150
        end
    },
    {
        nome = "Song of Time",
        seq = {"CR", "A", "CD", "CR", "A", "CD"},
        efeito = function(m)
            m.vel.y = 85.0
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end
    },
    {
        nome = "Song of Storms",
        seq = {"A", "CD", "CU", "A", "CD", "CU"},
        efeito = function(m)
            m.vel.y = 70.0
            set_mario_action(m, ACT_TWIRLING, 0)
        end
    },
    {
        nome = "Minuet of Forest",
        seq = {"A", "CU", "CL", "CR", "CL", "CR"},
        efeito = function(m)
            m.numLives = m.numLives + 1
            play_sound(SOUND_GENERAL_COLLECT_1UP, m.marioObj.header.gfx.cameraToObject)
        end
    },
    {
        nome = "Bolero of Fire",
        seq = {"CD", "A", "CD", "A", "CR", "CD", "CR", "CD"},
        efeito = function(m)
            m.vel.y = 95.0
            set_mario_action(m, ACT_BURNING_JUMP, 0)
        end
    },
    {
        nome = "Super Mario Bros. Theme",
        seq = {"CR", "CR", "CR", "A", "CR", "CU", "CD"},
        efeito = function(m)
            m.vel.y = 80.0
            m.forwardVel = 70.0
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end
    }
}

local function checar_musicas(m)
    for _, musica in ipairs(musicasConfig) do
        local tam = #musica.seq
        if #historicoNotas >= tam then
            local acertou = true
            for i = 1, tam do
                if historicoNotas[#historicoNotas - tam + i].id ~= musica.seq[i] then
                    acertou = false
                    break
                end
            end

            if acertou then
                play_sound(SOUND_MENU_STAR_SOUND_OKEY_DOKEY, m.marioObj.header.gfx.cameraToObject)
                musicaTocadaTexto = musica.nome
                tempoMostrarMusica = 90
                historicoNotas = {}
                if musica.efeito then musica.efeito(m) end
                return
            end
        end
    end
end

local function tocar_nota(nota, m)
    if nota.som ~= nil then
        audio_sample_play(nota.som, m.pos, 1.0)
    else
        play_sound_with_freq_scale(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject, nota.pitch)
    end

    table.insert(historicoNotas, nota)
    if #historicoNotas > maxNotasNaTela then
        table.remove(historicoNotas, 1)
    end

    if modoOcarina == 2 then
        checar_musicas(m)
    end
end

local function on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    local pressed = m.controller.buttonPressed
    local down = m.controller.buttonDown
    local t = textos[idioma]

    if cooldownNota > 0 then
        cooldownNota = cooldownNota - 1
    end

    if (pressed & D_JPAD) ~= 0 then
        if (down & L_TRIG) ~= 0 then
            if modoOcarina == 2 then
                modoOcarina = 0
                djui_chat_message_create(t.chatMusicasOff)
            else
                modoOcarina = 2
                djui_chat_message_create(t.chatMusicasOn)
            end
        else
            if modoOcarina == 1 then
                modoOcarina = 0
                djui_chat_message_create(t.chatLivreOff)
            else
                modoOcarina = 1
                djui_chat_message_create(t.chatLivreOn)
            end
        end
        historicoNotas = {}
        ultimoBotaoSegurado = 0
        return
    end

    if modoOcarina == 0 then return end

    if ultimoBotaoSegurado ~= 0 and (down & ultimoBotaoSegurado) == 0 then
        ultimoBotaoSegurado = 0
    end

    for _, nota in ipairs(notasConfig) do
        if (pressed & nota.btn) ~= 0 and ultimoBotaoSegurado ~= nota.btn and cooldownNota == 0 then
            tocar_nota(nota, m)
            ultimoBotaoSegurado = nota.btn
            cooldownNota = 4
            break
        end
    end

    if (down & A_BUTTON) ~= 0 or (pressed & A_BUTTON) ~= 0 then
        m.controller.buttonPressed = m.controller.buttonPressed & ~A_BUTTON
        m.controller.buttonDown = m.controller.buttonDown & ~A_BUTTON
    end

    m.controller.buttonPressed = m.controller.buttonPressed & ~(U_CBUTTONS | D_CBUTTONS | L_CBUTTONS | R_CBUTTONS)
    m.controller.buttonDown = m.controller.buttonDown & ~(U_CBUTTONS | D_CBUTTONS | L_CBUTTONS | R_CBUTTONS)
end

local function on_hud_render()
    if modoOcarina == 0 then return end

    local t = textos[idioma]

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local screenW = djui_hud_get_screen_width()
    local screenH = djui_hud_get_screen_height()

    local staffW = 220
    local staffH = 34
    local staffX = (screenW - staffW) / 2
    local staffY = screenH - 52

    djui_hud_set_color(0, 0, 0, 140)
    djui_hud_render_rect(staffX - 6, staffY - 4, staffW + 12, staffH + 8)

    for linha = 0, 3 do
        local lineY = staffY + 5 + (linha * 8)
        if modoOcarina == 2 then
            djui_hud_set_color(255, 220, 100, 170)
        else
            djui_hud_set_color(200, 220, 255, 150)
        end
        djui_hud_render_rect(staffX, lineY, staffW, 1)
    end

    djui_hud_set_color(255, 90, 70, 255)
    djui_hud_print_text("&", staffX + 4, staffY + 5, 0.75)

    djui_hud_set_color(255, 255, 255, 200)
    if modoOcarina == 1 then
        djui_hud_print_text(t.modoLivre, staffX, staffY - 13, 0.30)
    else
        djui_hud_print_text(t.modoMusicas, staffX, staffY - 13, 0.30)
    end

    if tempoMostrarMusica > 0 then
        tempoMostrarMusica = tempoMostrarMusica - 1
        djui_hud_set_color(255, 230, 60, 255)
        djui_hud_print_text(t.tocou .. musicaTocadaTexto .. "!", staffX + 75, staffY - 13, 0.32)
    end

    local startX = staffX + 26
    for i, nota in ipairs(historicoNotas) do
        local noteX = startX + ((i - 1) * 23)
        local noteY = staffY + nota.staffY

        djui_hud_set_color(nota.r, nota.g, nota.b, 255)
        djui_hud_render_rect(noteX, noteY, 10, 10)

        djui_hud_set_color(20, 20, 20, 255)
djui_hud_print_text(nota.label, noteX + 2, noteY, 0.32)
end
end
hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
-- FIM DO SCRIPT
