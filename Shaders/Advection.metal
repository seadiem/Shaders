#include <metal_stdlib>
using namespace metal;

struct FluidCell {
    float2 temp;
    float2 velocity;
    float density;
};

#define COLUMNS 90
#define ROWS 90

struct FluidBuffer {
    FluidCell cells[COLUMNS][ROWS];
};

kernel void moveCells(device FluidBuffer *current [[buffer(0)]],
                      device FluidBuffer *next [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    int2 velocity = int2(current[0].cells[id.x][id.y].velocity);
    int2 nextid = int2(id) + velocity;
    float content = current[0].cells[id.x][id.y].density;
    next[0].cells[nextid.x][nextid.y].density = content;
}

kernel void advectK1_2(device FluidBuffer *current [[buffer(0)]],
                     device FluidBuffer *next [[buffer(1)]],
                     uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) - current[0].cells[id.x][id.y].velocity;
    float2 ij; 
    ij.xy = floor(p);
    int2 i = int2(ij);
    float2 d11 = current[0].cells[i.x][i.y].density;
    float2 d21 = current[0].cells[i.x + 1][i.y].density;
    float2 d12 = current[0].cells[i.x][i.y + 1].density;
    float2 d22 = current[0].cells[i.x + 1][i.y + 1].density;
        if ((p.x < 0) || (p.y < 0)) {
            d11 = 0, d21 = 0, d12 = 0, d22 = 0;
        }
    float2 a = p - ij.xy;
//    a = normalize(a);
//    float2 a = ij.xy - p;
    next[0].cells[id.x][id.y].density = (mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y)).x;
//    next[0].cells[id.y][id.x].density = mix(mix(d11, d21, 0.1), mix(d12, d22, 0.1), 0.9);
}

kernel void advectK1(constant FluidBuffer *current [[buffer(0)]],
                     device FluidBuffer *next [[buffer(1)]],
                     uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) - current[0].cells[id.x][id.y].velocity;
    float4 ij; // i0, j0, i1, j1
    ij.xy = floor(p);
    ij.zw = ij.xy + 1.0;
    uint4 i = uint4(ij);
    float d11 = current[0].cells[i.x][i.y].density;
    float d21 = current[0].cells[i.z][i.y].density;
    float d12 = current[0].cells[i.x][i.w].density;
    float d22 = current[0].cells[i.z][i.w].density;
//    if ((p.x < 0) || (p.y < 0)) {
//        d11 = 0, d21 = 0, d12 = 0, d22 = 0;
//    }
    float2 a = p - ij.xy;
//    float2 a = ij.xy - p;
    next[0].cells[id.y][id.x].density = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
}

kernel void moveCellsPrecise(device FluidBuffer *current [[buffer(0)]],
                             device FluidBuffer *next [[buffer(1)]],
                             uint2 id [[thread_position_in_grid]]) {
    uint2 tempid = id;
    id.x = tempid.y;
    id.y = tempid.x;
    float2 p = float2(id);
    float2 v = current[0].cells[id.x][id.y].velocity;
    float2 f = p - v;
    int2 i = int2(floor(f));
    float2 j = fract(f);
    float d1 = current[0].cells[i.x][i.y].density;
    float d2 = current[0].cells[i.x][i.y + 1].density;
    float d3 = current[0].cells[i.x + 1][i.y].density;
    float d4 = current[0].cells[i.x + 1][i.y + 1].density;
    if ((p.x < 0) || (p.y < 0)) {
        d1 = 0, d1 = 0, d3 = 0, d4 = 0;
    }
    float z1 = mix(d1, d2, j.x);
    float z2 = mix(d3, d4, j.x);
    float nd = mix(z1, z2, j.y);
    next[0].cells[id.y][id.x].density = nd;
}

kernel void bounds(device FluidBuffer *buffer [[buffer(0)]],
                   uint2 id [[thread_position_in_grid]]) {
    
    if ((id.x <= 0) || (id.x >= COLUMNS - 20) || (id.y <= 0) || (id.y) >= ROWS - 20) {
        float2 center = float2(COLUMNS / 2, ROWS / 2);
        float2 c = center - float2(id);
        float2 cn = normalize(c);
        buffer[0].cells[id.x][id.y].velocity = float2(1, -1);
    }
}

//inline float2 bilerpFrag(sampler textureSampler, texture2d<float> texture, float2 p, float2 screenSize) {
//    float4 ij; // i0, j0, i1, j1
//    ij.xy = floor(p - 0.5) + 0.5;
//    ij.zw = ij.xy + 1.0;
//    
//    float4 uv = ij / screenSize.xyxy;
//    float2 d11 = texture.sample(textureSampler, uv.xy).xy;
//    float2 d21 = texture.sample(textureSampler, uv.zy).xy;
//    float2 d12 = texture.sample(textureSampler, uv.xw).xy;
//    float2 d22 = texture.sample(textureSampler, uv.zw).xy;
//    
//    float2 a = p - ij.xy;
//    
//    return mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
//}


kernel void fillTextureToDark(texture2d<half, access::write> output [[ texture(0) ]],
                              uint2 id [[ thread_position_in_grid ]]) {
    output.write(half4(0.5, 0.5, 0.5, 1.0), id);
}

kernel void fillTexture(constant FluidBuffer *current [[buffer(0)]],
                        texture2d<float, access::write> texture [[texture(0)]],
                        uint2 id [[thread_position_in_grid]]) {
    uint2 xy = id / 2;
    float density = current[0].cells[xy.x][xy.y].density;
    float4 color = float4(0.7, 0.6, 0.5, 1.0);
    float2 velocity = current[0].cells[xy.x][xy.y].velocity;
    float3 vel3;
    vel3.xy = velocity.xy;
    vel3.z = 1.0;
    float3 oy = float3(0, 1, 0);
    float k = dot(vel3, oy);
//    color = color * k;
    color = color * 1;
    if (density > 0) {
        float4 dcolor = float4(0.5, 1, 0, 1);
        dcolor *= density;
        dcolor.a = 1;
        color += dcolor;        
    }
//    if (density > 0) {
//        color = color * (density);        
//    } else {
//        float2 velocity = current[0].cells[xy.x][xy.y].velocity;
//        float3 vel3;
//        vel3.xy = velocity.xy;
//        vel3.z = 1.0;
//        float3 oy = float3(0, 1, 0);
//        float k = dot(vel3, oy);
//        color = color * k;
//    }
    color.a = 1.0;
    texture.write(color, id);
}
