#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;


struct Light
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct Material
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant Material material = {
    .ambientColor = { 0.9, 0.1, 0 },
    .diffuseColor = { 0.9, 0.1, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

struct ProjectedVertex
{
    float4 position [[position]];
    float3 eye;
    float3 normal;
};

// Vertex shader outputs and fragment shader inputs
struct OutVertex
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];
    float pointsize[[point_size]];
    
    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
    
};

vertex OutVertex vertexLightingShader(uint vertexID [[vertex_id]],
                     constant float3 *vertices [[buffer(0)]],
                     constant float3 *colors[[buffer(1)]],
              constant simd_float4x4 *matricies[[buffer(2)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    out.color.rgb = colors[vertexID].rgb;
    out.color.a = 1.0;
    out.pointsize = 5;
    
//    simd_float4x4 modelViewProjectionMatrix;
//    ProjectedVertex projectedVertex;
    
    return out;
}

fragment float4 fragmentLightingShader(OutVertex in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}
