#ifdef VERTEX_SHADER
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUv;
layout (location = 3) in vec4 aColor;

out vec2 TexCoords;
out vec4 VertexColor;

uniform mat4 Projection;

void main() {
    gl_Position = Projection * vec4(aPos.xy, 0.0, 1.0); 
    TexCoords = aUv;
    VertexColor = aColor;
}  
#endif // VERTEX_SHADER
#ifdef FRAGMENT_SHADER

out vec4 FragColor;
  
in vec2 TexCoords;
in vec4 VertexColor;

uniform sampler2D texture0;

float fmin = 0.0;

void main() { 
    float fmod = mod(gl_FragCoord.y, 2.0);
    float fstep = fmin + (1.0 - fmin) * fmod;

    vec4 tex = texture(texture0, TexCoords);
    vec4 color = vec4(VertexColor.xyz, tex.a * VertexColor.a);
    FragColor =  color * vec4(0.5, 1.0, 0.5, 1.0) * fstep;
}

#endif // FRAGMENT_SHADER
