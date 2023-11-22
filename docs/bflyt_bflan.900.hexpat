/*
*	MIT License
*
*	Copyright (c) 2023 W. Michael Knudson
*
*	Permission is hereby granted, free of charge, to any person obtaining a copy
*	of this software and associated documentation files (the "Software"), to deal
*	in the Software without restriction, including without limitation the rights
*	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*	copies of the Software, and to permit persons to whom the Software is
*	furnished to do so, subject to the following conditions:
*
*	The above copyright notice and this permission notice shall be included in all
*	copies or substantial portions of the Software.
*
*	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*	SOFTWARE.
*/

#include <std/io.pat>
#include <std/mem.pat>
#include <std/core.pat>

u32 cBflytGroupNameLength    = 0x21;
u32 cBflytPaneNameLength     = 0x18;
u32 cBflytUserNameLength     = 0x8;
u32 cBflytMaterialNameLength = 0x1c;

struct Color4u8 {
    u8 r;
    u8 g;
    u8 b;
    u8 a;
};

struct Color4f {
    float r;
    float g;
    float b;
    float a;
};

fn TCharCode32(str string) {
    u32 magic = (string[0] << 0x0) + (string[1] << 0x8) + (string[2] << 0x10) + (string[3] << 0x18);
    return magic;
};

enum BflytSectionType : u32 {
    UserData     = TCharCode32("usd1"),
    Layout       = TCharCode32("lyt1"),
    TextureList  = TCharCode32("txl1"),
    FontList     = TCharCode32("fnl1"),
    MaterialList = TCharCode32("mat1"),
    CaptureTextureList = TCharCode32("ctl1"),
    VectorGraphicsList = TCharCode32("vgl1"),
    PaneStart    = TCharCode32("pas1"),
    PaneEnd      = TCharCode32("pae1"),
    Pane         = TCharCode32("pan1"),
    PicturePane  = TCharCode32("pic1"),
    TextBoxPane  = TCharCode32("txt1"),
    WindowPane   = TCharCode32("wnd1"),
    PartsPane     = TCharCode32("prt1"),
    AlignmentPane = TCharCode32("ali1"),
    CapturePane   = TCharCode32("cpt1"),
    BoundingPane  = TCharCode32("bnd1"),
    ScissorPane   = TCharCode32("scr1"),
    GroupStart    = TCharCode32("grs1"),
    GroupEnd      = TCharCode32("gre1"),
    Group         = TCharCode32("grp1"),
    ControlSource = TCharCode32("cnt1"),
};

/* User data section */
struct ResUi2dSystemData {
    u32 pane_system_data_type;
    
};

struct ResUi2dSystemDataArray {
    u16 reserve0;
    u16 count;
    u32 offset;
    
    ResUi2dSystemData o_system_data @ addressof(this) + offset;
};

enum Ui2dUserDataType : u8 {
    String     = 0,
    S32        = 1,
    Float      = 2,
    SystemData = 3,
};

struct ResUi2dUserData {
    u32 name_offset;
    u32 data_array_offset;
    u16 data_count;
    Ui2dUserDataType data_type;
    u8  reserve0;
    
    if (data_type == Ui2dUserDataType::Float) {
        float o_data_array[data_count] @ addressof(this) + data_array_offset;
    } else if (data_type == Ui2dUserDataType::S32) {
        s32 o_data_array[data_count] @ addressof(this) + data_array_offset;
    } else if (data_type == Ui2dUserDataType::String) {
        char o_data_array[data_count] @ addressof(this) + data_array_offset;
    } else if (data_type == Ui2dUserDataType::SystemData) {
        ResUi2dSystemDataArray o_data_array[data_count] @ addressof(this) + data_array_offset;
    }
    
    char o_name[] @ addressof(this) + name_offset;
};

struct ResUi2dUserDataSection {
    u16 user_data_count;
    u16 reserve0;
    ResUi2dUserData user_data_array[user_data_count];
    
    u32 c_real_size = 0x4 + 0xc * user_data_count;
};

/* Layout */
struct ResBflytLayout {
    u8    is_centered;
    u8    reserve0;
    u16   reserve1;
    float width;
    float height;
    float parts_width;
    float parts_height;
    char  name[];
    
    u32 c_real_size = 0x14 + sizeof(name);
};

/* Texture List */
u32 texture_name_offset_helper;

struct ResBflytTextureOffset {
    u32 texture_offset;
    
    char o_texture_name[] @ texture_name_offset_helper + texture_offset;
};
struct ResBflytTextureList {
    u16 texture_count;
    u16 reserve0;
    
    texture_name_offset_helper = addressof(this) + 0x4;
    
    ResBflytTextureOffset name_offset_array[texture_count];

