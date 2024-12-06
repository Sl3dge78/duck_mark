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
        "ui.vert",
        "ui.frag",];

    for shaders {
        compile_shader(it);
    }
}

compile_shader :: (path: string) {
    output_file := tprint("%.spv", path);
    metadata_file := tprint("%.json", path);
    
    process : Process;
    create_process(*process, "glslang", "-V", path, "-o", output_file, working_directory = "bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
    create_process(*process, "shadercross", output_file, "-o", metadata_file, working_directory = "bin/shaders", capture_and_return_output = false, arg_quoting = .QUOTE_IF_NEEDED);
}
