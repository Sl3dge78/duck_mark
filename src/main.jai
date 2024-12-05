cross :: (a: Vector2, b: Vector2) -> float {
    return a.x * b.y - a.y * b.x;
}

main :: () {
    defer report_memory_leaks();
    defer log("Exit.");

    engine_create();
    defer engine_destroy();

    game_state: Game_State;
    game_state_create(*game_state);
    defer destroy(*game_state);

    delta_time : float = 0;
    running := true;
    while running {
        global_engine.frame_start = SDL_GetPerformanceCounter();

        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case .QUIT; running = false;
                case .WINDOW_RESIZED; {
                    // Renderer.update_window(window); @TODO Migration
                }
                case; game_state_input_event(*game_state, event);
            }
        }
        
        if key_just_pressed(.SDL_SCANCODE_LALT) {
            SDL_SetWindowRelativeMouseMode(global_engine.window, xx !(cast(bool)SDL_GetWindowRelativeMouseMode(global_engine.window)));
        }   

        engine_update(delta_time);
        game_state_update(*game_state, delta_time);

        render, frame_data := begin_frame();
        if render {
            game_state_draw(*game_state, frame_data);
            engine_draw(*frame_data);
            end_frame(frame_data);
        }
        reset_temporary_storage();
        
        frame_end := SDL_GetPerformanceCounter();
        delta_time = cast(float)(frame_end - global_engine.frame_start) / cast(float)SDL_GetPerformanceFrequency();
        global_engine.frame_time = delta_time;
    }
    SDL_WaitForGPUIdle(global_renderer.device);
}
