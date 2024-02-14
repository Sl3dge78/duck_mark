#version 450 core

layout(location = 0) in struct {
    vec4 color;
    vec3 normal;
    vec2 uv;
    vec4 pos_light_space;
    vec4 world_position;
} In;

layout(location = 0) out vec4 outColor;


layout(set = 0, binding = 0) uniform UBO {
    mat4 proj;
    mat4 view;
    mat4 light;
    vec4 light_dir[16];
    uint light_count;
};
layout(set = 1, binding = 0) uniform sampler2D shadow_map;
layout(set = 2, binding = 0) uniform sampler2D diffuse;

const int pcf_count = 3;
const int pcf_total_texels = (pcf_count * 2 + 1) * (pcf_count * 2 + 1);
const float map_size = 2048.0;
const float texel_size = 1.0 / map_size;
const vec3 ambient_color = vec3(0.529, 0.808, 0.922);

const float constant = 1.0;
const float linear = 0.5;
const float quadratic = 0.02;

float shadow(vec4 shadow_coord) {
    vec2 uv = shadow_coord.xy * 0.5 + 0.5; // @TODO: Do depth calc in -1 to 1 range
    float current = shadow_coord.z;
    int total = 0;
    float x = 1.0 - max(dot(In.normal, light_dir[0].xyz), 0.0);
    float bias = max(2.5 * x, 1.0);
    bias *= texel_size;
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
    vec3 iterated_color = In.color.rgb;
    iterated_color *= texture(diffuse, In.uv).rgb;
#if 0
    iterated_color *= point_light(In.world_position.xyz);
#else
    vec3 L = light_dir[0].xyz;
    float NdotL = max(dot(In.normal, -L), 0.0);
    float shadow = shadow(In.pos_light_space / In.pos_light_space.w);
    float factor = max(min(shadow, sqrt(NdotL)), 0.2);
    iterated_color *= factor; 

    vec3 ambient = ambient_color * 0.1;
    iterated_color += ambient * (1.0 - factor);
#endif
    outColor = vec4(iterated_color, 1);
}

