#import "Compiler";
#import "Basic";

get_plugin :: () -> *Metaprogram_Plugin {
    log("Get plugin");
    p := New(Metaprogram_Plugin);

    p.message = message;
    return p;
}

#scope_file
all_tests : [..]string;

message :: (p: *Metaprogram_Plugin, message: *Message) {
    if message.kind == .TYPECHECKED {
        get_test_procedures(xx message);
    }
    if message.kind == .PHASE {
        phase : *Message_Phase = xx message;
        if phase.phase == .TYPECHECKED_ALL_WE_CAN {
            add_build_string(get_test_call(all_tests));
        }
    }
}

get_test_procedures :: (message: *Message_Typechecked) {
    for message.procedure_headers {
        proc := it.expression;
        for note : proc.notes {
            if note.text == "Test" {
                array_add(*all_tests, proc.name);
            }
        }
    }
}

get_test_call :: (all_tests: []string) -> string {
    builder : String_Builder;
    print_to_builder(*builder, "#run {\n");
    print_to_builder(*builder, "#load \"src/main.jai\";");
    print_to_builder(*builder, "Debug:: #import \"Debug\";");
    print_to_builder(*builder, "context.assertion_failed = Debug.print_assert;\n");
    print_to_builder(*builder, "test_ok := 0;\n");
    for all_tests {
        print_to_builder(*builder, "log(\"Testing: %\");\n", it);
        print_to_builder(*builder, "if %() == false {\n", it);
        print_to_builder(*builder, "log(\"Test failed: %.\");\n", it);
        print_to_builder(*builder, "} else { test_ok += 1;}");
    }
    print_to_builder(*builder, "log(\"% tests completed. Ok: %%, Failed: %%.\", test_ok, % - test_ok);\n", all_tests.count, all_tests.count);
    print_to_builder(*builder, "}\n");

    return builder_to_string(*builder);
}
