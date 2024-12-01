
Input_Reader_Fn :: #type (self: *void, gs: *Game_State, event: SDL_Event);

PARALLEL_DUCKS :: 1000;
MAX_DUCKS :: 10000;
AREA_SIZE :: 25;
INITIAL_DUCKS :: 500;
DUCKS_PER_FRAME :: 10;

Game_State :: struct {
    font16: Font;
    // shadowmap_finished_semaphore: VkSemaphore;

    // quad_mesh: Mesh;

    // duck_mesh: Mesh;
    // duck_tex: Texture;
    // duck_desc: VkDescriptorSet;

    player: Player;

    ducks: [..]Duck;

    // instance_set_layout: VkDescriptorSetLayout;
    // instance_data_desc_set : VkDescriptorSet;
    // instance_data_buffer: Buffer;

    // material: Material;

    thread_group: Thread_Group;
}

Duck :: struct {
    position: Vector3;
    velocity: Vector3;
}

// create_material :: (instance_set_layout: VkDescriptorSetLayout) -> Material {
//     result: Material;

//     vtx := create_shader_module(global_renderer.device, "shaders/static_inst.vert.spv");
//     defer vkDestroyShaderModule(global_renderer.device, vtx, null);

//     frag := create_shader_module(global_renderer.device, "shaders/color.frag.spv");
//     defer vkDestroyShaderModule(global_renderer.device, frag, null);

//     {   // Shadowmap   
//         builder: Pipeline_Builder;
//         Pipeline_Builder.add_descriptor_set_layouts(*builder, 
//             global_renderer.camera_set_layout,
//             global_renderer.empty_set_layout,
//             global_renderer.empty_set_layout,
//             instance_set_layout);
//         Pipeline_Builder.add_vertex_input(*builder, Standard_Vertex);
//         Pipeline_Builder.add_shader(*builder, .VERTEX_BIT, vtx, "main");
//         Pipeline_Builder.rasterization_state_depth_bias(*builder, 1.25, 0, 1.75);
//         Pipeline_Builder.viewport_state(*builder, Renderer.SHADOWMAP_SIZE, Renderer.SHADOWMAP_SIZE);
//         Pipeline_Builder.depth_format(*builder, Renderer.SHADOWMAP_FORMAT);
//         Pipeline_Builder.set_push_constants(*builder, .VERTEX_BIT, size_of(Standard_Push_Constants));
//         result.pipelines[Pipeline_Kind.SHADOWMAP] = Pipeline_Builder.build(*builder, global_renderer.device);
//         log("Shadowmap pipeline created.");
//     }

//     {   // Color   
//         builder: Pipeline_Builder;
//         Pipeline_Builder.add_descriptor_set_layouts(*builder, 
//             global_renderer.camera_set_layout,
//             global_renderer.shadowmap_layout,
//             global_renderer.single_texture_layout,
//             instance_set_layout);
//         Pipeline_Builder.add_vertex_input(*builder, Standard_Vertex);
//         Pipeline_Builder.add_shader(*builder, .VERTEX_BIT, vtx, "main");
//         Pipeline_Builder.add_shader(*builder, .FRAGMENT_BIT, frag, "main");
//         Pipeline_Builder.add_dynamic_state(*builder, .VIEWPORT, .SCISSOR);
//         Pipeline_Builder.color_format(*builder, global_renderer.swapchain.format.format);
//         Pipeline_Builder.depth_format(*builder, Renderer.DEPTH_FORMAT);
//         Pipeline_Builder.set_push_constants(*builder, .VERTEX_BIT, size_of(Standard_Push_Constants));
//         result.pipelines[Pipeline_Kind.COLOR] = Pipeline_Builder.build(*builder, global_renderer.device);
//         log("Color pipeline created.");
//     }
//     return result;
// }

