#include <metal_stdlib>
using namespace metal;

#define SNAKECOLUMNS 8
#define SNAKEROWS 8
#define SNAKEDEPTH 4
#define SNAKESCALE 6

float3 mapWid3D(float3 w) {
    float3 wid = w;
    if ((wid.x) > SNAKECOLUMNS - 1) { wid.x = 0; }
    if ((wid.y) > SNAKEROWS - 1) { wid.y = 0; }
    if ((wid.z) > SNAKEDEPTH - 1) { wid.z = 0; }
    if ((wid.x) < 0) { wid.x = SNAKECOLUMNS - 1; }
    if ((wid.y) < 0) { wid.y = SNAKEROWS - 1; }
    if ((wid.z) < 0) { wid.z = SNAKEDEPTH - 1; }
    return wid;
}

struct SnakeCell3D {
    float3 position;
    float3 velocity;
    float3 info;
    float density;
    char cell; // 0 field, 4 target
    uint rem;
};

struct SnakeBuffer3D {
    thread SnakeCell3D cells[SNAKECOLUMNS][SNAKEROWS];
};

struct SnakeGrids {
    thread SnakeBuffer3D grids[SNAKEDEPTH];
};

struct AdvectElement3D {
    char letter;
    float3 offset;
    SnakeCell3D correspCell;
};


#define STENCIL 8
#define STENCIL3D (STENCIL * 3 + 2)
struct Stencil3x3 {
    simd_float3 offsets[STENCIL3D];
};

uint3 stencilCell3D(uint3 gridIndex, int stencilIndex, constant float3 *stencil) {
    float3 targetPosition = float3(gridIndex) + stencil[stencilIndex];
    targetPosition = mapWid3D(targetPosition); 
    return uint3(targetPosition);
}

void fillStencill(thread AdvectElement3D *elements, constant float3 *offsets, uint3 id, constant SnakeBuffer3D *grids){
    for (int i = 0; i < STENCIL3D; i++) {
        uint3 wid = stencilCell3D(id, i, offsets);
        AdvectElement3D element;
        element.letter = i;
        element.offset = offsets[i]; 
        element.correspCell = grids[wid.z].cells[wid.x][wid.y];
        elements[i] = element;
    }
}

kernel void unitAdvectVelocitySnake3DE(constant SnakeGrids *black [[buffer(0)]],
                                       device SnakeGrids *white [[buffer(1)]],
                                       constant Stencil3x3 *stencils [[buffer(2)]],
                                       uint3 id [[thread_position_in_grid]]) {
    SnakeCell3D current = black[0].grids[id.z].cells[id.x][id.y];
    thread AdvectElement3D elements[STENCIL3D];
    fillStencill(elements, stencils[0].offsets, id, black[0].grids);
    for (int i = 0; i < STENCIL3D; i++) {
        AdvectElement3D element = elements[i];
        float3 result = element.offset + element.correspCell.velocity;
        if (length(result) == 0) {
            if ((current.rem <= 2 ) && (element.correspCell.rem == 22)) {
                white[0].grids[id.z].cells[id.x][id.y] = element.correspCell;
                white[0].grids[id.z].cells[id.x][id.y].rem += 10;
            } 
        }
    }
}

kernel void contentAdvectSnake3DE(constant SnakeGrids *black [[buffer(0)]],
                                  device SnakeGrids *white [[buffer(1)]],
                                  constant Stencil3x3 *stencils [[buffer(2)]],
                                  uint3 id [[thread_position_in_grid]]) {    
    
    white[0].grids[id.z].cells[id.x][id.y] = black[0].grids[id.z].cells[id.x][id.y];
    thread AdvectElement3D elements[STENCIL3D];
    fillStencill(elements, stencils[0].offsets, id, black[0].grids);
    for (int i = 0; i < STENCIL3D; i++) {
        AdvectElement3D element = elements[i];
        float3 result = element.offset + element.correspCell.velocity;
        if (length(result) == 0) {
            white[0].grids[id.z].cells[id.x][id.y].density += element.correspCell.density;
        }
    }
    
}

kernel void setHeadVelocityE(device SnakeGrids *current [[buffer(0)]],
                             constant float3 *velocity [[buffer(1)]],
                             constant uint *last [[buffer(2)]],
                             uint3 id [[thread_position_in_grid]]) {
    if (current[0].grids[id.z].cells[id.x][id.y].rem == 22) {
        current[0].grids[id.z].cells[id.x][id.y].velocity = velocity[0];
    }
}

