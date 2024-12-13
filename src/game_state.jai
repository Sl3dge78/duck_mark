
Input_Reader_Fn :: #type (self: *void, gs: *Game_State, event: SDL_Event);

MAX_DUCKS :: 10000;
AREA_SIZE :: 25;
INITIAL_DUCKS :: 500;
DUCKS_PER_FRAME :: 10;

Game_State :: struct {
    quad_mesh: Mesh;
    duck_mesh: Mesh;
    duck_tex: Texture;

    player: Player;

    duck_count: u32;
    instance_data_buffer: Buffer;
    material: Material;
    thread_group: Thread_Group;
    ducks_compute: *SDL_GPUComputePipeline;
}

Instance_Matrices :: struct {
    xform: Matrix4;
    inverse: Matrix4;
    velocity: Vector4;
}

Global_Compute_Data :: struct {
    delta_time: float;
    area_size: float;
}

game_state_create :: (using state: *Game_State) {

    quad_mesh = load_mesh_from_vertices(.[
        .{.{- 0.5, 0, + 0.5}, UP, .{0, 0}, .{1, 1, 1, 1}},
        .{.{+ 0.5, 0, + 0.5}, UP, .{1, 0}, .{1, 1, 1, 1}},
        .{.{+ 0.5, 0, - 0.5}, UP, .{1, 1}, .{1, 1, 1, 1}},
        .{.{- 0.5, 0, - 0.5}, UP, .{0, 1}, .{1, 1, 1, 1}},], 
        .[0, 1, 2, 0, 2, 3]);

    duck_mesh = load_mesh_from_file("res/Duck.gltf");
    duck_tex = texture_from_file("res/DuckCM.png");
    material = create_material("shaders/static_inst.vert.spv", "shaders/color.frag.spv");

    player.transform.position = .{0, 25, 75};
    duck_count = INITIAL_DUCKS;
        
    instance_data_buffer = buffer_create(MAX_DUCKS * size_of(Instance_Data), .GRAPHICS_STORAGE_READ | .COMPUTE_STORAGE_READ | .COMPUTE_STORAGE_WRITE);
    // Initialize data
    {
        mapping := buffer_map(instance_data_buffer.handle, instance_data_buffer.size);
        defer buffer_unmap(mapping);
        array : []Instance_Matrices;
        array.data = mapping.ptr;
        array.count = MAX_DUCKS;
        for *array {
            angle := 2 * PI * random_get_zero_to_one();
            dist := random_get_zero_to_one() * 5;
            it.velocity = xyzw(.{cos(angle), 0, sin(angle) } * dist, 0);
            mat := make_translation_matrix4(.{0, 25, 0}) * make_scale_matrix4(.{0.01, 0.01, 0.01});
            initial_pos := Vector3.{0, 25, 0};
            // mat := make_look_at_matrix(initial_pos, initial_pos + it.velocity.xyz, .{0, 1, 0}, false) * make_scale_matrix4(.{0.01, 0.01, 0.01});
            it.xform = transpose(mat);
            it.inverse = transpose(inverse(it.xform));
        }
    }

    ducks_compute = build_compute_pipeline("shaders/ducks.comp.spv");
}


destroy :: (using state: *Game_State) {
    destroy(*duck_mesh);
    destroy(duck_tex);
    destroy(*quad_mesh);
    destroy(instance_data_buffer);
    destroy(material);
    SDL_ReleaseGPUComputePipeline(global_renderer.device, ducks_compute);
}

game_state_input_event :: (using state: *Game_State, event: SDL_Event) {
}

game_state_update :: (using state: *Game_State, delta_time: float) {
    player_update(*state.player, state, delta_time);

    if duck_count < MAX_DUCKS && mouse_down(.LEFT) {
        console_message("Nb Ducks: %", duck_count);//, NB Vertices : %", duck_count, 2399);
        for 0..DUCKS_PER_FRAME {
            duck_count += 1;
            if duck_count >= MAX_DUCKS then break;
        }
    }

    compute_ducks(state, delta_time);
}

