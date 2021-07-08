#include <metal_stdlib>
#include <simd/simd.h>

struct SimpleVertex {
    
    float4 position [[position]];
    float pointsize[[point_size]];
    
};

vertex SimpleVertex simpleVertexFunction(uint vertexID [[vertex_id]], 
                                         constant float3 *vertices [[buffer(0)]],
                                         constant simd_float4x4 *matricies[[buffer(1)]]) {
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    SimpleVertex out;
    out.position = transformMatrix * position4;
    
    return out;
}

fragment float4 simpleFragmentFunction(SimpleVertex vert [[stage_in]]) {
    float4 pixelcolor(0.5, 0.6, 0.7, 1.0);
    return pixelcolor;
}
