
#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Math";
#import "System";
#import "String";
#import "Bucket_Array";
#import "File";
#import "Random";
#import "Thread";

#import "sl3dge-jai"(BACKEND="SDL_GPU");
#import,dir "modules/sl3dge-jai/modules/jaison";

// #import "jai-tracy"(IMPORT_MODE = .CLIENT, ENABLED = ENABLE_TRACY);
// ENABLE_TRACY :: true;
#load "src/main.jai";
#load "src/game_state.jai";

#load "src/player.jai";
#load "src/transform.jai";

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

