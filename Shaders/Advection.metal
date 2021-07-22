#include <metal_stdlib>
using namespace metal;

struct FluidCell {
    float2 temp;
    float2 velocity;
    float density;
};

struct FluidBuffer {
    FluidCell cells[5][10];
};

kernel void moveCells(device FluidBuffer *current [[buffer(0)]],
                      device FluidBuffer *next [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    int2 delta = int2(current[0].cells[id.y][id.x].velocity);
    int2 nextid = int2(id) + delta;
    float content = current[0].cells[id.y][id.x].density;
    float old = next[0].cells[nextid.y][nextid.x].density;
    next[0].cells[nextid.y][nextid.x].density = content;
    current[0].cells[id.y][id.x].density = old;
}

kernel void moveCellsPrecise(device FluidBuffer *current [[buffer(0)]],
                             device FluidBuffer *next [[buffer(1)]],
                             uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id.y, id.x);
    float2 v = current[0].cells[id.y][id.x].velocity;
    float2 f = p - v;
    int2 i = int2(floor(f));
    float2 j = fract(f);
    float d1 = current[0].cells[i.y][i.x].density;
    float d2 = current[0].cells[i.y + 1][i.x].density;
    float d3 = current[0].cells[i.y][i.x + 1].density;
    float d4 = current[0].cells[i.y + 1][i.x + 1].density;
    float z1 = mix(d1, d2, j.x);
    float z2 = mix(d3, d4, j.x);
    float nd = mix(z1, z2, j.y);
    next[0].cells[id.y][id.x].density = nd;
}
