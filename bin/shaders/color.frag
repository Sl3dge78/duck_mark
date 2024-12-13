#version 450 core
#extension GL_ARB_shading_language_include : require
#include "common.glsl"

layout(location = 0) in struct {
    vec4 color;
    vec3 normal;
    vec2 uv;
    vec4 pos_light_space;
    vec4 world_position;
} In;

layout(location = 0) out vec4 out_color;

layout(set = FRAG_UNIFORM_SET, binding = 0) uniform CameraBuffer {
    mat4 proj;
    mat4 view;
    mat4 light;
    vec4 light_dir[16];
    uint light_count;
};
layout(set = FRAG_SAMPLER_SET, binding = 0) uniform sampler2D shadow_map;
layout(set = FRAG_SAMPLER_SET, binding = 1) uniform sampler2D diffuse;

const int pcf_count = 0;
const int pcf_total_texels = (pcf_count * 2 + 1) * (pcf_count * 2 + 1);
const float map_size = 2048.0;
const float texel_size = 1.0 / map_size;
const vec3 ambient_color = vec3(0.529, 0.808, 0.922);

const float constant = 1.0;
const float linear = 0.5;
const float quadratic = 0.02;

float shadow(vec4 shadow_coord) {
    vec3 proj_coords = In.pos_light_space.xyz / In.pos_light_space.w;
    vec2 uv = proj_coords.xy * 0.5 + 0.5;
    uv.y = 1 - uv.y;
    float current = proj_coords.z;
    float x = 1.0 - max(dot(In.normal, light_dir[0].xyz), 0.0);
    float bias = max(2.5 * x, 1.0) * texel_size;

    int total = 0;
    for(int x = -pcf_count; x <= pcf_count; x++) {
        for(int y = -pcf_count; y <= pcf_count; y++) {
            float closest = texture(shadow_map, uv + vec2(x, y) * texel_size).r;        
            if (current - bias > closest) {
                total += 1;
            }
        }
    }
    float result = float(total) / float(pcf_total_texels);
    return 1.0 - result;
}

float point_light(vec3 frag_pos) {
    float acc = 0;
    for(uint i = 0; i < light_count; i++) {
        vec3 light_pos = light_dir[i].xyz;
        float distance = length(light_pos - frag_pos);
        acc += 1.0 / (constant + linear * distance + quadratic * (distance * distance));
    }
    return acc;
}

void main() {
    vec3 iterated_color = In.color.rgb * texture(diffuse, In.uv).rgb;
    vec3 l = light_dir[0].xyz;
    float n_dot_l = max(dot(In.normal, -l), 0.0);
    float shadow = shadow(In.pos_light_space);
    float factor = max(min(shadow, sqrt(n_dot_l)), 0.2);
    vec3 ambient = ambient_color * 0.1;
    iterated_color = ambient * (1.0 - factor) + iterated_color * factor;
    out_color = vec4(iterated_color, 1);
}

