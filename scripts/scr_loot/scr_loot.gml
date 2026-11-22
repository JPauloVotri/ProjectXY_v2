/// @desc Inicializa a tabela global de drops; chamado uma vez pelo `obj_game`.
function loot_init() {
    global.loot_table = [
        { item: obj_loot_health, weight: 1 },
    ];
}

/// @desc Sorteia um tipo de loot da tabela global pelo peso.
/// @return {Id.Object} Objeto sorteado; `noone` quando não há peso positivo.
function loot_pick_item() {
    var _total = 0;
    var _len = array_length(global.loot_table);

    for (var _i = 0; _i < _len; _i++) {
        _total += global.loot_table[_i].weight;
    }

    if (_total <= 0) return noone;

    var _roll = random(_total);

    for (var _j = 0; _j < _len; _j++) {
        _roll -= global.loot_table[_j].weight;

        if (_roll < 0) return global.loot_table[_j].item;
    }

    return global.loot_table[_len - 1].item;
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

/// @desc Rola a chance e, se passar, cria `_count` loots sorteados na tabela global.
/// @param {Real} _x Coordenada x do ponto de origem.
/// @param {Real} _y Coordenada y do ponto de origem.
/// @param {Real} _chance Chance de dropar algo, de 0 a 1.
/// @param {Real} _count Quantidade de loots sorteados quando a chance passa.
/// @return {Real} Quantidade de loots criados.
function loot_drop(_x, _y, _chance, _count = 1) {
    if (random(1) >= _chance) return 0;

    var _spawned = 0;
    var _item = noone;

    repeat (_count) {
        _item = loot_pick_item();

        if (_item == noone) break;

        loot_spawn(_x, _y, _item, _spawned);
        _spawned++;
    }

    return _spawned;
}
