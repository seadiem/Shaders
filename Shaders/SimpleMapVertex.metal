/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Vertex shader outputs and fragment shader inputs
typedef struct
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;

} RasterizerData;

vertex RasterizerData vertexShaderMetalAndQuartzAndMatrix(uint vertexID [[vertex_id]],
             constant float3 *vertices [[buffer(0)]],
             constant float2 *viewportSizePointer [[buffer(1)]],
             constant float3 *colors[[buffer(2)]],
             constant simd_float4x4 *matricies[[buffer(3)]])
{
    RasterizerData out;
    out.position.xyz = vertices[vertexID];
    out.position.w = 1.0;
    out.color.rgb = colors[vertexID];
    out.color.a = 1.0;
    simd_float4x4 matrix;
    matrix = matricies[0];
    out.position = matrix * out.position;
    return out;
}

vertex RasterizerData vertexShaderMetalAndQuartz(uint vertexID [[vertex_id]],
             constant float3 *vertices [[buffer(0)]],
             constant float2 *viewportSizePointer [[buffer(1)]],
             constant float3 *colors[[buffer(2)]])
{
    RasterizerData out;
    out.position.xyz = vertices[vertexID];
    out.position.w = 1.0;
    out.color.rgb = colors[vertexID];
    out.color.a = 1.0;
    return out;
}

vertex RasterizerData vertexShaderMetalAndQuartz2D(
             uint vertexID [[vertex_id]],
             constant float2 *vertices [[buffer(0)]],
             constant float2 *viewportSizePointer [[buffer(1)]],
             constant float3 *colors[[buffer(2)]])
{
    RasterizerData out;
    out.position.xy = vertices[vertexID];
    out.position.z = 1.0;
    out.position.w = 1.0;
    out.color.rgb = colors[vertexID];
    out.color.a = 1.0;
    return out;
}

vertex RasterizerData vertexShaderCoub(uint vertexID [[vertex_id]],
             constant float3 *vertices [[buffer(0)]],
             constant float2 *viewportSizePointer [[buffer(1)]],
             constant float3 *colors[[buffer(2)]])
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float3 pixelSpacePosition = vertices[vertexID].xyz;

    // Get the viewport size and cast to float.
    float2 viewportSize = viewportSizePointer[0];
    

    // To convert from positions in pixel space to positions in clip-space,
    // divide the pixel coordinates by half the size of the viewport.
    // out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    // out.position.xy = pixelSpacePosition / (viewportSize * 0.1);
    
    out.position = float4(pixelSpacePosition.x, pixelSpacePosition.y, pixelSpacePosition.z, 1);
    
    
    float3 color = colors[vertexID];
    float4 outcolor = float4(color.r, color.g, color.b, 1.0);
    
    // Pass the input color directly to the rasterizer.
    out.color = outcolor;

    return out;
}


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
             constant float2 *vertices [[buffer(0)]],
             constant float2 *viewportSizePointer [[buffer(1)]],
             constant float3 *colors[[buffer(2)]])
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float2 pixelSpacePosition = vertices[vertexID].xy;

    // Get the viewport size and cast to float.
    float2 viewportSize = viewportSizePointer[0];
    

    // To convert from positions in pixel space to positions in clip-space,
    // divide the pixel coordinates by half the size of the viewport.
    // out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    // out.position.xy = pixelSpacePosition / (viewportSize * 0.1);
    
    out.position = float4(pixelSpacePosition.x, pixelSpacePosition.y, 0.0, 1.0);
    
    
    float3 color = colors[vertexID];
    float4 outcolor = float4(color.r, color.g, color.b, 1.0);
    
    // Pass the input color directly to the rasterizer.
    out.color = outcolor;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}

