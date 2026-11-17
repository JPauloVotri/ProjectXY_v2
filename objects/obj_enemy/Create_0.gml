event_inherited();

#region Vida
    /// @desc Vida máxima; quem sobrescreve redefine `current_health` junto no próprio Create.
    MAX_HEALTH = 1;

    /// @desc Vida atual; `health` é global embutida do GM e seria compartilhada.
    current_health = MAX_HEALTH;
#endregion

#region Defesa
    /// @desc Nenhum dano fere, de nenhuma fonte.
    INVINCIBLE = false;

    /// @desc Dano mínimo que fere: o acerto só vale com `_amount` igual ou acima disto.
    DAMAGE_THRESHOLD = 1;
#endregion

#region Hooks
    /// @desc Roda uma vez com a vida em zero, antes da instância morrer.
    on_death = function() {}
#endregion

#region Dano
    /// @desc Frames do branquejar do último acerto que feriu.
    HURT_FLASH_FRAMES = 30;

    /// @desc Frames entre as trocas do branquejar.
    HURT_FLASH_INTERVAL = 3;

    hurt_time = 0;

    /// @desc Desconta a vida e mata ao zerar; acerto bloqueado não deixa marca visual.
    /// @param {Real} _amount Dano do acerto.
    /// @return {Bool} `true` quando a vida desceu.
    take_damage = function(_amount) {
        if (current_health <= 0) return false;
        if (INVINCIBLE) return false;
        if (_amount < DAMAGE_THRESHOLD) return false;

        current_health = max(current_health - _amount, 0);

        if (current_health == 0) {
            on_death();
            instance_destroy();

            return true;
        }

        hurt_time = HURT_FLASH_FRAMES;

        return true;
    }

    /// @desc Desconta um frame do branquejar do último acerto que feriu.
    update_hurt = function() {
        if (hurt_time <= 0) return;

        hurt_time--;
    }

    /// @desc Verdadeiro nos frames em que o acerto desenha o corpo todo branco.
    /// @return {Bool}
    is_flashing = function() {
        return hurt_time > 0 && (hurt_time div HURT_FLASH_INTERVAL) % 2 == 1;
    }
#endregion
