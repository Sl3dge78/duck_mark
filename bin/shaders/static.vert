#version 450 core
#extension GL_ARB_shading_language_include : require
#include "common.glsl"
 
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUv;
layout(location = 3) in vec4 aColor;

layout(set = VTX_UNIFORM_SET, binding = 1) uniform constants {
    mat4 transform;
    mat4 inv_transform;
} PushConstants;

layout(set = VTX_UNIFORM_SET, binding = 0) uniform CameraBuffer {
    mat4 proj;
    mat4 view;
    mat4 light;
    uint light_count;
    vec4 light_dir[16];
} CameraData;

layout(location = 0) out struct {
    vec4 color;
    vec3 normal;
    vec2 uv;
    vec4 pos_light_space;
    vec4 world_position;
} Out;

void main() {
    vec4 world_position = vec4(aPos, 1.0) * PushConstants.transform;
    // mat4 xform = CameraData.proj * CameraData.view * PushConstants.transform;
    gl_Position = world_position * CameraData.view * CameraData.proj;
    Out.world_position = world_position;
    Out.color = aColor;
    Out.normal = aNormal * mat3(transpose(PushConstants.inv_transform));
    Out.uv = aUv;
    mat4 light_xform = PushConstants.transform * CameraData.light;
    Out.pos_light_space = vec4(aPos, 1.0) * light_xform;
}