    u32 c_real_size = 0x4 + 0x4 * texture_count;
};

/* Font List */
u32 font_name_offset_helper;

struct ResBflytFontOffset {
    u32 font_offset;
    
    char o_font_name[] @ font_name_offset_helper + font_offset;
};

struct ResBflytFontList {
    u16  font_count;
    u16  reserve0;
    
    font_name_offset_helper = addressof(this) + 0x4;
    
    ResBflytFontOffset  name_offset_array[font_count];

    u32 c_real_size = 0x4 + 0x4 * font_count;
};

/* Material Color data */
enum BflytMaterialColorType : u8 {
    U8    = 0,
    Float = 1
};
bitfield ResBflytMaterialColorDataColorTypes {
    BflytMaterialColorType color_0_type : 1;
    BflytMaterialColorType color_1_type : 1;
    BflytMaterialColorType color_2_type : 1;
    BflytMaterialColorType color_3_type : 1;
    BflytMaterialColorType color_4_type : 1;
    BflytMaterialColorType color_5_type : 1;
    BflytMaterialColorType color_6_type : 1;
    BflytMaterialColorType color_7_type : 1;
};

u32 c_material_color_data_base;
u32 c_color_type_index = 0;
u8  c_color_types_info;
u32 c_color_data_size;
struct ResBflytColorTypeOffset {
    u8 color_offset;

    if ((c_color_types_info >> c_color_type_index) == 0) {
        Color4u8 o_color @ c_material_color_data_base + color_offset;
        c_color_data_size += 4;
    } else if ((c_color_types_info >> c_color_type_index) == 1) {
        Color4f o_color @ c_material_color_data_base + color_offset ;
        c_color_data_size += 0x10;
    }
     
    c_color_data_size  += 1;
    c_color_type_index += 1;
} [[color(std::format("{}{}{}{}",o_color.r,o_color.g,o_color.b,o_color.a))]];

struct ResBflytMaterialColorData {
    u8 color_types;
    u8 color_count;
    
    c_material_color_data_base = addressof(this);
    c_color_type_index         = 0;
    c_color_types_info         = color_types;
    c_color_data_size          = 0x2;
    
    ResBflytColorTypeOffset color_offset_array[color_count];
};

/* Material texture map */


bitfield ResBflytMaterialTextureOptions {
    wrap_mode : 2;
    filter    : 2;
    reserve0  : 4;
};
struct ResBflytMaterialTextureMap {
    u16                            texture_index;
    ResBflytMaterialTextureOptions u_options;
    ResBflytMaterialTextureOptions v_options;
};

/* Material texture extensions */
bitfield ResBflytMaterialTextureExtension {
    is_capture_texture : 1;
    is_vector_texture  : 1;
    reserve0           : 30;
};

/* Material texture srt */
struct ResBflytMaterialTextureSrt {
    float translation_x;
    float translation_y;
    float rotation;
    float scale_x;
    float scale_z;
};

/* Material texture coord gen */
enum BflytShaderType : u8 {
    Reserve0     = 3,
    Reserve1     = 4,
    Reserve2     = 5,
    Reserve3     = 6,
    BrickRepeat  = 7
};
struct ResBflytMaterialTexCoordGen {
    u8  reserve0;
    BflytShaderType shader_type;
    u16 reserve1;
    u32 reserve2;
    u64 reserve3;
};

/* Material Tev combiner */
struct ResBflytMaterialTevCombiner {
    u8 data;
    u8 reserve0;
    u8 reserve1;
    u8 reserve2;
};

/* Material alpha compare */
enum BflytAlphaTestFunction : u8 {
    Never         = 0,
    LessThan      = 1,
    LessThanEqual = 2,
    Equal         = 3,
    NotEqual      = 4,
    GreaterEqual  = 5,
    Greater       = 6,
    Always        = 7,
};

struct ResBflytMaterialAlphaCompare {
    BflytAlphaTestFunction alpha_test_function;
    u8    reserve0;
    u16   reserve1;
    float alpha_compare_ref_value;
};

/* Material blend mode */
/* Default Add */
enum BflytBlendEquation : u8 {
    Invalid    = 0,
    Add        = 1,
    Sub        = 2,
    ReverseSub = 3,
    Min        = 4,
    Max        = 5,
};
/* Default Zero */
enum BflytBlendFunction : u8 {
    Zero                     = 0,
    One                      = 1,
    DestinationColor         = 2,
    DestinationColorMinusOne = 3,
    SourceAlpha              = 4,
    SourceAlphaMinusOne      = 5,
    DestinationAlpha         = 6,
    DestinationAlphaMinusOne = 7,
    SourceColor              = 8,
    SourceColorMinusOne      = 9
};
/* Default Clear */
enum BflytLogicOp : u8 {
    Invalid      = 0,
    NoOp         = 1,
    Clear        = 2,
    Set          = 3,
    Copy         = 4,
    CopyInverted = 5,
    Invert       = 6,
    And          = 7,
    Nand         = 8,
    Or           = 9,
    Nor          = 10,
    Xor          = 11,
    Equivalent   = 12,
    AndReverse   = 13,
    AndInverted  = 14,
    OrReverse    = 15,
    OrInverted   = 16,
};

