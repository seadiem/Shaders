#include <metal_stdlib>
using namespace metal;

struct Pixel {
    uint ids[5];
    float2 velocity;
    float4 color;
};

struct Buffer {
    Pixel pixels[40][30];
};

kernel void movePixel(device Buffer *previews [[buffer(0)]],
                      device Buffer *nexts [[buffer(1)]],
                      uint2 id [[thread_position_in_grid]]) {
    nexts[0].pixels[id.x][id.y] = previews[0].pixels[id.x][id.y];
//    Pixel pixel;
//    pixel.velocity = float2(30, 30);
//    pixel.color = float4(id.x, id.y, 1, 1);
//    pixel.ids[0] = 1;
//    pixel.ids[1] = 2;
//    pixel.ids[2] = 3;
//    pixel.ids[3] = 4;
//    pixel.ids[4] = 5;
//    nexts[0].pixels[id.x][id.y] = pixel;
}

kernel void movePixelLight(device Pixel *previews [[buffer(0)]],
                           device Pixel *nexts [[buffer(1)]],
                           uint id [[thread_position_in_grid]]) {
    //    nexts[0].pixels[id.x][id.y] = previews[0].pixels[id.x][id.y];
    Pixel pixel;
    pixel.velocity = float2(20, 10);
    nexts[id] = pixel;
}
