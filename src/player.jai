Player :: struct {
    transform: Transform;
    // physics: Physics;

    yaw: float = -PI / 2.0;
    pitch: float = PI / 2.0;
    forward : Vector3;


    EYE_HEIGHT :: 1.6;  
}

player_update :: (using player: *Player, game_state: *Game_State, delta_time: float) {

    position := transform.position;

    // Look
    LOOK_SPEED :: 0.0025;
    yaw += cast(float)(mouse_delta_x()) * LOOK_SPEED;
    yaw = fmod_cycling(yaw, 2.0 * PI);
    pitch += cast(float)(mouse_delta_y()) * LOOK_SPEED;
    pitch = clamp(pitch, 0.001, PI - 0.001);
    forward = unit_vector(xyz(sin(pitch) * cos(yaw), cos(pitch), sin(pitch) * sin(yaw)));

    look_at(*transform, forward);
    
    right := cross(forward, Vector3.{0, 1, 0});

    // Free cam
    velocity: Vector3;
    if key_down(.SDL_SCANCODE_W) then velocity += forward;
    if key_down(.SDL_SCANCODE_S) then velocity -= forward;
    if key_down(.SDL_SCANCODE_D) then velocity += right;
    if key_down(.SDL_SCANCODE_A) then velocity -= right;
    if key_down(.SDL_SCANCODE_E) then velocity += .{0, 1, 0};
    if key_down(.SDL_SCANCODE_Q) then velocity -= .{0, 1, 0};

    transform.position += velocity * 5 * delta_time;

}

player_get_camera_matrix :: (using self: *Player) -> Matrix4 {
    eye_position := transform.position + .{0, EYE_HEIGHT, 0};
    return make_look_at_matrix(eye_position, eye_position + forward, UP, false);
}