struct ResBflytMaterialBlendMode {
    BflytBlendEquation blend_equation;
    BflytBlendFunction blend_function_source;
    BflytBlendFunction blend_function_destination;
    BflytLogicOp       logic_op;
};

struct ResBflytMaterialReserve2 {
    u32 reserve0;
    u32 reserve1;
    u32 reserve2;
};

struct ResBflytMaterialProjectionTexGen {
    u32 reserve0;
    u32 reserve1;
    u32 reserve2;
    u32 reserve3;
    u32 reserve4;
};

struct ResBflytMaterialReserve3 {
    u32 reserve0;
    u32 reserve1;
};

struct ResBflytMaterialDetailedCombiner {
    u32 data[4];
};

struct ResBflytMaterialUserCombiner {
    char name[0x60];
    u32  reserve[5];
};

struct ResBflytMaterialVectorTextureInfo {
    u32      flags;
    Color4u8 color;
    u64      reserve0;
};

struct ResBflytMaterialBrickRepeatShaderInfo {
    u32 reserve0[0x16];
};

/* Material */
bitfield ResBflytMatMemCount {
     tex_map_count                  : 2;
     tex_srt_count                  : 2;
     tex_coord_gen_count            : 2;
     tev_combiner_count             : 3;
     alpha_compare_count            : 1;
     color_blend_mode               : 1;
     reserve0                       : 1;
     color_and_alpha_blend_mode     : 1;
     reserve1                       : 1;
     reserve2                       : 1;
     projection_tex_gen_count       : 2;
     reserve3                       : 1;
     reserve4                       : 1;
     detailed_combiner_count        : 1;
     user_combiner_count            : 1;
     has_texture_extensions         : 1;
     vector_texture_info_count      : 2;
     brick_repeat_shader_info_count : 2;
     reserve5                       : 6;
};

struct ResBflytMaterialData {
    char                      material_name[cBflytMaterialNameLength];
    ResBflytMatMemCount       mat_mem;
    ResBflytMaterialColorData color_data;
    
