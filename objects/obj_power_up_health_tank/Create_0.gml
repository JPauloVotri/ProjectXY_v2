event_inherited();

/// @desc Concede um tanque de vida: +100 no máximo e +100 na vida atual.
/// @param {Id.Instance.obj_player} _player Jogador que coletou o pickup.
/// @return {Bool} true: o pickup é consumido.
on_collect = function(_player) {
    _player.grant_health_tank();

    return true;
}
