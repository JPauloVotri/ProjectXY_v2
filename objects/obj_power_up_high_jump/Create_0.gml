event_inherited();

/// @desc Multiplica o impulso do pulo: o jogador sobe mais alto.
/// @param {Id.Instance.obj_player} _player Jogador que coletou o pickup.
/// @return {Bool} true: o pickup é consumido.
on_collect = function(_player) {
    _player.grant_high_jump();

    return true;
}
