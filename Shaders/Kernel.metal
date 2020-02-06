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
