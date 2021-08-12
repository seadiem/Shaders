#include <metal_stdlib>
using namespace metal;

struct SnakeCell {
    short head;
    bool tail;
    short number;
    float density;
    float2 velocity;
    float2 temp;
};

#define SNAKECOLUMNS 8
#define SNAKEROWS 8
#define SNAKESCALE 6

struct SnakeBuffer {
    SnakeCell cells[SNAKECOLUMNS][SNAKEROWS];
};

struct AdvectElement {
    char letter;
    float2 offset;
    SnakeCell correspCell;
};

float2 mapWid(float2 w) {
    float2 wid = w;
    if ((wid.x) > SNAKECOLUMNS - 1) { wid.x = 0; }
    if ((wid.y) > SNAKEROWS - 1) { wid.y = 0; }
    if ((wid.x) < 0) { wid.x = SNAKECOLUMNS - 1; }
    if ((wid.y) < 0) { wid.y = SNAKEROWS - 1; }
    return wid;
}

kernel void unitAdvectVelocitySnake(constant SnakeBuffer *black [[buffer(0)]],
                                    device SnakeBuffer *white [[buffer(1)]],
                                    device float4 *info [[buffer(2)]],
                                    uint2 id [[thread_position_in_grid]]) {
    
    AdvectElement elements[8];
    
    float2 e = float2(id);
    float2 a = e + float2(-1, 1); a = mapWid(a);
    float2 b = e + float2( 0, 1); b = mapWid(b);
    float2 c = e + float2( 1, 1); c = mapWid(c);
    float2 d = e + float2(-1, 0); d = mapWid(d);
    e = e;
    float2 f = e + float2( 1, 0); f = mapWid(f);
    float2 g = e + float2(-1,-1); g = mapWid(g);
    float2 h = e + float2( 0,-1); h = mapWid(h);
    float2 j = e + float2( 1,-1); j = mapWid(j);
    
    uint2 wid;
    AdvectElement element;
    element.letter = 'a';
    element.offset = float2(-1, 1); wid = uint2(a);
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[0] = element;
    
    element.letter = 'b';
    element.offset = float2(0, 1); wid = uint2(b);
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[1] = element;
    
    element.letter = 'c';
    element.offset = float2(1, 1); wid = uint2(c);
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[2] = element;
    
    element.letter = 'd';
    element.offset = float2(-1, 0); wid = uint2(d);
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[3] = element;
    
    element.letter = 'f';
    element.offset = float2(1, 0); wid = uint2(f); 
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[4] = element;
    
    element.letter = 'g';
    element.offset = float2(-1,-1); wid = uint2(g); 
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[5] = element;
    
    element.letter = 'h';
    element.offset = float2(0,-1); wid = uint2(h); 
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[6] = element;
    
    element.letter = 'j';
    element.offset = float2(1, -1); wid = uint2(j); 
    element.correspCell = black[0].cells[wid.x][wid.y];
    elements[7] = element;
    
    for (int i = 0; i < 8; i++) {
        AdvectElement element = elements[i];
        if (length(element.offset + element.correspCell.velocity) == 0) {
            white[0].cells[id.x][id.y] = element.correspCell;
            // сделать среднее значение если более чем одна  указывает на клетку
            break;
        }
    }
    if (white[0].cells[id.x][id.y].head == 1) {
        info[0] = float4(id.x, id.y, 7, 7);        
    }
}

kernel void copySnake(device SnakeBuffer *source [[buffer(0)]],
                      device SnakeBuffer *target [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    target[0].cells[id.x][id.y] = source[0].cells[id.x][id.y];
}

kernel void diffSnake(constant SnakeBuffer *black [[buffer(0)]],
                      device SnakeBuffer *white [[buffer(1)]],
                      constant float4 *info [[buffer(2)]],
                      uint2 id [[thread_position_in_grid]]) {
    white[0].cells[id.x][id.y].density -= black[0].cells[id.x][id.y].density;
    white[0].cells[id.x][id.y].velocity -= black[0].cells[id.x][id.y].velocity;
    white[0].cells[id.x][id.y].head -= black[0].cells[id.x][id.y].head;
//    float2 head = info[0].xy;
//    float2 fid = float2(id);
//    if ((head.x == fid.x) && (head.y == fid.y)) {
//        white[0].cells[id.x][id.y].head = 1;
//    } else {
//        white[0].cells[id.x][id.y].head = 0;
//    }
}


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

kernel void setHeadVelocity(device SnakeBuffer *current [[buffer(0)]],
                            constant float2 *velocity [[buffer(1)]],
                            uint2 id [[thread_position_in_grid]]) {
    if (current[0].cells[id.x][id.y].head) {
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
