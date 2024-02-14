#version 450 core
 
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUv;
layout(location = 3) in vec4 aColor;
layout(location = 4) in uvec4 joints;
layout(location = 5) in vec4 weights;

layout(set = 0, binding = 0) uniform CameraData_t {
    mat4 proj;
    mat4 view;
    mat4 light;
    uint light_count;
    vec4 light_dir[16];
} CameraData;

layout(set = 3, binding = 0) uniform InstanceData_t {
    mat4 joint_matrices[64];
} InstanceData;

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
    mat4 skin_mat = 
        weights.x * InstanceData.joint_matrices[joints.x] + 
		weights.y * InstanceData.joint_matrices[joints.y] +
		weights.z * InstanceData.joint_matrices[joints.z] +
		weights.w * InstanceData.joint_matrices[joints.w];

    vec4 world_pos = PushConstants.transform * skin_mat * vec4(aPos, 1.0);
    gl_Position = CameraData.proj * (CameraData.view * world_pos);

    mat4 inv_skin = inverse(PushConstants.transform * skin_mat);

    Out.color = aColor;
    Out.normal = mat3(inv_skin) * aNormal;    
    Out.uv = aUv;
    Out.pos_light_space = CameraData.light * world_pos;
    Out.world_position = world_pos;
}
