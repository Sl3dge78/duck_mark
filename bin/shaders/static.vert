#version 450 core
 
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUv;
layout(location = 3) in vec4 aColor;

layout(set = 0, binding = 0) uniform CameraBuffer {
    mat4 proj;
    mat4 view;
    mat4 light;
    uint light_count;
    vec4 light_dir[16];
} CameraData;

layout(push_constant) uniform constants {
    mat4 transform;
    mat4 inv_transform;
} PushConstants;

layout(location = 0) out struct {
    vec4 color;
    vec3 normal;
    vec2 uv;
    vec4 pos_light_space;
    vec4 world_position;
} Out;

void main() {
    vec4 world_position = PushConstants.transform * vec4(aPos, 1.0);
    // mat4 xform = CameraData.proj * CameraData.view * PushConstants.transform;
    gl_Position = CameraData.proj * CameraData.view * world_position;
    Out.world_position = world_position;
    Out.color = aColor;
    Out.normal = mat3(transpose(PushConstants.inv_transform)) * aNormal;    
    Out.uv = aUv;
    mat4 light_xform = CameraData.light * PushConstants.transform;
    Out.pos_light_space = light_xform * vec4(aPos, 1.0);
}
