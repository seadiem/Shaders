#include <metal_stdlib>
using namespace metal;

struct DebugCell {
    float4 info;
};

struct DebugBuffer {
    DebugCell cells[8][3]; // Column number(x), Row number(y). (x, y) 
};

kernel void debugCells(device DebugBuffer *current [[buffer(0)]],
                      uint2 id [[thread_position_in_grid]]) {
    current[0].cells[id.x][id.y].info.xy = float2(id);
    current[0].cells[id.x][id.y].info.z = float(id.x + id.y);
}

/*
 after reshape for printing on CPU it prints
 [[0.0,0.0], [1.0,0.0], [2.0,0.0], [3.0,0.0], [4.0,0.0], [5.0,0.0], [6.0,0.0], [7.0,0.0]]
 [[0.0,1.0], [1.0,1.0], [2.0,1.0], [3.0,1.0], [4.0,1.0], [5.0,1.0], [6.0,1.0], [7.0,1.0]]
 [[0.0,2.0], [1.0,2.0], [2.0,2.0], [3.0,2.0], [4.0,2.0], [5.0,2.0], [6.0,2.0], [7.0,2.0]]
 */
