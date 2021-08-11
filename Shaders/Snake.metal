#include <metal_stdlib>
using namespace metal;

struct SnakeCell {
    bool head;
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


bool directToMe(float2 offset, SnakeCell source) {
    if (length(offset - source.velocity) == 0) { return true; }
    else { return false; }
}

struct AdvectElement {
    char letter;
    float2 offset;
    SnakeCell correspCell;
};

kernel void unitAdvectVelocitySnake(device SnakeBuffer *black [[buffer(0)]],
                                    device SnakeBuffer *white [[buffer(1)]],
                                    uint2 id [[thread_position_in_grid]]) {
    
    AdvectElement elements[8];
    
    float2 e = float2(id);
    float2 a = e + float2(-1, 1);
    float2 b = e + float2( 0, 1);
    float2 c = e + float2( 1, 1);
    float2 d = e + float2(-1, 0);
    e = e;
    float2 f = e + float2( 1, 0);
    float2 g = e + float2(-1,-1);
    float2 h = e + float2( 0,-1);
    float2 j = e + float2( 1,-1);
    
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
    
    for (int i = 0 ; i < 8 ; i++ ) {
        AdvectElement element = elements[i];
        if (length(element.offset + element.correspCell.velocity) == 0) {
            white[0].cells[id.x][id.y] = element.correspCell; 
            // сделать среднее значение если более чем одна  указывает на клетку
            break;
        }
    }
}

kernel void advectVelocitySnake(device SnakeBuffer *black [[buffer(0)]],
                                device SnakeBuffer *white [[buffer(1)]],
                                uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) + black[0].cells[id.x][id.y].velocity;
    float2 ij; 
    ij.xy = floor(p * 2);
    int2 i = int2(ij);
    float2 d11 = black[0].cells[i.x][i.y].velocity;
    float2 d21 = black[0].cells[i.x + 1][i.y].velocity;
    float2 d12 = black[0].cells[i.x][i.y + 1].velocity;
    float2 d22 = black[0].cells[i.x + 1][i.y + 1].velocity;
    if ((p.x < 0) || (p.y < 0)) {
        d11 = 0, d21 = 0, d12 = 0, d22 = 0;
    }
    float2 a = p - ij.xy;
    white[0].cells[id.x][id.y].velocity = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
}


kernel void advectDensitySnake(device SnakeBuffer *black [[buffer(0)]],
                               device SnakeBuffer *white [[buffer(1)]],
                               uint2 id [[thread_position_in_grid]]) {
    float2 p = float2(id) - black[0].cells[id.x][id.y].velocity;
    float2 ij; 
    ij.xy = floor(p);
    int2 i = int2(ij);
    float d11 = black[0].cells[i.x][i.y].density;
    float d21 = black[0].cells[i.x + 1][i.y].density;
    float d12 = black[0].cells[i.x][i.y + 1].density;
    float d22 = black[0].cells[i.x + 1][i.y + 1].density;
    if ((p.x < 0) || (p.y < 0)) {
        d11 = 0, d21 = 0, d12 = 0, d22 = 0;
    }
    float2 a = p - ij.xy;
    white[0].cells[id.x][id.y].density = mix(mix(d11, d21, a.x), mix(d12, d22, a.x), a.y);
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

kernel void moveBlackToWhite(device SnakeBuffer *black [[buffer(0)]],
                             device SnakeBuffer *white [[buffer(1)]],
                             uint2 id [[thread_position_in_grid]],
                             uint2 idp [[thread_position_in_threadgroup]]) {
    white[0].cells[id.x][id.y] = black[0].cells[id.x][id.y]; 
//    white[0].cells[n.x][n.y] = black[0].cells[id.x][id.y];
    white[0].cells[id.x][id.y].temp = white[0].cells[id.x][id.y].velocity; 
    
//    threadgroup bool usedIndex[SNAKECOLUMNS][SNAKEROWS];
    float2 velocity = black[0].cells[id.x][id.y].velocity;
    if (length(velocity) > 0) {
        float2 diastanation = float2(id) + black[0].cells[id.x][id.y].velocity;
        int2 next = int2(diastanation);
        white[0].cells[next.x][next.y] = black[0].cells[id.x][id.y];
    }
   
    
//    threadgroup bool usedIndex[100][100];
//    if (usedIndex[n.x][n.y] == false) {
//        SnakeCell currentNext = white[0].cells[n.x][n.y];
//        currentNext.density += black[0].cells[id.x][id.y].density;
//        currentNext.velocity =  black[0].cells[id.x][id.y].velocity;
//        white[0].cells[n.x][n.y] = currentNext;
//        usedIndex[n.x][n.y] = true;
//    }
//    if (black[0].cells[id.x][id.y].density > 0) {
//        white[0].cells[n.x][n.y] = black[0].cells[id.x][id.y];
//    }
}

kernel void copySnake(device SnakeBuffer *source [[buffer(0)]],
                      device SnakeBuffer *target [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    target[0].cells[id.x][id.y] = source[0].cells[id.x][id.y];
}

kernel void diffSnake(device SnakeBuffer *black [[buffer(0)]],
                      device SnakeBuffer *white [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    if (white[0].cells[id.x][id.y].tail == false) {
        white[0].cells[id.x][id.y].density -= black[0].cells[id.x][id.y].density;
        white[0].cells[id.x][id.y].velocity -= black[0].cells[id.x][id.y].velocity;
    }
}


kernel void moveSnakeCells(device SnakeBuffer *current [[buffer(0)]],
                           uint2 id [[thread_position_in_grid]]) {
    if (current[0].cells[id.x][id.y].density > 0) {
        int2 n = int2(float2(id) + current[0].cells[id.x][id.y].velocity);
        current[0].cells[n.x][n.y] = current[0].cells[id.x][id.y];
        current[0].cells[id.x][id.y].head = false;
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
