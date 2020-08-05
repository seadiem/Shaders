#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct LightTwo
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant LightTwo light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct MaterialTwo
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant MaterialTwo material = {
    .ambientColor = { 0.9, 0.1, 1 },
    .diffuseColor = { 0.9, 0.1, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};


struct OutVertexTwo
{

    float4 position [[position]];
    float pointsize[[point_size]];
    
    float3 eye;
    float3 normal;
    
    float2 uv;
    int textnumber;
    float4 color;
    float4 material;
    bool  toLights;
    bool hasTexture;
    
};

matrix_float3x3 matrix_float4x4_extract_linear_two(matrix_float4x4 m)
{
    vector_float3 X = m.columns[0].xyz;
    vector_float3 Y = m.columns[1].xyz;
    vector_float3 Z = m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return l;
}

vertex OutVertexTwo vertexLightingShaderAlphaTextureZero(uint vertexID [[vertex_id]],
                                                        constant float3 *vertices [[buffer(0)]],
                                                        constant float3 *normals [[buffer(1)]],
                                                        constant float4 *colors[[buffer(2)]],
                                                        constant simd_float4x4 *matricies[[buffer(3)]],
                                                        constant bool *tolifgts[[buffer(4)]],
                                                        constant float3 *uv[[buffer(5)]],
                                                        constant bool *verexHasTexture[[buffer(6)]],
                                                        constant float4 *material[[buffer(7)]],
                                                        constant bool *ismesh[[buffer(8)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertexTwo out;
    out.position = transformMatrix * position4;
    out.color = colors[vertexID];
    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear_two(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normals[vertexID];
    
    out.uv = uv[vertexID].xy;
    out.textnumber = int(uv[vertexID].z);
    out.hasTexture = verexHasTexture[vertexID];
    out.toLights = tolifgts[0];
    out.material = material[vertexID];
    
    return out;
}

fragment float4 fragment_light_texture_zero(OutVertexTwo vert [[stage_in]],
                                            constant bool *hasTexture [[buffer(0)]],
                                            constant float *specularF [[buffer(1)]],
                                            constant float2 *darkFactor [[buffer(2)]],
                                            texture2d<float> diffuseTexture0 [[texture(0)]],
                                            texture2d<float> diffuseTexture1 [[texture(1)]],
                                            texture2d<float> diffuseTexture2 [[texture(2)]],
                                            sampler samplr [[sampler(0)]]) {
    
    bool lighting = true;
    bool totexturing = hasTexture[0];
    float specularK = specularF[0];
    float2 darkF = darkFactor[0];
    
    float4 pixelcolor;
    if (vert.hasTexture && totexturing) {
        texture2d<float> texture;
        if (vert.textnumber == 0) { texture = diffuseTexture0; }
        else if (vert.textnumber == 1) { texture = diffuseTexture1; }
        else if (vert.textnumber == 2) { texture = diffuseTexture2; }
        else { texture = diffuseTexture0; }
        pixelcolor = float4(texture.sample(samplr, vert.uv).rgba);
        if (pixelcolor.g > 0.9) {
            lighting = false;
        } 
    } else { 
        pixelcolor = vert.color; 
    }
    
    if (pixelcolor.a == 0) {
        pixelcolor = vert.color;
    }
    
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(vert.normal);
    float dk = 1;
    if (vert.hasTexture && totexturing) { dk = 0.5; }
    float diffuseIntensity = saturate(dot(normal, light.direction));
    if (lighting == false) {
        if (diffuseIntensity < 1) {
            diffuseIntensity = 1;
        }
    }
    if (diffuseIntensity < 0.3 ) {
        diffuseIntensity = 0.3;
    }
    
    
    float morelight = 1.0;
    if (darkF.x > 0) { morelight = darkF.y; }
    
    float3 diffuseTerm = light.diffuseColor * pixelcolor.rgb * diffuseIntensity * morelight;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower) * dk * specularK;
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    
    float4 shadedlight;
    if (vert.toLights == true) { shadedlight = float4(ambientTerm + diffuseTerm + specularTerm, pixelcolor.a); }
    else { shadedlight = pixelcolor; }
    
//    if (vert.toLights == true) { return float4(ambientTerm + diffuseTerm + specularTerm, pixelcolor.a); }
//    else { return pixelcolor; }
    
    float ballancex = vert.material.x;
    float ballancey = vert.material.y;
    
//    float ballancex = 0.0;
//    float ballancey = 1.0;
    
    float4 shadedlightbalanced = shadedlight * ballancex;
    float4 initialballance = pixelcolor * ballancey;
    float4 resultcolor = shadedlightbalanced + initialballance;
    resultcolor.a = pixelcolor.a;
    return resultcolor;
    

    
    // k
    // [-----/--] = 1
    // lifgting / solid
}

struct OutVertexDote
{
    float4 position [[position]];
    float pointsize[[point_size]];
    float4 color;    
};

vertex OutVertexDote doteVertex(uint vertexID [[vertex_id]],
                                constant float3 *vertices [[buffer(0)]],
                                constant float4 *colors[[buffer(1)]],
                                constant simd_float4x4 *matricies[[buffer(2)]] )
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertexDote out;
    out.position = transformMatrix * position4;
    out.color = colors[vertexID];
    out.pointsize = 1;
    
    
    return out;
}

fragment float4 doteFragment(OutVertexDote vert [[stage_in]]) {
    return vert.color;
}
