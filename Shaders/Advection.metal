#include <metal_stdlib>
using namespace metal;

struct FluidCell {
    float2 velocity;
    float density;
};

struct FluidBuffer {
    FluidCell cells[10][10];
};

kernel void moveCells(device FluidBuffer *current [[buffer(0)]],
                      device FluidBuffer *next [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
//    float2 currentPosition = float2(id);
//    float2 nextPosition = currentPosition + current[0].cells[id.x][id.y].velocity;
//    uint2 nextid = uint2(nextPosition);
////    next[0].cells[nextid.x][nextid.y].density = 1.0;
//    next[0].cells[id.x][id.y].density = 1.0;
    float out;
    if ((id.x == 5) && (id.y == 5)) { out = 0; }
    else { out = 1; }
    next[0].cells[id.x][id.y].density = out;
//    next[0].cells[nextid.x][nextid.y].density = current[0].cells[id.x][id.y].density; 
}
