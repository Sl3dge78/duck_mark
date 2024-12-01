#version 450 core

layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUv;
layout(location = 2) in vec4 aColor;

layout(set = 1, binding = 0) uniform constants {
    vec2 scale;
    vec2 translation;
} PushConstants;

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec2 vUv;

void main() {
    gl_Position = vec4(aPos.xy * PushConstants.scale + PushConstants.translation , 0.0, 1.0);
    vColor = aColor;
    vUv = aUv;
}