    ResBflytMaterialTextureMap  tex_map_array[mat_mem.tex_map_count] @ addressof(this) + 0x20 + c_color_data_size;
    if (mat_mem.has_texture_extensions == true) {
        ResBflytMaterialTextureExtension tex_ext_array[mat_mem.tex_map_count] @ addressof(this) + 0x20 + c_color_data_size + 0x4 * mat_mem.tex_map_count;
    }
    ResBflytMaterialTextureSrt  tex_srt_array[mat_mem.tex_srt_count]             @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count;
    ResBflytMaterialTexCoordGen tex_coord_gen_array[mat_mem.tex_coord_gen_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count;
    ResBflytMaterialTevCombiner tev_combiner_array[mat_mem.tev_combiner_count]   @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count;
    
    ResBflytMaterialAlphaCompare alpha_compare_array[mat_mem.alpha_compare_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count;
    
    u32 c_blend_count = (mat_mem.color_and_alpha_blend_mode != 0) ? 2 : mat_mem.color_blend_mode;
    ResBflytMaterialBlendMode blend_mode_array[c_blend_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count;

    ResBflytMaterialReserve2         reserve2_array[mat_mem.reserve2] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count;
    ResBflytMaterialProjectionTexGen projection_tex_gen_array[mat_mem.projection_tex_gen_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2;
    ResBflytMaterialReserve3         reserve3_array[mat_mem.reserve3] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2 + 0x14 * mat_mem.projection_tex_gen_count;
    

    ResBflytMaterialDetailedCombiner detailed_combiner_array[mat_mem.detailed_combiner_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2 + 0x14 * mat_mem.projection_tex_gen_count + 0x8 * mat_mem.reserve3;
    ResBflytMaterialUserCombiner user_combiner_array[mat_mem.user_combiner_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2 + 0x14 * mat_mem.projection_tex_gen_count + 0x8 * mat_mem.reserve3 + 0x10 * mat_mem.detailed_combiner_count;
    ResBflytMaterialVectorTextureInfo vector_texture_info_array[mat_mem.vector_texture_info_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2 + 0x14 * mat_mem.projection_tex_gen_count + 0x8 * mat_mem.reserve3 + 0x10 * mat_mem.detailed_combiner_count + 0x74 * mat_mem.user_combiner_count;
    ResBflytMaterialBrickRepeatShaderInfo brick_repeat_gen_array[mat_mem.brick_repeat_shader_info_count] @ addressof(this) + 0x20 + c_color_data_size + ((mat_mem.has_texture_extensions * 0x4) + 0x4) * mat_mem.tex_map_count + 0x14 * mat_mem.tex_srt_count + 0x10 * mat_mem.tex_coord_gen_count + 0x4 * mat_mem.tev_combiner_count + 0x8 * mat_mem.alpha_compare_count + 0x4 * c_blend_count + 0xc * mat_mem.reserve2 + 0x14 * mat_mem.projection_tex_gen_count + 0x8 * mat_mem.reserve3 + 0x10 * mat_mem.detailed_combiner_count + 0x74 * mat_mem.user_combiner_count + 0x10 * mat_mem.vector_texture_info_count;
};

u32 material_list_base;
struct ResBflytMaterialDataOffset {
    u32 material_data_offset;
    
    ResBflytMaterialData o_material_data @ material_list_base + material_data_offset;
};

struct ResBflytMaterialList {
    u16 material_count;
    u16 reserve0;
    
    material_list_base = addressof(this) - 0x8;
    
    ResBflytMaterialDataOffset material_data_offsets[material_count];
    
    u32 c_real_size = 0x4 + 0x4 * material_count;
};

/* Capture texture list */
u32 s_capture_texture_list_base = 0;

struct ResBflytCapturePaneInfo {
    u32   pane_name_offset0;
    u32   pane_name_offset1;
    u32   reserve0[6];
    u8    values[8];
    float reserve1;
    float reserve2;
    
    char o_pane0_name[] @ s_capture_texture_list_base + pane_name_offset0;
    char o_pane1_name[] @ s_capture_texture_list_base + pane_name_offset1;
};
struct ResBflytCaptureTextureList {
    s_capture_texture_list_base = addressof(this) - 0x8;

    u32                     capture_info_count;
    ResBflytCapturePaneInfo capture_info_array[capture_info_count];
    
    u32 c_real_size = 0x4 + 0x30 * capture_info_count;
    
};

/* Vector graphics list */
u32 s_vector_graphics_list_base = 0;

struct ResBflytVectorGraphicsInfo {
    u32  reserve1;
    u32  reserve2;
    u32  reserve3;
    char bnvg_name[];
};

struct ResBflytVectorGraphicsInfoOffset {
    u32 offset;
    
    ResBflytVectorGraphicsInfo o_graphics_info @ s_vector_graphics_list_base + offset;
};

struct ResBflytVectorGraphicsList {
    s_vector_graphics_list_base = addressof(this) - 8;

    u32                              vector_graphics_count;
    ResBflytVectorGraphicsInfoOffset vector_graphics_info_array[vector_graphics_count];
    
    u32 c_real_size = 0x4 + 0x4 * vector_graphics_count;
};

/* Pane */
bitfield BflytPaneFlags {
    is_influence_alpha : 1;
    is_visible         : 1;
    reserve0           : 6;
};
bitfield BflytOriginBitField {
    origin_x        : 2;
    origin_y        : 2;
    parent_origin_x : 2;
    parent_origin_y : 2;
};
struct ResBflytPane {
    BflytPaneFlags      pane_flags;
    BflytOriginBitField origin;
    u8                  alpha;
    u8                  flag_ex;
    char                pane_name[cBflytPaneNameLength];
    char                user_name[cBflytUserNameLength];
    float               translation_x;
    float               translation_y;
    float               translation_z;
    float               rotation_x;
    float               rotation_y;
    float               rotation_z;
    float               scale_x;
    float               scale_y;
    float               size_x;
    float               size_y;

    u32 c_real_size = 0x4c;
};

/* Picture pane */
struct ResBflytTextureUv {
    float top_left_x;
    float top_left_y;
    float top_right_x;
    float top_right_y;
    float bottom_left_x;
    float bottom_left_y;
    float bottom_right_x;
    float bottom_right_y;
};

struct ResBflytPicturePane : ResBflytPane {
    Color4u8          top_left_vertex_color;
    Color4u8          top_right_vertex_color;
    Color4u8          bottom_left_vertex_color;
    Color4u8          bottom_right_vertex_color;
    u16               material_index;
    u8                texture_count;
    u8                is_shape;
    ResBflytTextureUv texture_uv_array[texture_count];

    c_real_size = c_real_size + 0x14 + 0x20 * texture_count;
};

/* Text box pane */
struct ResBflytPerCharacterTransform {
    float eval_time_offset;
    float eval_time_width;
    u8    loop_type;
    u8    origin_v;
    u8    has_anim_info;
    u8    reserve0;
};

bitfield BflytTextOriginBitField {
    text_origin_x : 2;
    text_origin_y : 2;
    reserve0      : 4;
};
bitfield BflytTextPaneFlags {
    use_shadow                  : 1;
    is_restrict_length          : 1;
    border_format               : 2;
    has_per_character_transform : 1;
    reserve1                    : 3;
};

struct ResBflytTextBoxPane : ResBflytPane {
    u16                     text_buffer_size;
    u16                     text_length;
    u16                     material_index;
    u16                     font_index;
    BflytTextOriginBitField text_origin;
    u8                      line_alignment;
    BflytTextPaneFlags      text_flags;
    u8                      reserve2;
    float          italic_tilt;
    u32            text_offset;
    Color4u8       font_top_color;
    Color4u8       font_bottom_color;
    float          font_size_x;
    float          font_size_y;
    float          character_space;
    float          line_space;
    u32            label_offset;
    float          shadow_translation_x;
    float          shadow_translation_y;
    float          shadow_size_x;
    float          shadow_size_y;
    Color4u8       shadow_top_color;
    Color4u8       shadow_bottom_color;
    float          shadow_italic_tilt;
    u32            line_transform_offset;
    u32            per_character_transform_offset;
    
    char16 o_text[text_length >> 1] @ addressof(this) + text_offset - 0x8;
    char16 o_label[]           @ addressof(this) + label_offset - 0x8;
    if (text_flags.has_per_character_transform == true) {
        ResBflytPerCharacterTransform per_character_transform_array[text_length] @ addressof(this) + per_character_transform_offset;
    }
    
    c_real_size = c_real_size + 0x54;
};

/* Window pane */
struct Vector2f {
    float x;
    float y;
};
struct ResBflytWindowContent {
    Color4u8 top_left_vertex_color;
    Color4u8 top_right_vertex_color;
    Color4u8 bottom_left_vertex_color;
    Color4u8 bottom_right_vertex_color;
    u16      material_index;
    u8       uv_coordinate_count;
    u8       reserve0;
    Vector2f picture_uv_array[uv_coordinate_count];
};

enum BflytTextureFlipMode : u8 {
    None      = 0,
    FlipU     = 1,
    FlipV     = 2,
    Rotate90  = 3,
    Rotate180 = 4,
    Rotate270 = 5,
};
struct ResBflytWindowFrame {
    u16                  material_index;
    BflytTextureFlipMode texture_flip_mode;
    u8                   reserve0;
};

u32 c_wnd_pane_base;
struct ResBflytWindowFrameOffset {
    u32 frame_offset;
    
    ResBflytWindowFrame o_window_frame @ c_wnd_pane_base + frame_offset;
};

struct ResBflytWindowPane : ResBflytPane {
    s16 inflation_left;
    s16 inflation_right;
    s16 inflation_top;
    s16 inflation_bottom;
    s16 frame_size_left;
    s16 frame_size_right;
    s16 frame_size_top;
    s16 frame_size_bottom;
    u8  frame_count;
    u8  flag;
    u16 reserve0;
    u32 content_offset;
    u32 frame_offset_array_offset;
    
    c_wnd_pane_base = addressof(this) - 0x8;
    
    ResBflytWindowContent     o_content @ c_wnd_pane_base + content_offset;
    ResBflytWindowFrameOffset o_frame_offset_array[frame_count] @ c_wnd_pane_base + frame_offset_array_offset;
    
    c_real_size = c_real_size + 0x1c;
};

/* Part pane */
struct ResBflytPartsPaneBasicInfo {
    char  user_name[cBflytUserNameLength];
    float translation_x;
    float translation_y;
    float translation_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float scale_x;
    float scale_y;
    float size_x;
    float size_y;
    u8    pane_alpha;
    u8    reserve0;
    u8    reserve1;
};

struct ResBflytPartsProperty {
    char property_name[cBflytPaneNameLength];
    u8   usage_flag;
    u8   basic_usage_flag;
    u8   material_usage_flag;
    u8   user_data_type;
    u32  pane_offset;
    u32  user_data_offset;
    u32  pane_basic_info_offset;
};

struct ResBflytPartsPane : ResBflytPane {
    u32                   property_count;
    float                 magnify_x;
    float                 magnify_y;
    ResBflytPartsProperty property_array[property_count];
    char                  o_layout_name[] @ addressof(this) + c_real_size + 0xc + 0x28 * property_count;
    
    c_real_size = c_real_size + 0xc + 0x28 * property_count;
};

/* Group */
struct ResBflytPaneName {
    char name[cBflytPaneNameLength];
};
struct ResBflytGroup {
    char group_name[cBflytGroupNameLength];
    u8   reserve0;
    u16  child_count;
    ResBflytPaneName child_name_array[child_count];
    
    u32 c_real_size = 0x24 + child_count * cBflytPaneNameLength;
};

/* Control source */
struct ResBflytControlSource {
    u32  reserve0_offset;
    u32  name_array_offset;
    u16  pane_count;
    u16  anim_count;
    u32  pane_name_offset_array;
    u32  anim_name_offset_array;

    char o_control_name[]  @ addressof(this) + 0x14;
    char o_reserve0_name[] @ addressof(this) - 0x8 + reserve0_offset;
    ResBflytPaneName o_pane_name[pane_count] @ addressof(this) - 0x8 + name_array_offset;
    ResBflytPaneName o_anim_name[anim_count] @ addressof(this) - 0x8 + name_array_offset + pane_count * cBflytPaneNameLength;
    
    u32 c_real_size = 0x14;
};

/* Ui2d Binary field layout animation (Bflan) */
enum BflanSectionType : u32 {
    PaneAnimInfo  = TCharCode32("pai1"),
    PaneAnimShare = TCharCode32("pah1"),
    PaneAnimTag   = TCharCode32("pat1"),
};

enum BflanAnimInfoType : u32 {
    PerCharacterTransformCurveAnim = TCharCode32("FLCC"),
    ExtendedUserDataAnim           = TCharCode32("FLEU"),

    PerCharacterTransformAnim      = TCharCode32("FLCT"),
    PaneSrtAnim                    = TCharCode32("FLPA"),
    VertexColorAnim                = TCharCode32("FLVC"),
    VisibilityAnim                 = TCharCode32("FLVI"),
    DropShadowAnim                 = TCharCode32("FLDS"),
    MaskTextureAnim                = TCharCode32("FLMT"),
    ProceduralShapeAnim            = TCharCode32("FLPS"),
    WindowAnim                     = TCharCode32("FLWN"),
    StateMachineAnim               = TCharCode32("FSMA"),

    AlphaCompareAnim               = TCharCode32("FLAC"),
    FontShadowAnim                 = TCharCode32("FLFS"),
    IndirectSrtAnim                = TCharCode32("FLIM"),
    MaterialColorAnim              = TCharCode32("FLMC"),
    TextureSrtAnim                 = TCharCode32("FLTS"),
    TexturePatternAnim             = TCharCode32("FLTP"),
    BrickRepeatAnim                = TCharCode32("FTBR"),
    VectorGraphicsAnim             = TCharCode32("FVGA"),

};

enum BflanPerCharacterTransformCurveTarget : u8 {
    TranslateX      = 0,
    TranslateY      = 1,
    TranslateZ      = 2,
    RotateX         = 3,
    RotateY         = 4,
    RotateZ         = 5,
    LeftTopRed      = 6,
    LeftTopGreen    = 7,
    LeftTopBlue     = 8,
    LeftTopAlpha    = 9,
    LeftBottomRed   = 10,
    LeftBottomGreen = 11,
    LeftBottomBlue  = 12,
    LeftBottomAlpha = 13,
};


enum BflanPerCharacterTransformTarget : u8 {
    EvalTypeOffset = 0,
};
enum BflanPaneSrtTarget : u8 {
    TranslateX = 0,
    TranslateY = 1,
    TranslateZ = 2,
    RotateX    = 3,
    RotateY    = 4,
    RotateZ    = 5,
    ScaleX     = 6,
    ScaleY     = 7,
    SizeX      = 8,
    SizeY      = 9,
};
enum BflanVertexColorTarget : u8 {
   LeftTopRed       = 0,
   LeftTopGreen     = 1,
   LeftTopBlue      = 2,
   LeftTopAlpha     = 3,
   RightTopRed      = 4,
   RightTopGreen    = 5,
   RightTopBlue     = 6,
   RightTopAlpha    = 7,
   LeftBottomRed    = 8,
   LeftBottomGreen  = 9,
   LeftBottomBlue   = 10,
   LeftBottomAlpha  = 11,
   RightBottomRed   = 12,
   RightBottomGreen = 13,
   RightBottomBlue  = 14,
   RightBottomAlpha = 15,
   PaneAlpha        = 16,
};
enum BflanVisibilityTarget : u8 {
    Visibility = 0,
};
enum BflanMaterialColorTarget : u8 {
    BufferRed      = 0,
    BufferGreen    = 1,
    BufferBlue     = 2,
    BufferAlpha    = 3,
    Constant0Red   = 4,
    Constant0Green = 5,
    Constant0Blue  = 6,
    Constant0Alpha = 7,
    Color0Red      = 8,
    Color0Green    = 9,
    Color0Blue     = 10,
    Color0Alpha    = 11,
    Color1Red      = 12,
    Color1Green    = 13,
    Color1Blue     = 14,
    Color1Alpha    = 15,
    Color2Red      = 16,
    Color2Green    = 17,
    Color2Blue     = 18,
    Color2Alpha    = 19,
    Color3Red      = 20,
    Color3Green    = 21,
    Color3Blue     = 22,
    Color3Alpha    = 23,
    Color4Red      = 24,
    Color4Green    = 25,
    Color4Blue     = 26,
    Color4Alpha    = 27,
};
enum BflanTextureSrtTarget : u8 {
    TranslateU = 0,
    TranslateV = 1,
    Rotate     = 2,
    ScaleU     = 3,
    ScaleV     = 4,
};
enum BflanTexturePatternTarget : u8 {
    Image = 0,
};
enum BflanAlphaCompareTarget : u8 {
    CompareReference = 0,
};
enum BflanFontShadowTarget : u8 {
    BlackRed   = 0,
    BlackGreen = 1,
    BlackBlue  = 2,
    WhiteRed   = 3,
    WhiteGreen = 4,
    WhiteBlue  = 5,
    WhiteAlpha = 6,
};

enum BflanCurveType : u8 {
    Constant = 0,
    Step     = 1,
    Hermite  = 2,
};

struct ResBflanHermiteKey {
    float key_index;
    float value;
    float slope;
};
struct ResBflanStepKey {
    float key_index;
    u16   value;
    u16   reserve0;
};

u32 s_last_anim_info_magic = 0;
struct ResBflanAnimTarget {
    u8  reserve0;
    
    if (s_last_anim_info_magic == BflanAnimInfoType::PerCharacterTransformCurveAnim) {
        BflanPerCharacterTransformCurveTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::PerCharacterTransformAnim) {
        BflanPerCharacterTransformTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::PaneSrtAnim) {
        BflanPaneSrtTarget target_index;
    }  else if (s_last_anim_info_magic == BflanAnimInfoType::VertexColorAnim) {
        BflanVertexColorTarget target_index;
    }  else if (s_last_anim_info_magic == BflanAnimInfoType::VisibilityAnim) {
        BflanVisibilityTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::MaterialColorAnim) {
        BflanMaterialColorTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::TextureSrtAnim) {
        BflanTextureSrtTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::TexturePatternAnim) {
        BflanTexturePatternTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::AlphaCompareAnim) {
        BflanAlphaCompareTarget target_index;
    } else if (s_last_anim_info_magic == BflanAnimInfoType::FontShadowAnim) {
        BflanFontShadowTarget target_index;
    } else {
        u8  target_index;
    }
    
    BflanCurveType  curve_type;
    u8  reserve1;
    u16 frame_count;
    u16 reserve2;
    u32 key_array_offset;
    
    if (curve_type == BflanCurveType::Constant) {
        float o_constant_key_array[frame_count] @ addressof(this) + key_array_offset;
    } else if (curve_type == BflanCurveType::Step) {
        ResBflanStepKey o_step_key_array[frame_count] @ addressof(this) + key_array_offset;
    } else if (curve_type == BflanCurveType::Hermite) {
        ResBflanHermiteKey o_hermite_key_array[frame_count] @ addressof(this) + key_array_offset;
    }
};

u32 s_anim_info_base = 0;
struct ResBflanAnimTargetOffset {
    u32 offset;
    
    ResBflanAnimTarget o_anim_target @ s_anim_info_base + offset [[inline]];
};

struct ResBflanAnimInfo {
    BflanAnimInfoType magic;
    u8  anim_target_count;
    u8  reserve0;
    u16 reserve1;
    
    s_anim_info_base = addressof(this);
    s_last_anim_info_magic = u32(magic);
    
    ResBflanAnimTargetOffset anim_target_offset_array[anim_target_count];
};

u32 s_anim_content_base = 0;
struct ResBflanAnimInfoOffset {
    u32 offset;
    
    ResBflanAnimInfo o_anim_info @ s_anim_content_base + offset [[inline]];
};

enum BflanAnimType : u8 {
    Pane         = 0,
    Material     = 1,
    User         = 2,
    PaneExt      = 3,
    StateMachine = 4,
};

struct ResBflanAnimContent {
    char          anim_name[0x1c];
    u8            anim_info_count;
    BflanAnimType anim_type;
    u16           reserve0;

    s_anim_content_base = addressof(this);
    
    ResBflanAnimInfoOffset anim_info_offset_array[anim_info_count];
};

u32 s_pane_anim_info_base = 0;
struct ResBflanAnimContentOffset {
    u32 offset;
    
    ResBflanAnimContent o_anim_content @ s_pane_anim_info_base + offset [[inline]];
};

struct ResBflanPaneAnimInfo {
    u16 frame_count;
    u8  is_looping;
    u8  reserve0;
    u16 texture_count;
    u16 anim_content_count;
    u32 anim_content_offset_array_offset;
    u32 texture_name_offset_array[texture_count];
    
    s_pane_anim_info_base = addressof(this) - 0x8;
    
    ResBflanAnimContentOffset o_anim_content_array[anim_content_count] @ s_pane_anim_info_base + anim_content_offset_array_offset;
    
    u32 c_real_size = 0xc + 0x4 * texture_count;
};

struct ResBflanPaneAnimShare {
    u32 share_info_offset;
    u16 share_info_count;
    u16 reserve0;
    
    u32 c_real_size = 0x8;
};

struct ResBflanGroup {
    char group_name[0x21];
    u8   flag;
    u16  reserve0;
};

using ResUi2dSection;
struct ResBflanPaneAnimTag {
    u16 tag_order;
    u16 group_count;
    u32 name_offset;
    u32 group_array_offset;
    u32 user_data_section_offset;
    u16 start_frame;
    u16 end_frame;
    u8  is_descending_bind;
    u8  reserve0;
    u16 reserve1;
    
    char o_name[0x8] @ addressof(this) - 0x8 + name_offset;
    
    if (group_count != 0) {
        ResBflanGroup o_group_array[group_count] @ addressof(this) - 0x8 + group_array_offset;
    }
    if (user_data_section_offset != 0) {
        ResUi2dSection o_user_data @ addressof(this) - 0x8 + user_data_section_offset;
    }
    
    u32 c_real_size = 0x18;
};

/* Ui2d headers */
struct ResUi2dSection {
    BflytSectionType magic;
    u32              section_size;
    
    if (magic == BflytSectionType::UserData) {
        ResUi2dUserDataSection user_data;
        $ -= user_data.c_real_size;
    } else if (magic == BflytSectionType::Layout) {
        ResBflytLayout layout;
        $ -= layout.c_real_size;
    } else if (magic == BflytSectionType::TextureList) {
        ResBflytTextureList texture_list;
        $ -= texture_list.c_real_size;
    } else if (magic == BflytSectionType::FontList) {
        ResBflytFontList font_list;
        $ -= font_list.c_real_size;
    } else if (magic == BflytSectionType::MaterialList) {
        ResBflytMaterialList material_list;
        $ -= material_list.c_real_size;
    } else if (magic == BflytSectionType::CaptureTextureList) {
        ResBflytCaptureTextureList capture_texture_list;
        $ -= capture_texture_list.c_real_size;
    } else if (magic == BflytSectionType::VectorGraphicsList) {
        ResBflytVectorGraphicsList vector_graphics_list;
        $ -= vector_graphics_list.c_real_size;
    } else if (magic == BflytSectionType::Pane) {
        ResBflytPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::PicturePane) {
        ResBflytPicturePane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::TextBoxPane) {
        ResBflytTextBoxPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::WindowPane) {
        ResBflytWindowPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::PartsPane) {
        ResBflytPartsPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::AlignmentPane) {
        ResBflytPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::CapturePane) {
        ResBflytPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::BoundingPane) {
        ResBflytPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::ScissorPane) {
        ResBflytPane pane;
        $ -= pane.c_real_size;
    } else if (magic == BflytSectionType::Group) {
        ResBflytGroup group;
        $ -= group.c_real_size;
    } else if (magic == BflytSectionType::ControlSource) {
        ResBflytControlSource control_source;
        $ -= control_source.c_real_size;
    } else if (magic == BflanSectionType::PaneAnimShare) {
        ResBflanPaneAnimShare pane_anim_share;
        $ -= pane_anim_share.c_real_size;
    } else if (magic == BflanSectionType::PaneAnimTag) {
        ResBflanPaneAnimTag pane_anim_tag;
        $ -= pane_anim_tag.c_real_size;
    } else if (magic == BflanSectionType::PaneAnimInfo) {
        ResBflanPaneAnimInfo pane_anim_info;
        $ -= pane_anim_info.c_real_size;
    }
    
    $ += section_size - 0x8;
};

struct ResUi2dHeader {
    u32 magic;
    u16 endianess;
    u16 header_size;
    u16 micro_version;
    u8  minor_version;
    u8  major_version;
    u32 file_size;
    u32 section_count;
};

ResUi2dHeader head @ 0x0;

u32 offset = head.header_size;

ResUi2dSection section_array[head.section_count] @ offset;