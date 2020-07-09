#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

matrix_float3x3 matrix_float4x4_extract_linear(matrix_float4x4 m)
{
    vector_float3 X = m.columns[0].xyz;
    vector_float3 Y = m.columns[1].xyz;
    vector_float3 Z = m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return l;
}

struct Light
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct Material
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant Material material = {
    .ambientColor = { 0.9, 0.1, 1 },
    .diffuseColor = { 0.9, 0.1, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

// Vertex shader outputs and fragment shader inputs
struct OutVertex
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

struct VertexPack
{
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
};

vertex OutVertex vertexLightingShaderMeshesIndex(constant VertexPack *v [[buffer(0)]], 
                                                           constant simd_float4x4 *matricies[[buffer(3)]], 
                                                           uint vertexID [[vertex_id]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    VertexPack in = v[vertexID];
    float3 position3 = in.position;
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    //    out.color.rgb = colors[vertexID].rgb;
    //    out.color.a = 1.0;
    //    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * in.normal;
    
    //    out.toLights = tolifgts[0];
    
    return out;
}

vertex OutVertex vertexLightingShaderMeshesIndexAndNormals(constant VertexPack *v [[buffer(8)]], 
                                                 constant float3 *normals [[buffer(1)]],
                                                 constant float4 *colors[[buffer(2)]],
                                                 constant simd_float4x4 *matricies[[buffer(3)]],
                                                 constant bool *tolifgts[[buffer(4)]],
                                                 constant float2 *uv[[buffer(5)]],
                                                 constant bool *hasTexture[[buffer(6)]],
                                                 constant int *textureNumber[[buffer(7)]],
                                                 constant float3 *vertices [[buffer(0)]],
                                                 constant bool *isMesh [[buffer(9)]],
                                                 uint vertexID [[vertex_id]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3;
    float3 normal;
    bool ismesh = isMesh[0];
    
//    VertexPack in = v[vertexID];
//    position3 = in.position;
//    normal = in.normal;
    
//    position3 = vertices[vertexID];
//    normal = normals[vertexID];
    
    if (ismesh) {
        VertexPack in = v[vertexID];
        position3 = in.position;
        normal = in.normal;
    } else {
        position3 = vertices[vertexID];
        normal = normals[vertexID];
    }
    
 
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    //    out.color.rgb = colors[vertexID].rgb;
    //    out.color.a = 1.0;
    //    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normal;
    
    //    out.toLights = tolifgts[0];
    
    return out;
}

vertex OutVertex vertexLightingShaderMeshes(const VertexPack v [[stage_in]], constant simd_float4x4 *matricies[[buffer(3)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = v.position.xyz;
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
//    out.color.rgb = colors[vertexID].rgb;
//    out.color.a = 1.0;
//    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
//    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
 //   out.normal = normalMatrix * normals[vertexID];
    
//    out.toLights = tolifgts[0];
    
    return out;
}

vertex OutVertex vertexLightingShaderAlphaTexture(uint vertexID [[vertex_id]],
                                                  constant float3 *vertices [[buffer(0)]],
                                                  constant float3 *normals [[buffer(1)]],
                                                  constant float4 *colors[[buffer(2)]],
                                                  constant simd_float4x4 *matricies[[buffer(3)]],
                                                  constant bool *tolifgts[[buffer(4)]],
                                                  constant float2 *uv[[buffer(5)]],
                                                  constant bool *hasTexture[[buffer(6)]]
                                                  // constant int *textureNumber[[buffer(7)]]
                                                  )
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    out.color = colors[vertexID];
    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normals[vertexID];
    
    out.toLights = tolifgts[0];
    
    out.uv = uv[vertexID];
    out.hasTexture = hasTexture[0];
    out.hasTexture = true; //!
    out.toLights = false;
//    out.textureNumber = textureNumber[vertexID];
    
    return out;
}

vertex OutVertex vertexLightingShaderAlpha(uint vertexID [[vertex_id]],
                                      constant float3 *vertices [[buffer(0)]],
                                      constant float3 *normals [[buffer(1)]],
                                      constant float4 *colors[[buffer(2)]],
                                      constant simd_float4x4 *matricies[[buffer(3)]],
                                      constant bool *tolifgts[[buffer(4)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    out.color = colors[vertexID];
    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normals[vertexID];
    
    out.toLights = tolifgts[0];
    
    return out;
}

vertex OutVertex vertexLightingShader(uint vertexID [[vertex_id]],
                     constant float3 *vertices [[buffer(0)]],
                     constant float3 *normals [[buffer(1)]],
                     constant float3 *colors[[buffer(2)]],
              constant simd_float4x4 *matricies[[buffer(3)]],
                       constant bool *tolifgts[[buffer(4)]])
{
    
    simd_float4x4 projectionMatrix = matricies[0];
    simd_float4x4 viewMatrix = matricies[1];
    simd_float4x4 modelMatrix = matricies[2];
    simd_float4x4 transformMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    float3 position3 = vertices[vertexID];
    float4 position4;
    position4.xyz = position3;
    position4.w = 1.0;
    
    OutVertex out;
    out.position = transformMatrix * position4;
    out.color.rgb = colors[vertexID].rgb;
    out.color.a = 1.0;
    out.pointsize = 5;
    
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    simd_float3x3 normalMatrix = matrix_float4x4_extract_linear(modelViewMatrix);
    out.eye =  -(modelViewMatrix * position4).xyz;    
    out.normal = normalMatrix * normals[vertexID];
    
    out.toLights = tolifgts[0];
    
    return out;
}

fragment float4 fragment_light_texture(OutVertex vert [[stage_in]], 
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

fragment float4 fragment_light_mesh(OutVertex vert [[stage_in]]) {
    
//    float4 pixelcolor;
//    if (vert.hasTexture) { pixelcolor = float4(diffuseTexture.sample(samplr, vert.uv).rgb, vert.color.a); } 
//    else { pixelcolor = vert.color; }
    
    float4 pixelcolor = float4(0.5, 0.5, 0.7, 1.0);
    
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
    
    return float4(ambientTerm * 5 + diffuseTerm + specularTerm, 1);
    
//    if (vert.toLights == true) { return float4(ambientTerm + diffuseTerm + specularTerm, vert.color.a); }
//    else { return pixelcolor; }
    
}

fragment float4 fragment_light(OutVertex vert [[stage_in]]) {
    
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(vert.normal);

    float diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = light.diffuseColor * vert.color.rgb * diffuseIntensity;
//    float3 diffuseTerm = light.diffuseColor * material.diffuseColor * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    
    if (vert.toLights == true) { return float4(ambientTerm + diffuseTerm + specularTerm, vert.color.a); }
    else { return vert.color; }
}

fragment float4 fragment_light_no_specular(OutVertex vert [[stage_in]])
{
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(vert.normal);
    
    float diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = light.diffuseColor * vert.color.rgb * diffuseIntensity;
    //    float3 diffuseTerm = light.diffuseColor * material.diffuseColor * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    specularTerm[0] = 0.2;
    specularTerm[1] = 0.2;
    specularTerm[2] = 0.2;
    return float4(ambientTerm + diffuseTerm + specularTerm, 1);
}

fragment float4 fragmentLightingShader(OutVertex in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}


fragment float4 main_fragment(const OutVertex v [[stage_in]]) {
    
    float3 const ambient = light.ambientColor * material.ambientColor;
    
    float3 const normal = normalize(v.normal);
    float const intensityDiffuse = saturate(dot(normal, light.direction));  // `saturate` clamps the value between 0 and 1.
    float3 const diffuse = intensityDiffuse * (light.diffuseColor * material.diffuseColor);
    

    
    float3 specular(0);
    if (intensityDiffuse > 0) {
        float3 const eyeDirection = normalize(v.eye);
        float3 const halfway = normalize(light.direction + eyeDirection);
        float const specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specular = light.specularColor * material.specularColor * specularFactor;
    }
    
    return float4(ambient + diffuse + specular, 1);
}

fragment half4 fragment_main_balls(OutVertex in [[stage_in]])
{
    float3 L(0, 0, 1);
    float3 N = normalize(in.normal);
    float NdotL = saturate(dot(N, L));
    
    float intensity = saturate(0.1 + NdotL);
    
    return half4(intensity * in.color);
}
