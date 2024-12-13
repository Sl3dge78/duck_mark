// For SPIR-V shaders, use the following resource sets:
// 
// For vertex shaders:
//     0: Sampled textures, followed by storage textures, followed by storage buffers
//     1: Uniform buffers
// 
// For fragment shaders:
//     2: Sampled textures, followed by storage textures, followed by storage buffers
//     3: Uniform buffers
#define VTX_SAMPLER_SET  0
#define VTX_STORAGE_BUFFER_SET  0
#define VTX_UNIFORM_SET  1
#define FRAG_SAMPLER_SET 2
#define FRAG_UNIFORM_SET 3

// For SPIR-V shaders, use the following resource sets:
//    0: Sampled textures, followed by read-only storage textures, followed by read-only storage buffers
//    1: Write-only storage textures, followed by write-only storage buffers
//    2: Uniform buffers
#define COMP_SAMPLER_SET 0
#define COMP_READONLY_TEXTURE_SET 0
#define COMP_READONLY_BUFFER_SET 0
#define COMP_WRITEONLY_TEXTURE_SET 1
#define COMP_WRITEONLY_BUFFER_SET 1
#define COMP_UNIFORM_BUFFER_SET 2
