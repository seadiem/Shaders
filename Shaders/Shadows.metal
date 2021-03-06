#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct LightOne
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant LightOne light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct MaterialOne
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant MaterialOne material = {
    .ambientColor = { 0.9, 0.1, 1 },
    .diffuseColor = { 0.9, 0.1, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};


struct OutVertexOne
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];
    float pointsize[[point_size]];
    
    float3 eye;
    float3 normal;
    float2 uv;
    
    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
    bool  toLights;
    bool hasTexture;
    int textureNumber;
    
};

matrix_float3x3 matrix_float4x4_extract_linear_one(matrix_float4x4 m)
{
    vector_float3 X = m.columns[0].xyz;
    vector_float3 Y = m.columns[1].xyz;
    vector_float3 Z = m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return l;
}

vertex OutVertexOne vertexLightingShaderAlphaTextureTwo(uint vertexID [[vertex_id]],
                                                  constant float3 *vertices [[buffer(0)]],
                                                  constant float3 *normals [[buffer(1)]],
                                                  constant float4 *colors[[buffer(2)]],
                                                  constant simd_float4x4 *matricies[[buffer(3)]],
                                                  constant bool *tolifgts[[buffer(4)]],
                                                  constant float2 *uv[[buffer(5)]],
                                                  constant bool *hasTexture[[buffer(6)]],
                                                  constant int *textureNumber[[buffer(7)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertexOne out;
    out.position = transformMatrix * position4;
    out.color = colors[vertexID];
    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear_one(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normals[vertexID];
    
    out.toLights = tolifgts[0];
    
    out.uv = uv[vertexID];
    out.hasTexture = hasTexture[0];
    out.hasTexture = true; //!
    out.toLights = false;
    out.textureNumber = textureNumber[vertexID];
    
    return out;
}

fragment float4 fragment_light_texture_two(OutVertexOne vert [[stage_in]], 
                                       texture2d<float> diffuseTexture [[texture(0)]], 
                                       sampler samplr [[sampler(0)]]) {
    
    float4 pixelcolor;
    if (vert.hasTexture) { pixelcolor = float4(diffuseTexture.sample(samplr, vert.uv).rgb, vert.color.a); } 
    else { pixelcolor = vert.color; }
    
    //    return pixelcolor;
    
    float3 ambientTerm = light.ambientColor * pixelcolor.rgb;
    
    float3 normal = normalize(vert.normal);
    float diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = light.diffuseColor * pixelcolor.rgb * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    
    if (vert.toLights == true) { return float4(ambientTerm + diffuseTerm + specularTerm, vert.color.a); }
    else { return pixelcolor; }
    
}
