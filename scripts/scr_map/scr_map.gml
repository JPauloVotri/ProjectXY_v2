#macro MAP_TILE_WIDTH 320
#macro MAP_TILE_HEIGHT 180

/// @desc Atributos de mapa de uma room.
/// @param {Asset.GMRoom} _room_asset Room do GameMaker.
/// @param {Real} _tile_x Coluna global da room.
/// @param {Real} _tile_y Linha global da room.
function MapRoom(_room_asset, _tile_x, _tile_y) constructor {
    /// @type {Asset.GMRoom}
    room_asset = _room_asset;
    tile_x = _tile_x;
    tile_y = _tile_y;
}

/// @desc Tile local e global de uma posição no mapa.
/// @param {String} _room_name Nome do asset da room.
/// @param {Real} _local_x Coluna local dentro da room.
/// @param {Real} _local_y Linha local dentro da room.
/// @param {Real} _global_x Coluna global no mapa.
/// @param {Real} _global_y Linha global no mapa.
function MapTilePosition(_room_name, _local_x, _local_y, _global_x, _global_y) constructor {
    /// @type {String}
    room_name = _room_name;
    local_x = _local_x;
    local_y = _local_y;
    global_x = _global_x;
    global_y = _global_y;
}

/// @desc Tabela de atributos de mapa de cada room.
/// Cada entrada é um `MapRoom` com `room_asset`, `tile_x` e `tile_y`.
/// `tile_x` e `tile_y` são a posição da room na grade global de tiles.
/// @return {Array<Struct.MapRoom>}
function map_room_data() {
    return [
        new MapRoom(rm_room_1, 0, 0),
    ];
}

/// @desc Busca os atributos de mapa de uma room.
/// @param {Asset.GMRoom} _room_asset Room consultada.
/// @return {Struct.MapRoom,undefined} Entrada da tabela, ou `undefined`.
function map_room_attributes(_room_asset) {
    var _rooms = map_room_data();
    var _count = array_length(_rooms);

    for (var _i = 0; _i < _count; _i++) {
        if (_rooms[_i].room_asset == _room_asset) return _rooms[_i];
    }

    return undefined;
}

/// @desc Calcula o tile local e o tile global de uma posição na room atual.
/// @param {Asset.GMRoom} _room_asset Room atual.
/// @param {Real} _x X do player no mundo.
/// @param {Real} _y Y do player no mundo.
/// @return {Struct.MapTilePosition,undefined} Tiles local/global, ou `undefined`.
function map_tile_position(_room_asset, _x, _y) {
    var _attributes = map_room_attributes(_room_asset);

    if (is_undefined(_attributes)) return undefined;

    var _tiles_w = ceil(room_width / MAP_TILE_WIDTH);
    var _tiles_h = ceil(room_height / MAP_TILE_HEIGHT);
    var _local_x = clamp(floor(_x / MAP_TILE_WIDTH), 0, _tiles_w - 1);
    var _local_y = clamp(floor(_y / MAP_TILE_HEIGHT), 0, _tiles_h - 1);

    return new MapTilePosition(
        room_get_name(_attributes.room_asset),
        _local_x,
        _local_y,
        _attributes.tile_x + _local_x,
        _attributes.tile_y + _local_y
    );
}
