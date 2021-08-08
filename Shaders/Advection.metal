#include <metal_stdlib>
using namespace metal;

struct FluidCell {
    float density;
    float2 velocity;
    float2 temp;
};

#define COLUMNS 18
#define ROWS 18
#define SCALE 6

struct FluidBuffer {
    FluidCell cells[COLUMNS][ROWS];
};

kernel void moveCellsOne(device FluidBuffer *current [[buffer(0)]],
                         uint2 id [[thread_position_in_grid]]) {
    int2 n = int2(float2(id) + current[0].cells[id.x][id.y].velocity);
//    if ((n.x > COLUMNS - 1) || (n.y > ROWS - 1)) { return; }
    float content = current[0].cells[id.x][id.y].density;
    current[0].cells[id.x][id.y].temp += float2(id);
    if ((n.x > COLUMNS - 1) || (n.y > ROWS - 1)) { 
        return;
    }
    current[0].cells[n.x][n.y].density = content;
//    current[0].cells[id.x][id.y].temp = float2(n);
}

kernel void advectK1_3(device FluidBuffer *current [[buffer(0)]],
                       uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) - current[0].cells[id.x][id.y].velocity;
    float2 ij; 
    ij.xy = floor(p);
    int2 i = int2(ij);
    float d11 = current[0].cells[i.x][i.y].density;
    float d21 = current[0].cells[i.x + 1][i.y].density;
    float d12 = current[0].cells[i.x][i.y + 1].density;
    float d22 = current[0].cells[i.x + 1][i.y + 1].density;
    if ((p.x < 0) || (p.y < 0)) {
        d11 = 0, d21 = 0, d12 = 0, d22 = 0;
    }
    float2 a = p - ij.xy;
    current[0].cells[id.x][id.y].density = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
}

kernel void moveCells(device FluidBuffer *current [[buffer(0)]],
                      device FluidBuffer *next [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
//    int2 velocity = int2(current[0].cells[id.x][id.y].velocity);
//    int2 nextid = int2(id) + velocity;
    int2 nextid = int2(current[0].cells[id.x][id.y].velocity + float2(id));
    current[0].cells[id.x][id.y].temp = float2(nextid);
    float content = current[0].cells[id.x][id.y].density;
    next[0].cells[nextid.x][nextid.y].density = content;
    current[0].cells[nextid.x][nextid.y].density = content;
}

kernel void advectK1_2(device FluidBuffer *current [[buffer(0)]],
                     device FluidBuffer *next [[buffer(1)]],
                     uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) - current[0].cells[id.x][id.y].velocity;
    float2 ij; 
    ij.xy = floor(p);
    int2 i = int2(ij);
    float d11 = current[0].cells[i.x][i.y].density;
    float d21 = current[0].cells[i.x + 1][i.y].density;
    float d12 = current[0].cells[i.x][i.y + 1].density;
    float d22 = current[0].cells[i.x + 1][i.y + 1].density;
        if ((p.x < 0) || (p.y < 0)) {
            d11 = 0, d21 = 0, d12 = 0, d22 = 0;
        }
    float2 a = p - ij.xy;
//    a = normalize(a);
//    float2 a = ij.xy - p;
    next[0].cells[id.x][id.y].density = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
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
    next[0].cells[id.x][id.y].density = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
}

kernel void bounds(device FluidBuffer *buffer [[buffer(0)]],
                   uint2 id [[thread_position_in_grid]]) {
    if (id.x >= COLUMNS - 5) {
        buffer[0].cells[id.x][id.y].velocity = float2(1.0, -1.0);
    }
    if (id.x >= COLUMNS - 3) {
        buffer[0].cells[id.x][id.y].velocity = float2(2.0, 0.0);
    }
    if (id.x >= COLUMNS - 1) {
        buffer[0].cells[id.x][id.y].velocity = float2(-1.0, -1.0);
    }
}

kernel void field(device FluidBuffer *buffer [[buffer(0)]],
                  constant float2 *forces [[buffer(1)]],
                  uint2 id [[thread_position_in_grid]]) {
    buffer[0].cells[id.x][id.y].velocity = forces[0];
}

//kernel void bounds(device FluidBuffer *buffer [[buffer(0)]],
//                   uint2 id [[thread_position_in_grid]]) {
//    if ((id.x <= 0) || (id.x >= COLUMNS - 3) || (id.y <= 0) || (id.y >= ROWS - 5)) {
////        float2 center = float2(COLUMNS / 2, ROWS / 2);
////        float2 c = center - float2(id);
////        float2 cn = normalize(c);
//        buffer[0].cells[id.x][id.y].velocity = float2(1, 1);
//    }
//    if ((id.x <= 0) || (id.x >= COLUMNS - 3) || (id.y <= 0) || (id.y >= ROWS - 2)) {
//        buffer[0].cells[id.x][id.y].velocity = float2(1, 0);
//    }
//}

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
    uint2 xy = id / SCALE;
    float density = current[0].cells[xy.x][xy.y].density;
    float4 color = float4(0.7, 0.6, 0.5, 1.0);
    if (density > 0) {
        float4 dcolor = float4(0.5, 1, 0, 1);
        dcolor *= density;
        dcolor.a = 1;
        color += dcolor;        
    }
    color.a = 1.0;
    texture.write(color, id);
    
//    float2 velocity = current[0].cells[xy.x][xy.y].velocity;
//    float3 vel3;
//    vel3.xy = velocity.xy;
//    vel3.z = 1.0;
//    float3 oy = float3(0, 1, 0);
//    float k = dot(vel3, oy);
////    color = color * k;
//    color = color * 1;
//    if (density > 0) {
//        float4 dcolor = float4(0.5, 1, 0, 1);
//        dcolor *= density;
//        dcolor.a = 1;
//        color += dcolor;        
//    }
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
}
