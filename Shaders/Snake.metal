#include <metal_stdlib>
using namespace metal;

#define SNAKECOLUMNS 8
#define SNAKEROWS 8
#define SNAKESCALE 6

float2 mapWid(float2 w) {
    float2 wid = w;
    if ((wid.x) > SNAKECOLUMNS - 1) { wid.x = 0; }
    if ((wid.y) > SNAKEROWS - 1) { wid.y = 0; }
    if ((wid.x) < 0) { wid.x = SNAKECOLUMNS - 1; }
    if ((wid.y) < 0) { wid.y = SNAKEROWS - 1; }
    return wid;
}
// 

struct SnakeCell {
    float2 velocity;
    float2 directionToNode;
    float2 directionToParrent;
    float2 info;
    float density;
    bool target;
};

struct SnakeBuffer {
    thread SnakeCell cells[SNAKECOLUMNS][SNAKEROWS];
};

struct AdvectElement {
    char letter;
    float2 offset;
    SnakeCell correspCell;
};

struct Offset {
    float2 offset;
};

#define STENCIL 8
constant Offset stencilOffsets[] = {
    {float2(-1, 1)},
    {float2( 0, 1)},
    {float2( 1, 1)},
    {float2(-1, 0)},
    {float2( 1, 0)},
    {float2(-1,-1)},
    {float2( 0,-1)},
    {float2( 1,-1)},
};

uint2 stencilCell(uint2 gridIndex, int stencilIndex) {
    float2 targetPosition = float2(gridIndex) + stencilOffsets[stencilIndex].offset;
    targetPosition = mapWid(targetPosition); 
    return uint2(targetPosition);
}

kernel void unitAdvectVelocitySnake(constant SnakeBuffer *black [[buffer(0)]],
                                    device SnakeBuffer *white [[buffer(1)]],
                                    device float4 *info [[buffer(2)]],
                                    uint2 id [[thread_position_in_grid]]) {
    
    thread AdvectElement elements[STENCIL];
    for (int i = 0; i < STENCIL; i++) {
        uint2 wid = stencilCell(id, i);
        AdvectElement element;
        element.letter = i;
        element.offset = stencilOffsets[i].offset; 
        element.correspCell = black[0].cells[wid.x][wid.y];
        elements[i] = element;
    }
    for (int i = 0; i < STENCIL; i++) {
        SnakeCell current = black[0].cells[id.x][id.y];
        AdvectElement element = elements[i];
        
        // поле
        if (length(current.velocity) == 0 &&
            current.density == 0) {}
        
        // хвост
        if (length(current.directionToParrent) > 0 &&
            length(current.directionToNode) == 0 && 
            current.density > 0) {}
        
        // середина
        if (length(current.directionToParrent) > 0 &&
            length(current.directionToNode) > 0 &&
            current.density > 0) {}
        
        // голова
        if (length(current.velocity) > 0 &&
            length(current.directionToNode) > 0 &&
            length(current.directionToParrent) == 0 &&
            current.density > 0) {}
        
        if (length(element.offset + element.correspCell.velocity) == 0) {
            white[0].cells[id.x][id.y] = element.correspCell;
        }
    }
}

kernel void swapSnake(device SnakeBuffer *source [[buffer(0)]],
                      device SnakeBuffer *target [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    
    SnakeCell current = source[0].cells[id.x][id.y];
    if (current.target == false) { return; } // дальше выполняется лишь один тред из всей сетки
    
    thread AdvectElement elements[STENCIL];
    for (int i = 0; i < STENCIL; i++) {
        uint2 wid = stencilCell(id, i);
        AdvectElement element;
        element.letter = i;
        element.offset = stencilOffsets[i].offset; 
        element.correspCell = source[0].cells[wid.x][wid.y];
        elements[i] = element;
    }
    
    for (int i = 0; i < STENCIL; i++) {
        AdvectElement element = elements[i];
        
        if (length(element.correspCell.velocity) > 0) {
            float2 eid = element.offset + float2(id);
            float2 teid = eid + element.correspCell.velocity; uint2 itied = uint2(teid);
            if (length(teid - float2(id)) == 0) {
                target[0].cells[id.x][id.y] = element.correspCell; // теперь это голова
                // теперь настраиваем ячейку откуда пришла голова
                SnakeCell tcurrent = current;
                tcurrent.velocity = 0;
                tcurrent.directionToNode = 0;
                tcurrent.directionToParrent = current.velocity;
                target[0].cells[itied.x][itied.y] = tcurrent;
                return;
            }
        }
    }
}

kernel void diffSnake(constant SnakeBuffer *black [[buffer(0)]],
                      device SnakeBuffer *white [[buffer(1)]],
                      constant float4 *info [[buffer(2)]],
                      uint2 id [[thread_position_in_grid]]) {
    if (white[0].cells[id.x][id.y].target == false) {
        white[0].cells[id.x][id.y].density -= black[0].cells[id.x][id.y].density;
        white[0].cells[id.x][id.y].velocity -= black[0].cells[id.x][id.y].velocity;
    }
}

kernel void setHeadVelocity(device SnakeBuffer *current [[buffer(0)]],
                            constant float2 *velocity [[buffer(1)]],
                            uint2 id [[thread_position_in_grid]]) {
    if (length(current[0].cells[id.x][id.y].velocity) > 0) {
        current[0].cells[id.x][id.y].velocity = velocity[0];
    }
}

kernel void fillSnakeTextureToDark(texture2d<half, access::write> output [[texture(0)]],
                                   uint2 id [[thread_position_in_grid]]) {
    output.write(half4(0.5, 0.5, 0.5, 1.0), id);
}

kernel void fillSnakeTexture(constant SnakeBuffer *current [[buffer(0)]],
                             texture2d<float, access::write> texture [[texture(0)]],
                             uint2 id [[thread_position_in_grid]]) {
    uint2 xy = id / SNAKESCALE;
    float density = current[0].cells[xy.x][xy.y].density;
    float3 color = float3(0.7, 0.6, 0.5);
    float3 dcolor = float3(0.3, 0.3, 0.3);
    dcolor *= density;
    color += dcolor;  
    texture.write(float4(color, 1), id);
    
}


//
// делает туннель от головы змеи до края поля
kernel void pavePath(device SnakeBuffer *back [[buffer(0)]],
                     constant uint2 *headPosition [[buffer(1)]],
                     uint2 id [[thread_position_in_grid]]) {
    uint2 hindex = headPosition[0];
    float2 v = back[0].cells[hindex.x][hindex.y].velocity; // проверить порядок v и w
    float2 w = float2(id) - float2(headPosition[0]);
    float wp = dot(v, w) / length(v);
    if ((wp == length(w)) && (dot(v, w) > 0)) {
        back[0].cells[id.x][id.y].velocity = back[0].cells[hindex.x][hindex.y].velocity;
    }
    
}
