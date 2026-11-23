if (invincible_time > 0 && (invincible_time div BLINK_INTERVAL) % 2 == 0) return;

draw_sprite_ext(
    legs_sprite,
    legs_frame,
    x,
    y,
    image_xscale,
    1,
    0,
    c_white,
    1
);

draw_sprite_ext(
    spr_player_torso,
    torso_frame,
    x,
    y + torso_offset_y,
    image_xscale,
    1,
    0,
    c_white,
    1
);

if (muzzle_flash_time > 0) {
    draw_sprite_ext(
        spr_muzzle_flash,
        muzzle_flash_frame,
        x + muzzle_flash_offset.x,
        y + muzzle_flash_offset.y,
        image_xscale,
        muzzle_flash_yscale,
        0,
        c_white,
        1
    );
}
