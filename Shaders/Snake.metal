#include <metal_stdlib>
using namespace metal;

#define SNAKECOLUMNS 9
#define SNAKEROWS 9
#define SNAKESCALE 6

float2 mapWid(float2 w) {
    float2 wid = w;
    if ((wid.x) > SNAKECOLUMNS - 1) { wid.x = 0; }
    if ((wid.y) > SNAKEROWS - 1) { wid.y = 0; }
//    if ((wid.x) < 0) { wid.x = SNAKECOLUMNS - 1; }
//    if ((wid.y) < 0) { wid.y = SNAKEROWS - 1; }
    return wid;
}


// 

struct SnakeCell {
    float2 velocity;
    float2 info;
    float density;
    char cell; // 0 field, 1 body, 2 head, 3 target
    bool velocityAllow;
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
                                    device SnakeBuffer *debug3 [[buffer(3)]],
                                    device SnakeBuffer *debug2 [[buffer(4)]],
                                    device SnakeBuffer *debug1 [[buffer(5)]],
                                    uint2 id [[thread_position_in_grid]]) {
    debug3[0].cells[id.x][id.y] = black[0].cells[id.x][id.y];
    debug2[0].cells[id.x][id.y] = white[0].cells[id.x][id.y];
    thread AdvectElement elements[STENCIL];
    for (int i = 0; i < STENCIL; i++) {
        uint2 wid = stencilCell(id, i);
        AdvectElement element;
        element.letter = i;
        element.offset = stencilOffsets[i].offset; 
        element.correspCell = black[0].cells[wid.x][wid.y];
        elements[i] = element;
    }
    float2 c = float2(id);
    for (int i = 0; i < STENCIL; i++) {
        AdvectElement element = elements[i];
        float2 n = c + element.offset + element.correspCell.velocity;
        if (length(c - n) == 0) {
            white[0].cells[id.x][id.y].cell = element.correspCell.cell;
            white[0].cells[id.x][id.y].density = element.correspCell.density;
            if (black[0].cells[id.x][id.y].velocityAllow) {
                white[0].cells[id.x][id.y].velocity = element.correspCell.velocity;
            }
        }
    }
    debug1[0].cells[id.x][id.y] = white[0].cells[id.x][id.y];
}

kernel void setHeadVelocity(device SnakeBuffer *current [[buffer(0)]],
                            constant float2 *velocity [[buffer(1)]],
                            uint2 id [[thread_position_in_grid]]) {
    if (current[0].cells[id.x][id.y].cell == 2) {
        current[0].cells[id.x][id.y].velocity = velocity[0];
        current[0].cells[id.x][id.y].velocityAllow = false;        
    }
}

kernel void diffSnake(constant SnakeBuffer *black [[buffer(0)]],
                      device SnakeBuffer *white [[buffer(1)]],
                      constant float4 *info [[buffer(2)]],
                      device SnakeBuffer *debug1 [[buffer(3)]],
                      device SnakeBuffer *debug2 [[buffer(4)]],
                      uint2 id [[thread_position_in_grid]]) {
    debug1[0].cells[id.x][id.y] = white[0].cells[id.x][id.y];
    debug2[0].cells[id.x][id.y] = black[0].cells[id.x][id.y];
//    white[0].cells[id.x][id.y].density -= black[0].cells[id.x][id.y].density;
    //   white[0].cells[id.x][id.y].velocity -= black[0].cells[id.x][id.y].velocity;
}

kernel void copySnake(constant SnakeBuffer *source [[buffer(0)]],
                      device SnakeBuffer *target [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    target[0].cells[id.x][id.y] = source[0].cells[id.x][id.y];
}

kernel void captureSnake(constant SnakeBuffer *source [[buffer(0)]],
                         device SnakeBuffer *target [[buffer(1)]],
                         uint2 id [[thread_position_in_grid]]) {
    
    SnakeCell current = source[0].cells[id.x][id.y];
    if (current.cell != 3) { return; } // дальше выполняется лишь один тред из всей сетки
    
    thread AdvectElement elements[STENCIL];
    for (int i = 0; i < STENCIL; i++) {
        uint2 wid = stencilCell(id, i);
        AdvectElement element;
        element.letter = i;
        element.offset = stencilOffsets[i].offset; 
        element.correspCell = source[0].cells[wid.x][wid.y];
        elements[i] = element;
    }
    float2 c = float2(id);
    for (int i = 0; i < STENCIL; i++) {
        AdvectElement element = elements[i];
        if (element.correspCell.cell == 2) {
            float2 n = c + element.offset + element.correspCell.velocity;
            if (length(c - n) == 0) {
                target[0].cells[id.x][id.y] = element.correspCell;
                uint2 zid = uint2(c + element.offset);
                target[0].cells[zid.x][zid.y].cell = 1;
                return;
            }
        }
    }
}

kernel void swapSnake(device SnakeBuffer *source [[buffer(0)]],
                      device SnakeBuffer *target [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    
//    SnakeCell current = source[0].cells[id.x][id.y];
//    if (current.cell == 2) { return; } // дальше выполняется лишь один тред из всей сетки
//    
//    thread AdvectElement elements[STENCIL];
//    for (int i = 0; i < STENCIL; i++) {
//        uint2 wid = stencilCell(id, i);
//        AdvectElement element;
//        element.letter = i;
//        element.offset = stencilOffsets[i].offset; 
//        element.correspCell = source[0].cells[wid.x][wid.y];
//        elements[i] = element;
//    }
//    
//    for (int i = 0; i < STENCIL; i++) {
//        AdvectElement element = elements[i];
//    }
}

kernel void fillSnakeTextureToDark(texture2d<half, access::write> output [[texture(0)]],
                                   uint2 id [[thread_position_in_grid]]) {
    output.write(half4(0.5, 0.5, 0.5, 1.0), id);
}

kernel void fillSnakeTexture(constant SnakeBuffer *current [[buffer(0)]],
                             texture2d<float, access::write> texture [[texture(0)]],
                             uint2 id [[thread_position_in_grid]]) {
    uint2 xy = id / SNAKESCALE;
    SnakeCell cell = current[0].cells[xy.x][xy.y];
    
    float3 color = float3(0.7, 0.6, 0.5);
    
    float3 dcolor = float3(0.3, 0.3, 0.3);
    dcolor *= cell.density;
    color += dcolor;  
    
//    float3 ccolor = 0;
//    if (cell.cell == 0) { ccolor.r += 0.1; }
//    if (cell.cell == 1) { ccolor.g += 0.1; }
//    if (cell.cell == 2) { ccolor.b += 0.1; }
//    color += color;
    
    float3 fcolor = 0;
    fcolor.xy = cell.velocity * 0.1;
    color += fcolor;
    
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
