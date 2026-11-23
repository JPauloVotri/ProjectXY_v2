/// @desc Inicializa a tabela global de drops; chamado uma vez pelo `obj_game`.
function loot_init() {
    /// @desc Tabela global de drops; `is_needed` tira do sorteio atributos já cheios.
    global.loot_table = [
        {
            item: obj_loot_health,
            weight: 1,
            is_needed: function(_player) {
                return _player.current_health < _player.max_health;
            }
        },
    ];
}

/// @desc Sorteia um tipo de loot útil para o player, na tabela global, pelo peso.
/// @param {Id.Instance.obj_player} _player Player usado para filtrar os atributos cheios.
/// @return {Id.Object} Objeto sorteado; `noone` quando nenhum tipo é útil.
function loot_pick_item(_player) {
    var _eligible = [];
    var _total = 0;
    var _len = array_length(global.loot_table);

    for (var _i = 0; _i < _len; _i++) {
        var _entry = global.loot_table[_i];

        if (_entry.weight <= 0) continue;
        if (!_entry.is_needed(_player)) continue;

        array_push(_eligible, _entry);
        _total += _entry.weight;
    }

    if (_total <= 0) return noone;

    var _roll = random(_total);
    var _count = array_length(_eligible);

    for (var _j = 0; _j < _count; _j++) {
        _roll -= _eligible[_j].weight;

        if (_roll < 0) return _eligible[_j].item;
    }

    return _eligible[_count - 1].item;
}

/// @desc Cria um loot no ponto indicado; o índice desloca cópias em cruz.
/// @param {Real} _x Coordenada x do ponto de origem.
/// @param {Real} _y Coordenada y do ponto de origem.
/// @param {Id.Object} _item Objeto do loot a criar.
/// @param {Real} _index Ordem do loot na mesma origem; 0 fica no centro.
/// @return {Id.Instance} Instância criada.
function loot_spawn(_x, _y, _item, _index = 0) {
    var _offset = _index == 0 ? 0 : 4;
    var _angle = _index * 90;

    return instance_create_layer(
        _x + lengthdir_x(_offset, _angle),
        _y + lengthdir_y(_offset, _angle),
        LAYER_ACTORS,
        _item
    );
}

/// @desc Rola a chance e, se passar, cria até `_count` loots úteis da tabela global.
/// @param {Real} _x Coordenada x do ponto de origem.
/// @param {Real} _y Coordenada y do ponto de origem.
/// @param {Real} _chance Chance de dropar algo, de 0 a 1.
/// @param {Real} _count Quantidade de loots sorteados quando a chance passa.
/// @return {Real} Quantidade de loots criados.
function loot_drop(_x, _y, _chance, _count = 1) {
    /// @type {Id.Instance.obj_player}
    var _player = instance_find(obj_player, 0);

    if (_player == noone) return 0;
    if (random(1) >= _chance) return 0;

    var _spawned = 0;
    var _item = noone;

    repeat (_count) {
        _item = loot_pick_item(_player);

        if (_item == noone) break;

        loot_spawn(_x, _y, _item, _spawned);
        _spawned++;
    }

    return _spawned;
}
