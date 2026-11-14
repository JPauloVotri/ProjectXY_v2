event_inherited();

/// @desc Libera um pulo extra no ar: o jogador pode pular de novo na descida.
/// @param {Id.Instance.obj_player} _player Jogador que coletou o pickup.
/// @return {Bool} true: o pickup é consumido.
on_collect = function(_player) {
    _player.grant_double_jump();

    return true;
}
