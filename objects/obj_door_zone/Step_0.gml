if (!instance_exists(obj_player)) exit;

if (!place_meeting(x, y, obj_player)) {
    armed = true;

    exit;
}

if (!armed) exit;
if (obj_player.is_dead()) exit;

obj_player.travel_to(target_room, target_door);
