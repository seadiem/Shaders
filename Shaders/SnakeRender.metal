#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct SnakeVertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct SnakeVertexOut {
    float4 position [[position]];
    float3 eye;
    float3 normal;
};

matrix_float3x3 snake_matrix_float4x4_extract_linear(matrix_float4x4 m)
{
    vector_float3 X = m.columns[0].xyz;
    vector_float3 Y = m.columns[1].xyz;
    vector_float3 Z = m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return l;
}

vertex SnakeVertexOut snakeVertex(const SnakeVertexIn vertexIn [[stage_in]],
                          constant simd_float4x4 *matricies[[buffer(1)]]) {
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float4 position4 = float4(vertexIn.position, 1);

    SnakeVertexOut out;
    out.position = transformMatrix * position4;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = snake_matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye = -(modelViewMatrix * position4).xyz;  
    out.normal = normalMatrix * vertexIn.normal;
    
    return out;
}



struct SnakeLight {
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant SnakeLight light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct SnakeMaterial {
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant SnakeMaterial material = {
    .ambientColor = { 0.9, 0.1, 1 },
    .diffuseColor = { 0.9, 0.1, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

fragment float4 snakeFragment(SnakeVertexOut in [[stage_in]]) {
    
    SnakeLight light2 = light;
    light2.ambientColor += 0.5; 
    
    float3 const ambient = light2.ambientColor * material.ambientColor;
    
    float3 const normal = normalize(in.normal);
    float const intensityDiffuse = saturate(dot(normal, light.direction));  // `saturate` clamps the value between 0 and 1.
    float3 const diffuse = intensityDiffuse * (light.diffuseColor * material.diffuseColor);
    
    
    
    float3 specular(0);
    if (intensityDiffuse > 0) {
        float3 const eyeDirection = normalize(in.eye);
        float3 const halfway = normalize(light.direction + eyeDirection);
        float const specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specular = light.specularColor * material.specularColor * specularFactor;
    }
    
    return float4(ambient + diffuse + specular, 1);
    
}
