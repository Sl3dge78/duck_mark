struct Vertex_Input {
    @location(0) position: vec2f, 
    @location(1) uv: vec2f,
    @location(2) color: vec4f,
};

struct Vertex_Output {
    @builtin(position) position: vec4f,
    @location(0) color: vec4f,
    @location(1) uv: vec2f,
};

struct Push_Constants {
    scale: vec2f,
    translation: vec2f,
};

@group(0) @binding(0) var texture_sampler: sampler;
@group(0) @binding(1) var texture: texture_2d<f32>;

var<push_constant> push_constants : Push_Constants;

@vertex
fn vs_main (in: Vertex_Input) -> Vertex_Output {
    var out: Vertex_Output;
    out.color = in.color;
    out.uv    = in.uv;
    let pos_2d : vec2f = in.position.xy * push_constants.scale + push_constants.translation;
    out.position = vec4f(pos_2d, 0.0, 1.0);
    return out;
}

@fragment
fn fs_main (in: Vertex_Output) -> @location(0) vec4f {
    let fmod = 1.0 - ((in.position.y % 2.0) / 4.0);
    let color = in.color * textureSample(texture, texture_sampler, in.uv).r;
    return color * fmod;
}
