#include <metal_stdlib>
using namespace metal;

kernel void grid1(device const float *array [[buffer(1)]], 
                 device float *result [[buffer(0)]], 
                 uint index [[thread_position_in_grid]]) {
    float z = array[index];
    z += 10;
    result[index] = z;
}


kernel void firstPass(texture2d<half, access::write> output [[ texture(0) ]],
                      uint2 id [[ thread_position_in_grid ]]) {
    output.write(half4(0.5), id);
}

kernel void secondPass(texture2d<float, access::write> output [[ texture(0) ]],
                       constant float4 *colors [[buffer(0)]],
                       uint id [[ thread_position_in_grid ]]) {
    float4 color = colors[id];
    uint x = id % 200;
    uint y = id / 200;
    uint2 index = uint2(x, y);
    output.write(color, index);
}

kernel void secondPassTwo(texture2d<float, access::write> output [[ texture(0) ]],
                          constant float4 *colors [[buffer(0)]],
                          uint2 id [[ thread_position_in_grid ]]) {
    int width = 200;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    output.write(color, id);
}

kernel void secondPassLight(texture2d<float, access::write> output [[ texture(0) ]],
                            constant float4 *colors [[buffer(0)]],
                            constant float2 *points [[buffer(1)]],
                            uint2 id [[ thread_position_in_grid ]]) {
    int width = 200;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    
    float2 point = points[0];
    float dist = distance(float2(id), point);
    color /= dist / 100;
    
    output.write(color, id);
}
