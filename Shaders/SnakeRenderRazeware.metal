#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct VertexInRazeware {
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOutRazeware {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float density;
};

struct RazewareUniforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float3x3 normalMatrix;
};

struct SnakeFridgeUniforms {
    simd_float3x3 fridgeNormalMatrix;
    simd_float4x4 fridgeModelMatrix;
    simd_float4x4 cameraModelMatrix;
    simd_float4x4 cameraProjectionMatrix;
};

struct CoubeTransform {
    simd_float4x4 modelMatrix;
    simd_float3x3 normalMatrix;
};

struct FragmentUniforms {
    char lightCount;
    simd_float3 cameraPosition;
};

struct LightRazeware
{
    float3 position;
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant LightRazeware razelight = {
    .position = {1, 2, 2},
    .direction = { 1, 1, 1 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};
    

struct SnakeRazewareCell {
    float2 position;
    float2 velocity;
    float2 info;
    float density;
    char cell; // 0 field, 1 body, 2 head, 3 target
    char velocityAllow;
};

#define SNAKECOLUMNSRAZE 9
#define SNAKEROWSRAZE 9
#define SNAKESCALERAZE 6

vertex VertexOutRazeware vertexMainRazewareInstancing(const VertexInRazeware vertexIn [[stage_in]],
                                                      constant SnakeFridgeUniforms *uniforms [[buffer(1)]],
                                                      constant CoubeTransform *transforms [[buffer(2)]],
                                                      constant SnakeRazewareCell *white [[buffer(3)]],
                                                      uint instanceID [[instance_id]]) {
    SnakeRazewareCell cell = white[instanceID];
    float4x4 modelCellMatrix = float4x4(1);
    modelCellMatrix[3][0] = (cell.position.x - SNAKECOLUMNSRAZE / 2) * 5;
    modelCellMatrix[3][1] = (cell.position.y - SNAKEROWSRAZE / 2) * 5;
    VertexOutRazeware out {
        .position = uniforms[0].cameraProjectionMatrix * 
                    uniforms[0].cameraModelMatrix * 
                    uniforms[0].fridgeModelMatrix * 
                    modelCellMatrix *
                    vertexIn.position,
        .worldPosition = (uniforms[0].fridgeModelMatrix * modelCellMatrix * vertexIn.position).xyz,
        .worldNormal = uniforms[0].fridgeNormalMatrix * vertexIn.normal,
        .density = cell.density
    };
    return out;
}

vertex VertexOutRazeware vertexMainRazeware(const VertexInRazeware vertexIn [[stage_in]],
                                            constant RazewareUniforms *uniforms [[buffer(1)]],
                                            constant simd_float4x4 *matricies [[buffer(2)]]) {
    VertexOutRazeware out {
        .position = uniforms[0].projectionMatrix * uniforms[0].viewMatrix * uniforms[0].modelMatrix * vertexIn.position,
        .worldPosition = (uniforms[0].modelMatrix * vertexIn.position).xyz,
        .worldNormal = uniforms[0].normalMatrix * vertexIn.normal };
    return out;
}

fragment float4 fragmentMainRazeware(VertexOutRazeware in [[stage_in]],
                                     constant FragmentUniforms *fragmentUniforms [[buffer(1)]]) {
    
    
    float4 sky = float4(0.34, 0.9, 1.0, 1.0);
    float4 earth = float4(0.29, 0.58, 0.2, 1.0);
    float intensity = in.worldNormal.y * 0.5 + 0.5;
    float4 grasslight = mix(earth, sky, intensity);
    
    LightRazeware light = razelight;
    float3 normalDirection = normalize(in.worldNormal);
    
    float3 baseColor = float3(0.4, 0.5, 0.6);
    baseColor *= in.density;
    float3 diffuseColor = float3(0, 0, 0);
    float3 ambientColor = float3(0.4, 0.1, 0.1);
    float3 specularColor = float3(0, 0, 0);
    float3 materialSpecularColor = float3(0, 1, 0);
    float materialShininess = 32;
    
    float3 lightDirection = normalize(light.position);
    float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
    diffuseColor += light.diffuseColor * baseColor * diffuseIntensity;
    if (diffuseIntensity > 0) {
        float3 reflection =
        reflect(lightDirection, normalDirection);
        float3 cameraDirection = normalize(in.worldPosition + fragmentUniforms[0].cameraPosition);
        float specularIntensity = pow(saturate(dot(reflection, cameraDirection)), materialShininess);
        specularColor += light.specularColor * materialSpecularColor * specularIntensity;
    }
    float3 color = diffuseColor + ambientColor + specularColor;
    float4 sunlight = float4(color, 1);
    
    float4 out = max(grasslight, sunlight);
    return out + sunlight / 5;
}
