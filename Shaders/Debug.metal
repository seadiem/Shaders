#include <metal_stdlib>
using namespace metal;

struct DebugCell {
    float4 info;
};

struct DebugBuffer {
    DebugCell cells[5][3]; // Номер столбца(x), номер строки(y). (x, y) 
};

kernel void debugCells(device DebugBuffer *current [[buffer(0)]],
                      uint2 id [[thread_position_in_grid]]) {
    current[0].cells[id.x][id.y].info.xy = float2(id);
    current[0].cells[id.x][id.y].info.z = float(id.x + id.y);
}