compute_ducks :: (using state: *Game_State, delta_time: float) {
    cmd := SDL_NullCheck(SDL_AcquireGPUCommandBuffer(global_renderer.device));
    defer SDL_Check(SDL_SubmitGPUCommandBuffer(cmd));

    buffer_bindings := SDL_GPUStorageBufferReadWriteBinding.[ 
        .{ buffer = instance_data_buffer.handle, cycle = false }
    ];
    pass := SDL_NullCheck(SDL_BeginGPUComputePass(cmd, null, 0, buffer_bindings.data, buffer_bindings.count));
    defer SDL_EndGPUComputePass(pass);

    data := Global_Compute_Data.{
        delta_time,
        AREA_SIZE,
    };

    SDL_PushGPUComputeUniformData(cmd, 0, *data, size_of(type_of(data)));
    SDL_BindGPUComputePipeline(pass, ducks_compute);
    SDL_BindGPUComputeStorageBuffers(pass, 0, *instance_data_buffer.handle, 1);
    SDL_DispatchGPUCompute(pass, duck_count, 1, 1);
}

game_state_draw :: (using state: *Game_State, frame_data: Frame_Data) {
    lights : [16]Vector4;
    lights[0] = xyzw(unit_vector(.{-1, -1, -1}), 0);

    size:: 40;
    light_proj := orthographic_projection_matrix(-size, size, -size, size, -size, size, true);
    light_view := make_look_at_matrix(.{0, 0, 0}, lights[0].xyz, .{0, 1, 0}, false);
    light_matrix := light_proj * light_view;
    view := player_get_camera_matrix(*state.player);

    matrices := Global_Matrices.{
        projection = transpose(global_renderer.projection),
        view = transpose(view),
        light = transpose(light_matrix),
        light_count = 1,
        light_vec[0] = lights[0],
    };

    shadow_matrices := matrices;
    shadow_matrices.projection = transpose(light_proj);
    shadow_matrices.view = transpose(light_view);

    {   // Shadow pass
        render_pass := SDL_NullCheck(SDL_BeginGPURenderPass(frame_data.cmd, null, 0, *global_renderer.shadowmap_target));
        defer SDL_EndGPURenderPass(render_pass);
        SDL_PushGPUVertexUniformData(frame_data.cmd, 0, *shadow_matrices, size_of(type_of(shadow_matrices)));
        draw_scene(frame_data.cmd, render_pass, .SHADOWMAP, state);
    }

    {   // Color pass
        target := create_color_target(frame_data.target, .CLEAR, clear_color = .{0, 0, 0, 1});
        render_pass := SDL_NullCheck(SDL_BeginGPURenderPass(frame_data.cmd, *target, 1, *global_renderer.depth_stencil_target));
        defer SDL_EndGPURenderPass(render_pass);

        SDL_PushGPUVertexUniformData(frame_data.cmd, 0, *matrices, size_of(type_of(matrices)));
        SDL_PushGPUFragmentUniformData(frame_data.cmd, 0, *matrices, size_of(type_of(matrices)));

        // Bind the shadowmap
        binding := SDL_GPUTextureSamplerBinding.{ global_renderer.shadowmap, global_renderer.sampler };
        SDL_BindGPUFragmentSamplers(render_pass, 0, *binding, 1);

        draw_scene(frame_data.cmd, render_pass, .COLOR, state);
    }
}

draw_scene :: (cmd: *SDL_GPUCommandBuffer, render_pass: *SDL_GPURenderPass, kind: Pipeline_Kind, using game_state: *Game_State) {
    {   // Quad
        SDL_BindGPUGraphicsPipeline(render_pass, global_renderer.static_mesh_material.pipelines[kind]);

        // Useless in shadowmap
        binding := SDL_GPUTextureSamplerBinding.{ global_renderer.empty_texture, global_renderer.sampler };
        SDL_BindGPUFragmentSamplers(render_pass, 1, *binding, 1);
        mat := make_scale_matrix4(.{AREA_SIZE * 2, 1, AREA_SIZE * 2});
        push_constants := Standard_Push_Constants.{
            transform = transpose(mat),
            inverse_transform = transpose(inverse(mat)),
        };
        SDL_PushGPUVertexUniformData(cmd, 1, *push_constants, size_of(type_of(push_constants)));
        draw(quad_mesh, render_pass);
    }

    {   // Ducks
        SDL_BindGPUGraphicsPipeline(render_pass, material.pipelines[kind]);
        SDL_BindGPUVertexStorageBuffers(render_pass, 0, *instance_data_buffer.handle, 1);
        // Useless in shadowmap
        binding := SDL_GPUTextureSamplerBinding.{ duck_tex, global_renderer.sampler };
        SDL_BindGPUFragmentSamplers(render_pass, 1, *binding, 1);
        draw(duck_mesh, render_pass, duck_count);
    }
}
