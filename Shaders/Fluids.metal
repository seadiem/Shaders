#include <metal_stdlib>
using namespace metal;

inline float2 bilerpFrag(sampler textureSampler, 
                         texture2d<float> texture, 
                         float2 p, 
                         float2 screenSize) {
    float4 ij; // i0, j0, i1, j1
    ij.xy = floor(p - 0.5) + 0.5;
    ij.zw = ij.xy + 1.0;
    
    float4 uv = ij / screenSize.xyxy;
    float2 d11 = texture.sample(textureSampler, uv.xy).xy;
    float2 d21 = texture.sample(textureSampler, uv.zy).xy;
    float2 d12 = texture.sample(textureSampler, uv.xw).xy;
    float2 d22 = texture.sample(textureSampler, uv.zw).xy;
    
    float2 a = p - ij.xy;
    
    return mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
}

kernel void advect(texture2d<float, access::sample> velocity [[texture(0)]], 
                   texture2d<float, access::sample> advected [[texture(1)]], 
                   texture2d<float, access::write> output [[texture(2)]],
                   constant float2 *sizes [[buffer(0)]],
                   uint2 id [[thread_position_in_grid]]) {
    
    constexpr sampler fluid_sampler(coord::pixel, filter::nearest);
    float2 screenSize = sizes[0];
    float2 uv = float2(id);
    float2 color = 0.998 * bilerpFrag(fluid_sampler, advected, uv, screenSize);
    float4 outpuccolor = float4(color.x, color.y, 0, 1);
    output.write(outpuccolor, id);
}

kernel void firstPassFluid(texture2d<half, access::write> output [[ texture(0) ]],
                           uint2 id [[ thread_position_in_grid ]]) {
    output.write(half4(0.5), id);
}

struct InsectFluid {
    int id;
    float2 position;
    float2 velocity;
};

kernel void bufferToTexture(texture2d<float, access::write> output [[ texture(0) ]],
                            constant float4 *colors [[buffer(0)]],
                            constant InsectFluid *points [[buffer(1)]],
                            uint2 id [[thread_position_in_grid]]) {
    int width = 400;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    
    InsectFluid center = points[0];
    float2 point = center.position;
    float dist = distance(float2(id), point);
    float m = 1 / (dist / 100); 
    

    
    color *= m;
    color.g += m / 10;

    output.write(color, id);
}

kernel void backgroundDraw(texture2d<float, access::sample > preview [[texture(0)]],
                           texture2d<float, access::write> next [[texture(1)]],
                           constant float4 *colors [[buffer(0)]],
                           uint2 id [[ thread_position_in_grid ]]) {
    constexpr sampler s(coord::pixel, filter::nearest);
    float4 oldcolor = preview.sample(s, float2(id));
    
    int width = 400;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    
    float k = 0.05;
    
    float4 result = color * k + oldcolor * (1 - k);
    next.write(result, id);
}

kernel void lightDraw(texture2d<float, access::write> output [[texture(0)]],
                      texture2d<float, access::sample> texture  [[texture(1)]],
                      constant InsectFluid *points [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    constexpr sampler s(coord::pixel, filter::nearest);
    float4 color = texture.sample(s, float2(id));
    float4 notmod = color;
    InsectFluid center = points[0];
    float2 point = center.position;
    float dist = distance(float2(id), point);
    float m = 1 / (dist / 10); 
    color *= m;
    color.g += m / 10;
    float4 res = max(color, notmod);
    output.write(res, id);
}
