/// @desc Garante a câmera da room; ela não persiste, então cada room recebe uma nova.
if (instance_exists(obj_camera)) exit;

instance_create_layer(0, 0, LAYER_SYSTEMS, obj_camera);