kernel void cleanFieldSnake3D(constant SnakeGrids *source [[buffer(0)]],
                              device SnakeGrids *result [[buffer(1)]],
                              uint3 id [[thread_position_in_grid]]) {
    if (result[0].grids[id.z].cells[id.x][id.y].cell != 4) {
        result[0].grids[id.z].cells[id.x][id.y].density -= source[0].grids[id.z].cells[id.x][id.y].density;        
    }
    if (result[0].grids[id.z].cells[id.x][id.y].rem > 2) {
        result[0].grids[id.z].cells[id.x][id.y].rem -= 10;        
    }
}


kernel void copySnake(constant SnakeGrids *source [[buffer(0)]],
                      device SnakeGrids *target [[buffer(1)]],
                      uint3 id [[thread_position_in_grid]]) {
    target[0].grids[id.z].cells[id.x][id.y] = source[0].grids[id.z].cells[id.x][id.y];
}

kernel void captureSnake(constant SnakeGrids *source [[buffer(0)]],
                         device SnakeGrids *target [[buffer(1)]],
                         constant Stencil3x3 *stencils [[buffer(2)]],
                         uint3 id [[thread_position_in_grid]]) {
    
    SnakeCell3D current = source[0].grids[id.z].cells[id.x][id.y];
    if (current.cell != 4) { return; } // дальше выполняется лишь один тред из всей сетки
    
    thread AdvectElement3D elements[STENCIL3D];
    fillStencill(elements, stencils[0].offsets, id, source[0].grids);
    
    for (int i = 0; i < STENCIL3D; i++) {
        AdvectElement3D element = elements[i];
        float3 result = element.offset + element.correspCell.velocity;
        if ((length(result) == 0) && (element.correspCell.rem == 22)) {
            target[0].grids[id.z].cells[id.x][id.y] = element.correspCell;
            uint3 tp = uint3(float3(id) + element.offset);
            current.velocity = element.correspCell.velocity;
            current.rem = 12;
            current.cell = 0;
            target[0].grids[tp.z].cells[tp.x][tp.y] = current;
        }
    }
    

}


kernel void fillSnakeTextureToDark(texture2d<half, access::write> output [[texture(0)]],
                                   uint2 id [[thread_position_in_grid]]) {
    output.write(half4(0.5, 0.5, 0.5, 1.0), id);
}

kernel void fillSnakeTexture(constant SnakeGrids *current [[buffer(0)]],
                             texture2d<float, access::write> texture [[texture(0)]],
                             uint2 id [[thread_position_in_grid]]) {
    uint2 xy = id / SNAKESCALE;
    SnakeCell3D cell = current[0].grids[0].cells[xy.x][xy.y];
    
    float3 color = float3(0.7, 0.6, 0.5);
    
    color.r += cell.density * 0.8;
    
//    float3 ccolor = 0;
//    if (cell.cell == 0) { ccolor.r += 0.1; }
//    if (cell.cell == 1) { ccolor.g += 0.1; }
//    if (cell.cell == 2) { ccolor.b += 0.1; }
//    color += color;
    
    float3 fcolor = 0;
    fcolor.xyz = cell.velocity * 0.1;
    color += fcolor;
    
    
//    if (cell.cell == 0) {
//        color = float3(0, 1, 0);
//    }
//    
//    if (cell.cell == 1) {
//        color = float3(1, 0, 0);
//    }
//    
//    if (cell.cell == 3) {
//        color = float3(0, 0, 1);
//    }
//    
//    if (cell.cell == 2) {
//        color = float3(1, 1, 1);
//    }
    
//    if (cell.rem % 10 == 2) {
//        color += cell.rem / 100;
//    }
    
//    color = float3(0, cell.density / 3, 0);
    
    texture.write(float4(color, 1), id);
    
}


//
// делает туннель от головы змеи до края поля
//kernel void pavePath(device SnakeBuffer *back [[buffer(0)]],
//                     constant uint2 *headPosition [[buffer(1)]],
//                     uint2 id [[thread_position_in_grid]]) {
//    uint2 hindex = headPosition[0];
//    float2 v = back[0].cells[hindex.x][hindex.y].velocity; // проверить порядок v и w
//    float2 w = float2(id) - float2(headPosition[0]);
//    float wp = dot(v, w) / length(v);
//    if ((wp == length(w)) && (dot(v, w) > 0)) {
//        back[0].cells[id.x][id.y].velocity = back[0].cells[hindex.x][hindex.y].velocity;
//    }
//    
//}
