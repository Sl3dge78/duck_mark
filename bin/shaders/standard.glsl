#ifdef VERTEX_SHADER
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUv;
layout (location = 3) in vec4 aColor;

uniform mat4 Projection;
uniform mat4 View;
uniform mat4 Model;

out vec3 Normal;
out vec2 TexCoords;
out vec3 FragPos;
out vec4 VertexColor;

void main() {
    Normal = aNormal;
    TexCoords = aUv;
    VertexColor = aColor;
    FragPos = vec3(Model * vec4(aPos, 1.0));
    gl_Position = Projection * View * vec4(FragPos, 1.0);
}

#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER
out vec4 FragColor;

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;
in vec4 VertexColor;

uniform sampler2D texture0;

float constant = 1.0f;
float linear = 0.09f;
float quadratic = 0.002f;

void main() {
    vec3 light_pos = vec3(0, 2, 0);
    float distance = length(light_pos - FragPos);
    float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
    vec4 color_tex = 
    FragColor = attenuation * VertexColor;
    FragColor *= texture(texture0, TexCoords);
} 

#endif // FRAGMENT_SHADER
