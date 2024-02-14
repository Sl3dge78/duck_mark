
#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Math";
#import "SDL";
#import "System";
#import "String";
#import "Bucket_Array";
#import "File";
#import "Random";
#import "Process";
#import "Thread";

#load "modules/sl3dge-jai/module.jai";
#import,dir "modules/sl3dge-jai/modules/jaison";

#import "jai-tracy"(IMPORT_MODE = .CLIENT, ENABLED = ENABLE_TRACY);
ENABLE_TRACY :: true;

#load "src/main.jai";
#load "src/game_state.jai";

#load "src/player.jai";
#load "src/transform.jai";

#run {
    #import "Compiler";

    build_options : Build_Options_During_Compile;
    build_options.output_path = "bin/";
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

COMPILE_SHADERS :: true;

#run {
    if !COMPILE_SHADERS return;
    shaders := string.[
        "color.frag", 
        "skinned.vert",
        "static.vert",
        "static_inst.vert",
        "ui.vert",
        "ui.frag",];

    for shaders {
        compile_shader(it);
    }
}

compile_shader :: (path: string) {
    output_file := tprint("%.spv", path);
    
    process : Process;
    create_process(*process, "glslang", "-V", path, "-o", output_file, working_directory = "bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
}