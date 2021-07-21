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
    next[0].cells[nextid.y][nextid.x].density = current[0].cells[id.y][id.x].density;
    next[0].cells[id.y][id.x].temp = float2(nextid);
}
