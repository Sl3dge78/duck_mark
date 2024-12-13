#import "Compiler";
#import "Process";
#import "Basic";

#run {
    set_build_options_dc(.{do_output = false});
    shaders := string.[
        "color.frag", 
        "skinned.vert",
        "static.vert",
        "static_inst.vert",
        "noop.frag",
        "ducks.comp",
        "ui.vert",
        "ui.frag",];

    for shaders {
        compile_shader(it);
    }
}

compile_shader :: (path: string) {
    output_file := tprint("%.spv", path);
    metadata_file := tprint("%.json", path);
    
    run_command("glslang", "-V", path, "-o", output_file, working_directory = "bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
    log("% > %", path, output_file);
    run_command("shadercross", output_file, "-o", metadata_file, working_directory = "bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
    log("% > %", path, metadata_file);
}