game_state_create :: (using state: *Game_State) {
    // font16 = font_from_file("res/font.ttf", 16);

    // quad_mesh = load_mesh_from_vertices(.[
    //     .{.{- 0.5, 0, + 0.5}, UP, .{0, 0}, .{1, 1, 1, 1}},
    //     .{.{+ 0.5, 0, + 0.5}, UP, .{1, 0}, .{1, 1, 1, 1}},
    //     .{.{+ 0.5, 0, - 0.5}, UP, .{1, 1}, .{1, 1, 1, 1}},
    //     .{.{- 0.5, 0, - 0.5}, UP, .{0, 1}, .{1, 1, 1, 1}},], 
    //     .[0, 1, 2, 0, 2, 3]);

    // duck_mesh = load_mesh_from_file("res/Duck.gltf");
    // duck_tex = texture_from_file("res/DuckCM.png");
    // duck_desc = create_texture_descriptor_set(duck_tex);


    // array_reserve(*ducks, MAX_DUCKS);
    // for 0..INITIAL_DUCKS - 1 {
    //     duck := new_duck();
    //     array_add(*ducks, duck);
    // }

    // player.transform.position = .{0, 25, 75};
        

    // instance_data_buffer = buffer_create(MAX_DUCKS * size_of(Instance_Data), .STORAGE_BUFFER_BIT, "Instance data");
    // instance_set_layout = create_descriptor_set_layout(global_renderer.device, .[.{
    //     binding = 0,
    //     descriptorType = .STORAGE_BUFFER,
    //     descriptorCount = 1,
    //     stageFlags = .VERTEX_BIT,
    // }]);
    // material = create_material(instance_set_layout);

    // alloc_info := VkDescriptorSetAllocateInfo.{
    //     descriptorPool = global_renderer.descriptor_pool,
    //     descriptorSetCount = 1,
    //     pSetLayouts = *instance_set_layout,
    // };
    // Vk_Check(vkAllocateDescriptorSets(global_renderer.device, *alloc_info, *instance_data_desc_set));
    // update_instance_data_buffer(state);

    num_cpus := get_number_of_processors() / 2;
    num_threads := max(num_cpus - 1, 2);
    thread_group.logging = false;
    init(*thread_group, num_threads, update_duck);
    start(*thread_group);
}

update_instance_data_buffer :: (using self: *Game_State) {
    // buffer_info := VkDescriptorBufferInfo.{
    //     buffer = instance_data_buffer.handle,
    //     offset = 0,
    //     range = instance_data_buffer.size,
    // };

    // writes := VkWriteDescriptorSet.[.{
    //     dstSet = instance_data_desc_set,
    //     dstBinding = 0,
    //     dstArrayElement = 0,
    //     descriptorType = .STORAGE_BUFFER,
    //     descriptorCount = 1,
    //     pBufferInfo = *buffer_info
    // }];
    // vkUpdateDescriptorSets(global_renderer.device, writes.count, writes.data, 0, null);

}

new_duck :: () -> Duck {
    vel := .{
        1 - 2 * random_get_zero_to_one(), 
        0,
        // 1 - 2 * random_get_zero_to_one(), 
        1 - 2 * random_get_zero_to_one(), 
    } * 5;
    return .{.{0, 25, 0}, vel};
}

destroy :: (using state: *Game_State) {
    // vkDestroySemaphore(global_renderer.device, shadowmap_finished_semaphore, null);
    // destroy(*duck_mesh);
    // destroy(*duck_tex);
    // destroy(duck_desc);
    // destroy(*instance_data_buffer);
    // destroy(instance_set_layout);
    // destroy(*material);
    shutdown(*thread_group);
}

game_state_input_event :: (using state: *Game_State, event: SDL_Event) {
}

Instance_Matrices :: struct {
    xform: Matrix4;
    inverse: Matrix4;
}

Duck_In_Out_Data :: struct {
    nb: u32;
    offset: u32;
    delta_time: float;
    ducks: []Duck;
    buffer: []Instance_Matrices;
}

update_duck :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
    duck_data := cast(*Duck_In_Out_Data)work;

    for *duck_data.ducks {
        it.position += (it.velocity * duck_data.delta_time);
        if it.position.x > AREA_SIZE { 
            it.position.x = AREA_SIZE;
            it.velocity.x *= -1;
        } else if it.position.x < -AREA_SIZE {
            it.position.x = -AREA_SIZE;
            it.velocity.x *= -1;
        }

        if it.position.y < 0 {
            it.velocity.y *= -1;
            it.position.y = 0;
        }

        if it.position.z > AREA_SIZE { 
            it.position.z = AREA_SIZE;
            it.velocity.z *= -1;
        } else if it.position.z < -AREA_SIZE {
            it.position.z = -AREA_SIZE;
            it.velocity.z *= -1;
        }

        it.velocity.y -= 9.81 * duck_data.delta_time;

        it.velocity *= 0.999; // damp

        mat := make_translation_matrix4(it.position) * make_scale_matrix4(.{0.01, 0.01, 0.01});
        duck_data.buffer[it_index].xform = transpose(mat); 
        duck_data.buffer[it_index].inverse = transpose(inverse(mat));
    }

    return .CONTINUE;
}

