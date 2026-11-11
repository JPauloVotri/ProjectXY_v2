var _player = instance_place(x, y, obj_player);

if (_player == noone) return;
if (!on_collect(_player)) return;

instance_destroy();
