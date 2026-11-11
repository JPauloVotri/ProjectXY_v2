event_inherited();

/// @desc Anula a fricção: a água deixa de escalar a física.
/// @param {Id.Instance} _player Jogador que coletou o pickup.
/// @return {Bool} true: o pickup é consumido.
on_collect = function(_player) {
    _player.grant_frictionless();

    return true;
}