update_ducks :: (using state: *Game_State, delta_time: float) {
    // buf_ptr := buffer_map(*instance_data_buffer);
    // defer buffer_unmap(*instance_data_buffer);
    buf_ptr := null;

    i := 0;
    work_count := 0;
    while i < ducks.count {
        work := New(Duck_In_Out_Data,, temp);
        end := min(i + PARALLEL_DUCKS, ducks.count);
        work.nb = xx (end - i);

        work.offset = xx i;

        work.delta_time = delta_time;
        work.ducks.data = ducks.data + i;
        work.ducks.count = work.nb;

        work.buffer.data = buf_ptr + i * size_of(Instance_Matrices);
        work.buffer.count = work.nb;

        add_work(*thread_group, work, tprint("% - %", i, end));
        i += work.nb;
        work_count += 1;
    }

    // Wait for the threads to finish
    while work_count > 0 {
        sleep_milliseconds(1);
        results := get_completed_work(*thread_group);

        for results {
            // data := cast(*Duck_In_Out_Data) it;

            // for 0..data.nb - 1 {
            //     ducks[it + data.offset] = data.ducks[it];
            // }
        }

        work_count -= results.count;
    }
}

game_state_update :: (using state: *Game_State, delta_time: float) {
    player_update(*state.player, state, delta_time);

    if ducks.count < MAX_DUCKS && mouse_down(.LEFT) {
        for 0..DUCKS_PER_FRAME {
            duck := new_duck();
            array_add(*ducks, duck);
            if ducks.count >= MAX_DUCKS then break;
        }
        console_message("NB Ducks: %", ducks.count);
    }

    // update_ducks(state, delta_time,, logger = runtime_support_default_logger);
}

