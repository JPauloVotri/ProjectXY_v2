event_inherited();

image_speed = 1;

#region Tempo de vida
    /// @desc 10 segundos em passos de jogo; o Alarm 0 destrói o loot.
    alarm[0] = 10 * game_get_speed(gamespeed_fps);
#endregion

#region Cura
    /// @desc Vida recuperada por unidade coletada.
    HEAL_AMOUNT = 10;

    /// @desc Aplica a cura possível e sempre consome o loot, mesmo com a vida cheia.
    /// @param {Id.Instance.obj_player} _player Jogador que coletou o loot.
    /// @return {Bool} `true` para sempre consumir o loot.
    on_collect = function(_player) {
        _player.restore_health(HEAL_AMOUNT);

        return true;
    }
#endregion
