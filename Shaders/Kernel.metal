//
//  Shaders.metal
//  Shaders
//
//  Created by oktet on 12.12.2019.
//  Copyright © 2019 oktet. All rights reserved.
//

#include <metal_stdlib>



using namespace metal;
/// This is a Metal Shading Language (MSL) function equivalent to the add_arrays() C function, used to perform the calculation on a GPU.
kernel void add_arrays(device const char* inA,
                       device const char* inB,
                       device char* result,
                       uint index [[thread_position_in_grid]])
{
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    result[index] = inA[index] + inB[index];
    
}

kernel void add_arrays_simd(device const float4* inA,
                       device const float4 *inB,
                       device float4 *result,
                       device char *indicies,
                       uint index [[thread_position_in_grid]])
{
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    result[index] = inA[index];
    result[index].x /= inB[index].x;
    indicies[index] = index;
}

kernel void testinterpolate() {
//    simd_float2 one = simd_float2(0, 0);
//    simd_float2 two = simd_float2(4, 4);
//    simd_float2 result = mix(<#metal::float2 x#>, <#metal::float2 y#>, <#metal::float2 a#>)
}

kernel void learnKernel(device const float *vectors [[buffer(1)]], 
                        device float *result [[buffer(0)]], 
                        uint index [[thread_position_in_grid]]) {
    float z = vectors[index];
    z += 10;
    result[index] = z;
}

void kernel myKernel( uint2 S [[ threads_per_threadgroup ]], 
                      uint2 W [[ threadgroups_per_grid ]], 
                      uint2 z [[ thread_position_in_grid ]]) {
    
}

kernel void adjust_saturation(texture2d<float, access::read> inTexture [[texture(0)]], 
                              texture2d<float, access::write> outTexture [[texture(1)]], 
                              constant float *saturationFactors [[buffer(0)]], 
                              uint2 gid [[thread_position_in_grid]]) {
    float factor = saturationFactors[0];
    float4 inColor = inTexture.read(gid);
    float value = dot(inColor.rgb, float3(0.299, 0.587, 0.114)); float4 grayColor(value, value, value, 1.0);
    float4 outColor = mix(grayColor, inColor, factor); 
    outTexture.write(outColor, gid);
}

kernel void gaussian_blur_2d(texture2d<float, access::read> inTexture [[texture(0)]], 
                             texture2d<float, access::write> outTexture [[texture(1)]], 
                             texture2d<float, access::read> weights [[texture(2)]], 
                             uint2 gid [[thread_position_in_grid]]) {
    
    int size = weights.get_width(); 
    int radius = size / 2;
    float4 accumColor(0, 0, 0, 0);
    for (int j = 0; j < size; ++j) {
        for (int i = 0; i < size; ++i) {
            uint2 kernelIndex(i, j);
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(textureIndex).rgba;
            float4 weight = weights.read(kernelIndex).rrrr;
            accumColor += weight * color;
        }
        outTexture.write(float4(accumColor.rgb, 1), gid);
    }
    
}