/*
game_state_draw :: (using state: *Game_State, frame_data: *Frame_Data) {
    render_pass_3d(state, frame_data);
}

render_pass_3d :: (using state: *Game_State, frame_data: *Frame_Data) {

    command_buffers: [2] VkCommandBuffer;

    alloc_info := VkCommandBufferAllocateInfo.{
        commandPool = global_renderer.command_pool,
        level = .PRIMARY,
        commandBufferCount = 2,
    };
    Vk_Check(vkAllocateCommandBuffers(global_renderer.device, *alloc_info, command_buffers.data));

    begin_info := VkCommandBufferBeginInfo.{
        flags = .ONE_TIME_SUBMIT_BIT,
    };
    for command_buffers {
        Vk_Check(vkBeginCommandBuffer(it, *begin_info));
    }
    
     {   // Update uniforms
        lights : [16]Vector4;
        lights[0] = xyzw(unit_vector(.{-1, -1, -1}), 0);

        size:: 20;
        light_proj := orthographic_projection_matrix(size, -size, -size, size, -size, size, true);
        light_view := make_look_at_matrix(.{0, 0, 0}, lights[0].xyz, .{0, 1, 0}, false);
        view := player_get_camera_matrix(*state.player);

        matrices := Global_Matrices.{
            projection = transpose(global_renderer.projection),
            view = transpose(view),
            light = transpose(light_proj * light_view),
            light_count = 1,
            light_vec = lights,
        };
        uniform_buffer_write(*frame_data.camera_descriptor, *matrices);

        shadowmap_matrices := Global_Matrices.{
            projection = transpose(light_proj),
            view = transpose(light_view),
            light = matrices.light,
            light_vec = matrices.light_vec
        };
        uniform_buffer_write(*frame_data.shadowmap_camera_descriptor, *shadowmap_matrices);
    }

    // Begin render pass
    {   // Shadowmap
        transition_texture_layout(*global_renderer.shadowmap_texture, .UNDEFINED, .DEPTH_STENCIL_ATTACHMENT_OPTIMAL, command_buffers[0]);
        depth_attachment := VkRenderingAttachmentInfo.{
            imageView = global_renderer.shadowmap_texture.view, 
            imageLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            loadOp = .CLEAR,
            storeOp = .STORE,
            clearValue = .{depthStencil = .{1, 0}},
        };
        rendering_info := VkRenderingInfo.{
            renderArea = .{
                offset = .{0, 0},
                extent = .{Renderer.SHADOWMAP_SIZE, Renderer.SHADOWMAP_SIZE}, 
            },
            layerCount = 1,
            colorAttachmentCount = 0,
            pDepthAttachment = *depth_attachment,
        };
        vkCmdBeginRendering(command_buffers[0], *rendering_info);
    }
    
    {   // Color
        prepare_framebuffer(command_buffers[1], frame_data);
        transition_texture_layout(*global_renderer.shadowmap_texture, .DEPTH_STENCIL_ATTACHMENT_OPTIMAL, .SHADER_READ_ONLY_OPTIMAL, command_buffers[1]);
        depth_attachment := VkRenderingAttachmentInfo.{
            imageView = global_renderer.swapchain.depth_texture.view, 
            imageLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            loadOp = .CLEAR,
            storeOp = .STORE,
            clearValue = .{depthStencil = .{1, 0}},
        };
        color_attachment := VkRenderingAttachmentInfo.{
            imageView = frame_data.framebuffer.view,
            imageLayout = .COLOR_ATTACHMENT_OPTIMAL,
            loadOp = .LOAD,
            storeOp = .STORE,
            clearValue = .{color = .{ _float32 = .[0, 0, 0, 1]}},
        };
        rendering_info := VkRenderingInfo.{
            renderArea = .{
                offset = .{0, 0},
                extent = .{xx frame_data.framebuffer.w, xx frame_data.framebuffer.h}, 
            },
            layerCount = 1,
            colorAttachmentCount = 1,
            pColorAttachments = *color_attachment, 
            pDepthAttachment = *depth_attachment,
        };
        vkCmdBeginRendering(command_buffers[1], *rendering_info);
    }

    {
        command_buffer := command_buffers[0];
        // Quad
        layout := global_renderer.static_mesh_material.shadowmap.layout;
        bind_material(command_buffer, global_renderer.static_mesh_material, .SHADOWMAP);
        set_push_constants(make_scale_matrix4(.{AREA_SIZE * 2, 1, AREA_SIZE * 2}), command_buffer, layout);
        draw(quad_mesh, command_buffer);

        layout = state.material.shadowmap.layout;
        bind_material(command_buffer, state.material, .SHADOWMAP);
        vkCmdBindDescriptorSets(command_buffer, .GRAPHICS, layout, 3, 1, *instance_data_desc_set, 0, null);
        draw_instances(duck_mesh, command_buffer, xx ducks.count);
    }

    {
        command_buffer := command_buffers[1];

        // Quad
        layout := global_renderer.static_mesh_material.color.layout;
        bind_material(command_buffer, global_renderer.static_mesh_material, .COLOR);
        set_push_constants(make_scale_matrix4(.{AREA_SIZE * 2, 1, AREA_SIZE * 2}), command_buffer, layout);
        bind_diffuse(global_renderer.empty_texture_descriptor_set, command_buffer, layout);
        draw(quad_mesh, command_buffer);

        layout = state.material.color.layout;
        bind_material(command_buffer, state.material, .COLOR);
        vkCmdBindDescriptorSets(command_buffer, .GRAPHICS, layout, 3, 1, *instance_data_desc_set, 0, null);
        bind_diffuse(duck_desc, command_buffer, layout);
        draw_instances(duck_mesh, command_buffer, xx ducks.count);
    }

    for command_buffers {
        vkCmdEndRendering(it);
    }

    engine_draw(*frame_data.framebuffer, command_buffers[1]);

    end_framebuffer(command_buffers[1], frame_data);

    for command_buffers {
        vkEndCommandBuffer(it);
    }

    {   // Submit Shadowmap
        submit_info := VkSubmitInfo.{
            waitSemaphoreCount = 0,
            pWaitSemaphores = null,
            pWaitDstStageMask = null,
            commandBufferCount = 1,
            pCommandBuffers = *command_buffers[0],
            signalSemaphoreCount = 1,
            pSignalSemaphores = *global_renderer.shadowmap_texture.render_finished_semaphore,
        };
        Vk_Check(vkQueueSubmit(global_renderer.graphics_queue, 1, *submit_info, VK_NULL_HANDLE));
    }

    {   // Submit Color
        wait_semaphores := VkSemaphore.[
            global_renderer.shadowmap_texture.render_finished_semaphore,
            frame_data.image_available_semaphore,
        ];

        wait_stages := VkPipelineStageFlags.[
            .FRAGMENT_SHADER_BIT,
            .FRAGMENT_SHADER_BIT,
            .FRAGMENT_SHADER_BIT,
            .FRAGMENT_SHADER_BIT,
            .COLOR_ATTACHMENT_OUTPUT_BIT,
        ];

        submit_info := VkSubmitInfo.{
            waitSemaphoreCount = wait_semaphores.count,
            pWaitSemaphores = wait_semaphores.data,
            pWaitDstStageMask = wait_stages.data,
            commandBufferCount = 1,
            pCommandBuffers = *command_buffers[1],
            signalSemaphoreCount = 1,
            pSignalSemaphores = *frame_data.framebuffer.render_finished_semaphore,
        };
        Vk_Check(vkQueueSubmit(global_renderer.graphics_queue, 1, *submit_info, frame_data.frame_fence));
    }

}

Textured_Mesh_Instance :: struct {
    mesh: *Mesh;
    transform: Matrix4;
    texture: VkDescriptorSet;
}

record_textured_meshes :: (meshes: []Textured_Mesh_Instance, command_buffer: VkCommandBuffer, layout: VkPipelineLayout) {
}

// @Efficiency: We don't read the texture here, so we loose some bandwidth
record_textureless_meshes :: (meshes: []Textured_Mesh_Instance, command_buffer: VkCommandBuffer, layout: VkPipelineLayout) {
    for meshes {
        set_push_constants(it.transform, command_buffer, layout);
        draw(it.mesh, command_buffer);
    }
}
*/
