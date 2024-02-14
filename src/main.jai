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

    ZoneScoped();

    delta_time : float = 0;
    running := true;
    while running {
        FrameMark();
        global_engine.frame_start = SDL_GetPerformanceCounter();

        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT; running = false;
                case SDL_WINDOWEVENT; {
                    if event.window.event == {
                        // case SDL_WINDOWEVENT_RESIZED;
                            // Renderer.update_window(window); @TODO Migration
                    }
                }
                case; game_state_input_event(*game_state, event);
            }
        }
        
        if key_just_pressed(SDL_SCANCODE_LALT) {
            SDL_SetRelativeMouseMode(xx !(cast(bool)SDL_GetRelativeMouseMode()));
        }   

        engine_update(delta_time);
        game_state_update(*game_state, delta_time);

        frame_data := begin_frame();
        game_state_draw(*game_state, frame_data);
        end_frame(frame_data);
        reset_temporary_storage();
        
        frame_end := SDL_GetPerformanceCounter();
        delta_time = cast(float)(frame_end - global_engine.frame_start) / cast(float)SDL_GetPerformanceFrequency();
    }
    vkDeviceWaitIdle(global_renderer.device);
}
