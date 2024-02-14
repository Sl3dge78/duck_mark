
Input_Reader_Fn :: #type (self: *void, gs: *Game_State, event: SDL_Event);

Game_State :: struct {
    font16: Font;
    shadowmap_finished_semaphore: VkSemaphore;

    quad_mesh: Mesh;

    bunny_mesh: Mesh;
    bunny_tex: Texture;
    bunny_desc: VkDescriptorSet;

    player: Player;

    ducks: [..]Duck;
}


Duck :: struct {
    position: Vector3;
    velocity: Vector3;
}

game_state_create :: (using state: *Game_State) {
    font16 = font_from_file("res/font.ttf", 16);

    quad_mesh = load_mesh_from_vertices(.[
        .{.{- 0.5, 0, + 0.5}, UP, .{0, 0}, .{1, 1, 1, 1}},
        .{.{+ 0.5, 0, + 0.5}, UP, .{1, 0}, .{1, 1, 1, 1}},
        .{.{+ 0.5, 0, - 0.5}, UP, .{1, 1}, .{1, 1, 1, 1}},
        .{.{- 0.5, 0, - 0.5}, UP, .{0, 1}, .{1, 1, 1, 1}},], 
        .[0, 1, 2, 0, 2, 3]);

    bunny_mesh = load_mesh_from_file("res/Duck.gltf");
    bunny_tex = texture_from_file("res/DuckCM.png");
    bunny_desc = create_texture_descriptor_set(bunny_tex);

    NB_DUCKS :: 1000;

    for 0..NB_DUCKS {
        duck := new_duck();
        array_add(*ducks, duck);
    }

    player.transform.position = .{0, 25, 75};
        
    global_renderer.lights[0] = xyzw(unit_vector(.{-1, -1, -1}), 0);

}

new_duck :: () -> Duck {
    vel :=  unit_vector(.{
        1 - 2 * random_get_zero_to_one(), 
        1 - 2 * random_get_zero_to_one(), 
        1 - 2 * random_get_zero_to_one(), 
    }) * 50;
    return .{.{0, 10, 0}, vel};
}

destroy :: (using state: *Game_State) {
    vkDestroySemaphore(global_renderer.device, shadowmap_finished_semaphore, null);
}

game_state_input_event :: (using state: *Game_State, event: SDL_Event) {
}

game_state_update :: (using state: *Game_State, delta_time: float) {
    player_update(*state.player, state, delta_time);
    SIZE :: 50;
    for *ducks {
        it.position += (it.velocity * delta_time);
        if it.position.x > SIZE { 
            it.position.x = SIZE;
            it.velocity.x *= -1;
        } else if it.position.x < -SIZE {
            it.position.x = -SIZE;
            it.velocity.x *= -1;
        }

        if it.position.y < 0 {
            it.velocity.y *= -1;
            it.position.y = 0;
        }

        if it.position.z > SIZE { 
            it.position.z = SIZE;
            it.velocity.z *= -1;
        } else if it.position.z < -SIZE {
            it.position.z = -SIZE;
            it.velocity.z *= -1;
        }

        it.velocity.y -= 9.81 * delta_time;

        it.velocity *= 0.999; // damp
    }

    if mouse_left() {
        for 0..100 {
            duck := new_duck();
            array_add(*ducks, duck);
        }
        console_message("NB Ducks: %", ducks.count);
    }
}

game_state_draw :: (using state: *Game_State, frame_data: *Frame_Data) {
    render_pass_3d(state, frame_data);
}

render_pass_3d :: (using state: *Game_State, frame_data: *Frame_Data) {
    set_view_matrix(player_get_camera_matrix(*state.player));

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

    // @Speed: The fact that we have to split the color and shadowpass is annoying
    // Could be fixed if we have all the render data uploaded to the gpu, and use instances/indices
    // to look it up. Each shader will lookup what it needs and we're good
    mats := NewArray(ducks.count, Matrix4,, temp);
    for ducks {
        mats[it_index] = make_translation_matrix4(it.position) * make_scale_matrix4(.{0.01, 0.01, 0.01});
    }

    {
        bind_material(command_buffers[0], global_renderer.static_mesh_material, .SHADOWMAP);
        layout := global_renderer.static_mesh_material.shadowmap.layout;
        // Quad
        set_push_constants(make_scale_matrix4(.{100, 1, 100}), command_buffers[0], layout);
        draw(quad_mesh, command_buffers[0]);

        for mats {
            set_push_constants(it, command_buffers[0], layout);
            draw(bunny_mesh, command_buffers[0]);
        }
    }

    {
        bind_material(command_buffers[1], global_renderer.static_mesh_material, .COLOR);
        layout := global_renderer.static_mesh_material.color.layout;

        // Quad
        set_push_constants(make_scale_matrix4(.{100, 1, 100}), command_buffers[1], layout);
        bind_diffuse(global_renderer.empty_texture_descriptor_set, command_buffers[1], layout);
        draw(quad_mesh, command_buffers[1]);

        bind_diffuse(bunny_desc, command_buffers[1], layout);
        for mats {
            set_push_constants(it, command_buffers[1], layout);
            draw(bunny_mesh, command_buffers[1]);
        }
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
