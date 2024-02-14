#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Math";
#import "SDL";
#import "System";
#import "String";
#import "Bucket_Array";
#import "File";
#import "Random";

#load "../modules/sl3dge-jai/module.jai";
#import,dir "../modules/sl3dge-jai/modules/jaison";

#load "game_state.jai";

#load "player.jai";
#load "transform.jai";

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
        // engine_draw();
        end_frame(frame_data);
        reset_temporary_storage();
        
        frame_end := SDL_GetPerformanceCounter();
        delta_time = cast(float)(frame_end - global_engine.frame_start) / cast(float)SDL_GetPerformanceFrequency();
    }
    vkDeviceWaitIdle(global_renderer.device);
}

#run {
    #import "Compiler";

    build_options : Build_Options_During_Compile;
    build_options.output_path = "bin";
    build_options.output_executable_name = "out";

    #if OS == .LINUX {
        // build_options.append_linker_arguments = .["/lib/gcc/x86_64-linux-gnu/12/libgcc_eh.a", "/lib/gcc/x86_64-linux-gnu/11/libstdc++.a"];
    } else #if OS == .MACOS {
        build_options.append_linker_arguments = .["-framework", "Metal", "-framework", "QuartzCore"];
    } else #if OS == .WINDOWS {
        build_options.append_linker_arguments = .["Ws2_32.lib", "Userenv.lib", "Bcrypt.lib", "d3dcompiler.lib", "libcpmt.lib"];
    }
    set_build_options_dc(build_options);
}

#run {
    shaders := string.[
        "color.frag", 
        "skinned.vert",
        "static.vert",
        "ui.vert",
        "ui.frag",];

    for shaders {
        compile_shader(it);
    }
}

#import "Process";
#import "Thread";

compile_shader :: (t: *Thread) -> s64 {
    path := cast(*string)t.data;
    output_file := tprint("%.spv", path.*);
    result := run_command("glslang", "-V", path.*, "-o", output_file, working_directory = "bin/shaders");
    return result.exit_code;
}

compile_shader :: (path: string) {
    output_file := tprint("%.spv", path);
    
    process : Process;
    create_process(*process, "glslang", "-V", path, "-o", output_file, working_directory = "../bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
}

/*

interpreter_main :: () {
    basic();

    TEST_PROGRAM := #string _ASM
    mov [0x12], 12
    mov b, [0x12]
_ASM;
    cpu := Ship_CPU.{};
    Ship_CPU.run(*cpu, TEST_PROGRAM);
    assert(cpu.memory[0x12] == 12.0, "Mov to memory");
    assert(cpu.b == 12.0, "Mov from memory");
}
*/
