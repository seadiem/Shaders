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
    int width = 400;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    output.write(color, id);
}

struct Insect {
    int id;
    float2 position;
    float2 velocity;
};

float2 orbitVelocity(float2 sun, Insect planet);
kernel void insectPass(device Insect *insects[[buffer(0)]],
                       constant Insect *selected [[buffer(1)]],
                       uint id [[ thread_position_in_grid ]]) {
    Insect insect = insects[id];
    float2 velocity = orbitVelocity(selected[0].position, insect);
    insect.velocity = velocity / 10;
    insect.position += insect.velocity;
    insects[id] = insect;
}

kernel void secondPassLight(texture2d<float, access::write> output [[ texture(0) ]],
                            constant float4 *colors [[buffer(0)]],
                            constant Insect *selected [[buffer(1)]],
                            constant Insect *insects[[buffer(2)]],
                            uint2 id [[ thread_position_in_grid ]]) {
    int width = 400;
    int i = width * id.y + id.x;
    float4 color = colors[i];
    
    Insect center = selected[0];
    float2 point = center.position;
    float dist = distance(float2(id), point);
    float m = 1 / (dist / 100); 
    
    float m1 = 1;
    for (uint i = 0; i < 10; i++) {
        Insect insect = insects[i];
        float dist = distance(float2(id), insect.position);
        m1 *= dist / 80;
    }
    
    color *= m;
    color.g += m / 10;
    
    color += colors[i] / m1;
    
    output.write(color, id);
    
}

float2 orbitVelocity(float2 sun, Insect planet) {
    float2 diff = sun - planet.position;
    float2 c = float2(diff.y, -diff.x);
    c = normalize(c) * 2;
    return c;
}


kernel void copyTextures(texture2d<float, access::write> drawable [[ texture(0) ]],
                         texture2d<float> input [[ texture(1) ]],
                         texture2d<float> colors [[ texture(2) ]],
                         constant Insect *selected [[buffer(1)]],
                         uint2 pt [[ thread_position_in_grid ]]) {
    float2 center = selected[0].position;
    float2 coords = float2(pt);
    float d = distance(center, coords);
    
    float4 color = input.read(pt);
    float4 oldcolor = colors.read(pt);
    
    float k = d / 50;

    if (k > 1) { k = 1; }
    if (k < 0) { k = 0; }
    
    float4 result = color * k + oldcolor * (1 - k);
    
    drawable.write(result, pt);

}
