#version 450 core
#extension GL_ARB_shading_language_include : require
#include "common.glsl"
 
layout(location = 0) in vec3 in_pos;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;
layout(location = 3) in vec4 in_color;

layout(set = VTX_UNIFORM_SET, binding = 0) uniform CameraBuffer {
    mat4 proj;
    mat4 view;
    mat4 light;
    uint light_count;
    vec4 light_dir[16];
};

layout(location = 0) out struct {
    vec4 color;
    vec3 normal;
    vec2 uv;
    vec4 pos_light_space;
    vec4 world_position;
} Out;

struct InstanceData {
    mat4 xform;
    mat4 inverse;
    float velocity;
};

layout(set = VTX_STORAGE_BUFFER_SET, binding = 0) readonly buffer InstanceBuffer {
    InstanceData data[];
};

void main() {
    vec4 world_position = data[gl_InstanceIndex].xform * vec4(in_pos, 1.0);
    gl_Position = proj * view * world_position;
    Out.world_position = world_position;
    Out.color = in_color;
    Out.normal = mat3(data[gl_InstanceIndex].inverse) * in_normal;
    Out.uv = in_uv;
    Out.pos_light_space = light * world_position;
}
