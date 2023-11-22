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
#pragma pattern_limit 5000000
#pragma eval_depth 256

#include <std/io.pat>

/* NintendoWare common */
using ResNintendoWareRelocationTableEntry;

u64 s_pointer_base    = 0;
u64 s_gpu_region_base = 0;

fn TCharCode64(ref str string) {
    u64 c1 = string[0];
    u64 c2 = string[1];
    u64 c3 = string[2];
    u64 c4 = string[3];
    u64 c5 = 0;
    u64 c6 = 0;
    u64 c7 = 0;
    u64 c8 = 0;
    return (c1) | (c2 << 8) | (c3 << 16) | (c4 << 24) | (c5 << 32) | (c6 << 40) | (c7 << 48) | (c8 << 56);
};

struct ResNintendoWareRelocationTableEntry {
    u32 region_offset;
    u16 array_count;
    u8  relocation_count;
    u8  array_stride;
};

u32 g_relocation_table_entry_array_offset = 0;
struct ResNintendoWareRelocationTableSection {
    u64 base_pointer;
    u32 region_offset;
    u32 region_size;
    u32 base_entry_index;
    u32 entry_count;
    
    ResNintendoWareRelocationTableEntry o_entry_array[entry_count] @ g_relocation_table_entry_array_offset + base_entry_index * 0x8;
};

struct ResNintendoWareRelocationTable {
    u32 magic;
    u32 offset_from_header;
    u32 section_count;
    u32 reserve0;

    g_relocation_table_entry_array_offset = addressof(this) + 0x10 + section_count * 0x18;

    ResNintendoWareRelocationTableSection section_array[section_count];
};

struct ResNintendoWareString {
    u16  string_length;
    char string[string_length];
};

bitfield ResNintendoWareDictionaryRefBit {
    ref_bit_rshift : 3;
    ref_bit_length : 29;
};

u64  s_last_dictionary_base = 0;
bool s_external_strings_guard = 0;
struct ResNintendoWareDictionaryNode {
    ResNintendoWareDictionaryRefBit ref_bit;
    s16 left_node;
    s16 right_node;
    if (s_external_strings_guard == false) {
        ResNintendoWareString *key : u64;   
    } else {
        u64 external_string_key;
    }
    
    if (-1 < left_node) {
        //ResNintendoWareDictionaryNode o_left_node @ s_last_dictionary_base + left_node * 0x10;
    }
    if (-1 < right_node) {
        //ResNintendoWareDictionaryNode o_right_node @ s_last_dictionary_base + right_node * 0x10;
    }
};

struct ResNintendoWareDictionary {
    s_last_dictionary_base = addressof(this) + 0x8;
    
    u32 magic;
    s32 node_count;
    ResNintendoWareDictionaryNode root_node;
    ResNintendoWareDictionaryNode node_array[node_count];
};

struct ResNintendoWareSubHeader {
    u32 magic;
    u32 next_block_offset;
    u32 block_size;
    u32 reserve0;
};

struct ResNintendoWareFileHeader {
    u64 magic;
    u8  micro_version;
    u8  minor_version;
    u16 major_version;
    u16 endianess;
    u8  packed_alignment;
    u8  address_size;
    u32 file_name_offset;
    u16 runtime_is_relocated;
    u16 first_block_offset;
    u32 relocation_table_offset;
    u32 file_size;
    
    char o_file_name[] @ addressof(this) + file_name_offset;
    ResNintendoWareRelocationTable o_relocation_table @ addressof(this) + relocation_table_offset;
};

/* NintendoWare Gfx */
u64 cMaxGfxMemoryPoolSize  = 0x120;
u64 cMaxGfxBufferSize      = 0x48;
u64 cMaxGfxTextureSize     = 0xd8;
u64 cMaxGfxTextureViewSize = 0x48;
u64 cMaxGfxSamplerSize     = 0x78;

enum GfxMemoryPoolFlags : u32 {
    CpuNoAccess  = (1 << 0),
    CpuUncached  = (1 << 1),
    CpuCached    = (1 << 2),
    GpuNoAccess  = (1 << 3),
    GpuUncached  = (1 << 4),
    GpuCached    = (1 << 5),
    ShaderCode   = (1 << 6),
    Compressible = (1 << 7),
    Physical     = (1 << 8),
    Virtual      = (1 << 9),
};
enum GfxGpuAccessFlags : u32 {
    VertexBuffer        = (1 << 2),
    IndexBuffer         = (1 << 3),
    UniformBuffer       = (1 << 4),
    Texture             = (1 << 5),
    TransferDestination = (1 << 6),
    RenderTargetColor   = (1 << 7),
    RenderTargetDepth   = (1 << 8),
    IndirectDraw        = (1 << 9),
    DisplayTexture      = (1 << 10),
    Counter             = (1 << 11),
};
struct ResGfxMemoryPoolInfo {
    GfxMemoryPoolFlags memory_pool_flags;
    u32                size;
    u64                gpu_region_base;
};

struct ResGfxBufferInfo {
    u32               size;
    GfxGpuAccessFlags gpu_access_flags;
    u32               reserve0;
    u32               reserve1;
};

enum GfxChannelFormat : u8 {
    None         = 0x1,
    R8           = 0x2,
    R4G4B4A4     = 0x3,
    R5G5B5A1     = 0x5,
    A1B5G5R5     = 0x6,
    R5G6B5       = 0x7,
    B5G6R5       = 0x8,
    R8G8         = 0x9,
    R16          = 0xa,
    R8G8B8A8     = 0xb,
    B8G8R8A8     = 0xc,
    R9G9B9E5F    = 0xd,
    R10G10B10A2  = 0xe,
    R11G11B10F   = 0xf,
    R16G16       = 0x12,
    D24S8        = 0x13,
    R32          = 0x14,
    R16G16B16A16 = 0x15,
    D32FS8       = 0x16,
    R32G32       = 0x17,
    R32G32B32    = 0x18,
    R32G32B32A32 = 0x19,
    BC1          = 0x1a,
    BC2          = 0x1b,
    BC3          = 0x1c,
    BC4          = 0x1d,
    BC5          = 0x1e,
    BC6H         = 0x1f,
    BC7U         = 0x20,
    ASTC_4x4     = 0x2d,
    ASTC_5x4     = 0x2e,
    ASTC_5x5     = 0x2f,
    ASTC_6x5     = 0x30,
    ASTC_6x6     = 0x31,
    ASTC_8x5     = 0x32,
    ASTC_8x6     = 0x33,
    ASTC_8x8     = 0x34,
    ASTC_10x5    = 0x35,
    ASTC_10x6    = 0x36,
    ASTC_10x8    = 0x37,
    ASTC_10x10   = 0x38,
    ASTC_12x10   = 0x39,
    ASTC_12x12   = 0x3a,
    B5G5R5A1     = 0x3b,
};
enum GfxTypeFormat : u8 {
    Unorm   = 0x1,
    Snorm   = 0x2,
    UInt    = 0x3,
    SInt    = 0x4,
    Float   = 0x5,
    SRGB    = 0x6,
    Depth   = 0x7, /* (Unorm) */
    UScaled = 0x8,
    SScaled = 0x9,
    UFloat  = 0xa,
};

fn GFX_MAKE_IMAGE_FORMAT(u8 channel_format, u8 type_format) {
    return ((channel_format & 0xff) << 8) | (type_format & 0xff);
};

enum GfxImageFormat : u32 {
    R8_Unorm              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::Unorm),
    R8_Snorm              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::Snorm),
    R8_UInt               = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::UInt),
    R8_SInt               = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::SInt),
    R4G4B4A4_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R4G4B4A4,     GfxTypeFormat::Unorm),
    R5G5B5A1_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R5G5B5A1,     GfxTypeFormat::Unorm),
    A1B5G5R5_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::A1B5G5R5,     GfxTypeFormat::Unorm),
    R5G6B5_Unorm          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R5G6B5,       GfxTypeFormat::Unorm),
    B5G6R5_Unorm          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::B5G6R5,       GfxTypeFormat::Unorm),
    R8G8_Unorm            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::Unorm),
    R8G8_Snorm            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::Snorm),
    R8G8_UInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::UInt),
    R8G8_SInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::SInt),
    R16_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Unorm),
    R16_Snorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Snorm),
    R16_UInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::UInt),
    R16_SInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::SInt),
    R16_Float             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Float),
    Z16_Depth             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Depth),
    R8G8B8A8_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::Unorm),
    R8G8B8A8_Snorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::Snorm),
    R8G8B8A8_UInt         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::UInt),
    R8G8B8A8_SInt         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::SInt),
    R8G8B8A8_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::SRGB),
    B8G8R8A8_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::B8G8R8A8,     GfxTypeFormat::Unorm),
    B8G8R8A8_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::B8G8R8A8,     GfxTypeFormat::SRGB),
    R9G9B9E5F_SharedFloat = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R9G9B9E5F,    GfxTypeFormat::Float),
    R10G10B10A2_Unorm     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::Unorm),
    R10G10B10A2_UInt      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::UInt),
    R11G11B10F_Float      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R11G11B10F,   GfxTypeFormat::Float),
    R16G16_Unorm          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,       GfxTypeFormat::Unorm),
    R16G16_Snorm          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,       GfxTypeFormat::Snorm),
    R16G16_UInt           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,       GfxTypeFormat::UInt),
    R16G16_SInt           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,       GfxTypeFormat::SInt),
    R16G16_Float          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,       GfxTypeFormat::Float),
    D24S8_Depth           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::D24S8,        GfxTypeFormat::Depth),
    R32_UInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,          GfxTypeFormat::UInt),
    R32_SInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,          GfxTypeFormat::SInt),
    R32_Float             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,          GfxTypeFormat::Float),
    D32F_Depth            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,          GfxTypeFormat::Depth),
    R16G16B16A16_Unorm    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16, GfxTypeFormat::Unorm),
    R16G16B16A16_Snorm    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16, GfxTypeFormat::Snorm),
    R16G16B16A16_UInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16, GfxTypeFormat::UInt),
    R16G16B16A16_SInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16, GfxTypeFormat::SInt),
    R16G16B16A16_Float    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16, GfxTypeFormat::Float),
    D32FS8_Depth          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::D32FS8,       GfxTypeFormat::Depth),
    R32G32_UInt           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,       GfxTypeFormat::UInt),
    R32G32_SInt           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,       GfxTypeFormat::SInt),
    R32G32_Float          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,       GfxTypeFormat::Float),
    R32G32B32_UInt        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,    GfxTypeFormat::UInt),
    R32G32B32_SInt        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,    GfxTypeFormat::SInt),
    R32G32B32_Float       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,    GfxTypeFormat::Float),
    R32G32B32A32_UInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32, GfxTypeFormat::UInt),
    R32G32B32A32_SInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32, GfxTypeFormat::SInt),
    R32G32B32A32_Float    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32, GfxTypeFormat::Float),
    BC1_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC1,          GfxTypeFormat::Unorm),
    BC1_SRGB              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC1,          GfxTypeFormat::SRGB),
    BC2_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC2,          GfxTypeFormat::Unorm),
    BC2_SRGB              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC2,          GfxTypeFormat::SRGB),
    BC3_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC3,          GfxTypeFormat::Unorm),
    BC3_SRGB              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC3,          GfxTypeFormat::SRGB),
    BC4_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC4,          GfxTypeFormat::Unorm),
    BC4_Snorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC4,          GfxTypeFormat::Snorm),
    BC5_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC5,          GfxTypeFormat::Unorm),
    BC5_Snorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC5,          GfxTypeFormat::Snorm),
    BC6H_SF16             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC6H,         GfxTypeFormat::Float),
    BC6H_UF16             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC6H,         GfxTypeFormat::UFloat),
    BC7U_Unorm            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC7U,         GfxTypeFormat::Unorm),
    BC7U_SRGB             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::BC7U,         GfxTypeFormat::SRGB),
    ASTC_4X4_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_4x4,     GfxTypeFormat::Unorm),
    ASTC_4X4_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_4x4,     GfxTypeFormat::SRGB),
    ASTC_5X4_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_5x4,     GfxTypeFormat::Unorm),
    ASTC_5X4_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_5x4,     GfxTypeFormat::SRGB),
    ASTC_5X5_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_5x5,     GfxTypeFormat::Unorm),
    ASTC_5X5_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_5x5,     GfxTypeFormat::SRGB),
    ASTC_6X5_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_6x5,     GfxTypeFormat::Unorm),
    ASTC_6X5_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_6x5,     GfxTypeFormat::SRGB),
    ASTC_6X6_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_6x6,     GfxTypeFormat::Unorm),
    ASTC_6X6_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_6x6,     GfxTypeFormat::SRGB),
    ASTC_8X5_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x5,     GfxTypeFormat::Unorm),
    ASTC_8X5_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x5,     GfxTypeFormat::SRGB),
    ASTC_8X6_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x6,     GfxTypeFormat::Unorm),
    ASTC_8X6_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x6,     GfxTypeFormat::SRGB),
    ASTC_8X8_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x8,     GfxTypeFormat::Unorm),
    ASTC_8X8_SRGB         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_8x8,     GfxTypeFormat::SRGB),
    ASTC_10X5_Unorm       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x5,    GfxTypeFormat::Unorm),
    ASTC_10X5_SRGB        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x5,    GfxTypeFormat::SRGB),
    ASTC_10X6_Unorm       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x6,    GfxTypeFormat::Unorm),
    ASTC_10X6_SRGB        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x6,    GfxTypeFormat::SRGB),
    ASTC_10X8_Unorm       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x8,    GfxTypeFormat::Unorm),
    ASTC_10X8_SRGB        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x8,    GfxTypeFormat::SRGB),
    ASTC_10X10_Unorm      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x10,   GfxTypeFormat::Unorm),
    ASTC_10X10_SRGB       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_10x10,   GfxTypeFormat::SRGB),
    ASTC_12X10_Unorm      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_12x10,   GfxTypeFormat::Unorm),
    ASTC_12X10_SRGB       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_12x10,   GfxTypeFormat::SRGB),
    ASTC_12X12_Unorm      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_12x12,   GfxTypeFormat::Unorm),
    ASTC_12X12_SRGB       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::ASTC_12x12,   GfxTypeFormat::SRGB),
    B5G5R5A1_Unorm        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::B5G5R5A1,     GfxTypeFormat::Unorm),
};
enum GfxAttributeFormat : u32 {
    None_Unorm           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::None,         GfxTypeFormat::Unorm),
    R8_Unorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::Unorm),
    R8_Snorm             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::Snorm),
    R8_UInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::UInt),
    R8_SInt              = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::SInt),
    R8_UScaled           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::UScaled),
    R8_SScaled           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8,           GfxTypeFormat::SScaled),
    R8G8_Unorm           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::Unorm),
    R8G8_Snorm           = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::Snorm),
    R8G8_UInt            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::UInt),
    R8G8_SInt            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::SInt),
    R8G8_UScaled         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::UScaled),
    R8G8_SScaled         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8,         GfxTypeFormat::SScaled),
    R16_Unorm            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Unorm),
    R16_Snorm            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Snorm),
    R16_UInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::UInt),
    R16_SInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::SInt),
    R16_Float            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::Float),
    R16_UScaled          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::UScaled),
    R16_SScaled          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16,          GfxTypeFormat::SScaled),
    R8G8B8A8_Unorm       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::Unorm),
    R8G8B8A8_Snorm       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::Snorm),
    R8G8B8A8_UInt        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::UInt),
    R8G8B8A8_SInt        = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::SInt),
    R8G8B8A8_UScaled     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::UScaled),
    R8G8B8A8_SScaled     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R8G8B8A8,     GfxTypeFormat::SScaled),
    R10G10B10A2_Unorm    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::Unorm),
    R10G10B10A2_Snorm    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::Snorm),
    R10G10B10A2_UInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::UInt),
    R10G10B10A2_SInt     = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R10G10B10A2,  GfxTypeFormat::SInt),
    R16G16_Unorm         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::Unorm),
    R16G16_Snorm         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::Snorm),
    R16G16_UInt          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::UInt),
    R16G16_SInt          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::SInt),
    R16G16_Float         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::Float),
    R16G16_UScaled       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::UScaled),
    R16G16_SScaled       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16,        GfxTypeFormat::SScaled),
    R32_UInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,           GfxTypeFormat::UInt),
    R32_SInt             = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,           GfxTypeFormat::SInt),
    R32_Float            = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32,           GfxTypeFormat::Float),
    R16G16B16A16_Unorm   = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::Unorm),
    R16G16B16A16_Snorm   = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::Snorm),
    R16G16B16A16_UInt    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::UInt),
    R16G16B16A16_SInt    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::SInt),
    R16G16B16A16_Float   = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::Float),
    R16G16B16A16_UScaled = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::UScaled),
    R16G16B16A16_SScaled = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R16G16B16A16,  GfxTypeFormat::SScaled),
    R32G32_UInt          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,        GfxTypeFormat::UInt),
    R32G32_SInt          = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,        GfxTypeFormat::SInt),
    R32G32_Float         = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32,        GfxTypeFormat::Float),
    R32G32B32_UInt       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,     GfxTypeFormat::UInt),
    R32G32B32_SInt       = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,     GfxTypeFormat::SInt),
    R32G32B32_Float      = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32,     GfxTypeFormat::Float),
    R32G32B32A32_UInt    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32,  GfxTypeFormat::UInt),
    R32G32B32A32_SInt    = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32,  GfxTypeFormat::SInt),
    R32G32B32A32_Float   = GFX_MAKE_IMAGE_FORMAT(GfxChannelFormat::R32G32B32A32,  GfxTypeFormat::Float),
};

enum GfxImageStorageDimension : u8 { 
    Type1D = 1,
    Type2D = 2,
    Type3D = 3,
};

bitfield ResGfxTextureInfoFlags {
    is_packaged         : 1;
    is_sparse_binding   : 1;
    is_sparse           : 1;
    is_res_texture      : 1;
    reserve0            : 4;
};
struct ResGfxTextureInfo {
    ResGfxTextureInfoFlags   texture_flags;
    GfxImageStorageDimension storage_dimension;
    u16 tile_mode;
    u16 swizzle;
    u16 mip_levels;
    u16 sample_count;
    u16 reserve1;
    GfxImageFormat    image_format;
    GfxGpuAccessFlags gpu_access_flags;
    u32 width;
    u32 height;
    u32 depth;
    u32 array_layers;
    u32 packaged_texture_layout;
};

enum GfxImageDimension : u8 {
    Type1D                  = 0,
    Type2D                  = 1,
    Type3D                  = 2,
    TypeCube                = 3,
    Type1DArray             = 4,
    Type2DArray             = 5,
    Type2DMultisample       = 6,
    Type2DMultisampleArray  = 7,
    TypeCubeArray           = 8,
    TypeRectangle           = 9,
};

enum GfxTextureSwizzle : u8 {
    Zero = 0,
    One  = 1,
    R    = 2,
    G    = 3,
    B    = 4,
    A    = 5,
};

enum GfxTextureDepthStencilMode : u8 {
    Depth   = 0,
    Stencil = 1,
};

struct ResGfxTextureViewInfo {
    GfxImageDimension          image_dimension;
    GfxTextureDepthStencilMode depth_stencil_mode;
    u16                        reserve0;
    GfxImageFormat             image_format;
    GfxTextureSwizzle          swizzle_x;
    GfxTextureSwizzle          swizzle_y;
    GfxTextureSwizzle          swizzle_z;
    GfxTextureSwizzle          swizzle_w;
    u32                        reserve1;
    u16                        base_mip_level;
    u16                        mip_levels;
    u32                        reserve2[3];
    u32                        base_array_layer;
    u32                        array_layers;
    u32                        reserve3[2];
    u64                        runtime_texture;
};

enum GfxWrapMode : u8 {
    Repeat            = 0,
    MirrorRepeat      = 1,
    ClampToEdge       = 2,
    ClampToBorder     = 3,
    MirrorClampToEdge = 4,
};

enum GfxCompareOperation : u8 {
    Never            = 0,
    LessThan         = 1,
    Equal            = 2,
    LessThanEqual    = 3,
    GreaterThan      = 4,
    NotEqual         = 5,
    GreaterThanEqual = 6,
    Always           = 7,
};

enum GfxBorderColor : u8 {
    White            = 0,
    TransparentBlack = 1,
    Black            = 2,
};

enum GfxMipMapFilter : u8 {
    None    = 0,
    Nearest = 1,
    Linear  = 2,
};

enum GfxMinFilter : u8 {
    Invalid = 0,
    Nearest = 1,
    Linear  = 2,
};

enum GfxMagFilter : u8 {
    Invalid = 0,
    Nearest = 1,
    Linear  = 2,
};

enum GfxReductionFilter : u8 {
    Average = 0,
    Min     = 1,
    Max     = 2,
};

bitfield ResGfxSamplerInfoPackedOptions {
    GfxMipMapFilter    mip_map_filter    : 2;
    GfxMagFilter       mag_filter        : 2;
    GfxMinFilter       min_filter        : 2;
                       enable_anisotropy : 1;
                       enable_compare_op : 1;
    GfxReductionFilter reduction_filter  : 2;
                       reserve0          : 6;
};
struct ResGfxSamplerInfo {
    GfxWrapMode                    wrap_mode_u;
    GfxWrapMode                    wrap_mode_v;
    GfxWrapMode                    wrap_mode_w;
    GfxCompareOperation            compare_op;
    GfxBorderColor                 border_color;
    u8                             max_anisotropy;
    ResGfxSamplerInfoPackedOptions packed_options;
    float                          lod_clamp_min;
    float                          lod_clamp_max;
    float                          lod_bias;
    u32                            reserve1;
    u32                            reserve2;
    u32                            reserve3;
};

using ResBntx;
struct ResGfxEmbedFile {
    u64   file_offset;
    u32   file_size;
    u32   reserve0;
    
    u64 c_magic @ file_offset + s_pointer_base;
    if (0x8 < file_size) {
    
        if (c_magic == TCharCode64("BNTX")) {
            ResBntx o_texture_archive @ file_offset + s_pointer_base;
        }
    }
};

enum GfxUserDataType : u8 {
    S32    = 0,
    Float  = 1,
    String = 2,
    Byte   = 3,
};

struct ResGfxUserData {
    ResNintendoWareString *user_data_name : u64;
    u64                    user_data;
    s32                    data_entries;
    u8                     data_type;
    u8                     reserve0[0x2b];
};
enum GfxPrimitiveTopology : u32 {
    Points                 = 0,
    Lines                  = 1,
    LineStrip              = 2,
    Triangles              = 3,
    TrianglesStrip         = 4,
    LinesAdjacency         = 5,
    LineStripAdjacency     = 6,
    TrianglesAdjacency     = 7,
    TriangleStripAdjacency = 8,
    Patches                = 9,
};

enum GfxIndexFormat : u32 {
    U8  = 0,
    U16 = 1,
    U32 = 2
};

enum GfxComparisonFunction : u8 {
    Never            = 0,
    Less             = 1,
    Equal            = 2,
    LessThanEqual    = 3,
    Greater          = 4,
    NotEqual         = 5,
    GreaterThanEqual = 6,
    Always           = 7
};

enum GfxStencilOperation : u8 {
    Keep          = 0,
    Zero          = 1,
    Replace       = 2,
    Increment     = 3,
    Decrement     = 4,
    Invert        = 5,
    IncrementWrap = 6,
    DecrementWrap = 7
};

enum GfxBlendFactor : u8 {
    Zero                     = 0,
    One                      = 1,
    SourceColor              = 2,
    SourceColorMinusOne      = 3,
    DestinationColor         = 4,
    DestinationColorMinusOne = 5,
    SourceAlpha              = 6,
    SourceAlphaMinusOne      = 7,
    DestinationAlpha         = 8,
    DestinationAlphaMinusOne = 9,
    ConstantColor            = 10,
    ConstantColorMinusOne    = 11,
    ConstantAlpha            = 12,
    ConstantAlphaMinusOne    = 13,
    SourceAlphaSaturate      = 14,
    SourceOneColor           = 15,
    SourceOneColorMinusOne   = 16,
    SourceOneAlpha           = 17,
    SourceOneAlphaMinusOne   = 18
};

enum GfxBlendEquation : u8 {
    Add        = 0,
    Sub        = 1,
    ReverseSub = 2,
    Min        = 3,
    Max        = 4
};

enum GfxLogicOperation : u8 {
    Clear        = 0,
    And          = 1,
    AndReverse   = 2,
    Copy         = 3,
    AndInverted  = 4,
    NoOp         = 5,
    Xor          = 6,
    Or           = 7,
    Nor          = 8,
    Equivalent   = 9,
    Invert       = 10,
    OrReverse    = 11,
    CopyInverted = 12,
    OrInverted   = 13,
    Nand         = 14,
    Set          = 15,
};

enum GfxCullMode : u8 {
    None  = 0,
    Front = 1,
    Back  = 2,
};

enum GfxFillMode : u8 {
    Point = 0,
    Line  = 1,
    Fill  = 2,
};

enum GfxFrontFace : u8 {
    CounterClockWise = 0,
    ClockWise        = 1,
};

enum GfxChannelSource : u8 {
    Zero  = 0x0,
    One   = 0x1,
    Red   = 0x2,
    Green = 0x3,
    Blue  = 0x4,
    Alpha = 0x5
};

u32 cVariableBlockWidthTable[20];
u32 cVariableBlockHeightTable[20];
u32 cPackagedTextureTexelSizeTable[34];

fn InitializeGfxImageSizeTables() {
cVariableBlockWidthTable[0] = 0x10;
cVariableBlockWidthTable[1] = 0x08;
cVariableBlockWidthTable[2] = 0x10;
cVariableBlockWidthTable[3] = 0x08;
cVariableBlockWidthTable[4] = 0x08;
cVariableBlockWidthTable[5] = 0x04;
cVariableBlockWidthTable[6] = 0x04;
cVariableBlockWidthTable[7] = 0x05;
cVariableBlockWidthTable[8] = 0x05;
cVariableBlockWidthTable[9] = 0x06;
cVariableBlockWidthTable[10] = 0x06;
cVariableBlockWidthTable[11] = 0x08;
cVariableBlockWidthTable[12] = 0x08;
cVariableBlockWidthTable[13] = 0x08;
cVariableBlockWidthTable[14] = 0x0a;
cVariableBlockWidthTable[15] = 0x0a;
cVariableBlockWidthTable[16] = 0x0a;
cVariableBlockWidthTable[17] = 0x0a;
cVariableBlockWidthTable[18] = 0x0c;
cVariableBlockWidthTable[19] = 0x0c;

cVariableBlockHeightTable[0] = 0x08; 
cVariableBlockHeightTable[1] = 0x08; 
cVariableBlockHeightTable[2] = 0x08; 
cVariableBlockHeightTable[3] = 0x08;
cVariableBlockHeightTable[4] = 0x04; 
cVariableBlockHeightTable[5] = 0x04; 
cVariableBlockHeightTable[6] = 0x04; 
cVariableBlockHeightTable[7] = 0x04;
cVariableBlockHeightTable[8] = 0x05; 
cVariableBlockHeightTable[9] = 0x05; 
cVariableBlockHeightTable[10] = 0x06; 
cVariableBlockHeightTable[11] = 0x05;
cVariableBlockHeightTable[12] = 0x06; 
cVariableBlockHeightTable[13] = 0x08; 
cVariableBlockHeightTable[14] = 0x05; 
cVariableBlockHeightTable[15] = 0x06;
cVariableBlockHeightTable[16] = 0x08; 
cVariableBlockHeightTable[17] = 0x0a; 
cVariableBlockHeightTable[18] = 0x0a; 
cVariableBlockHeightTable[19] = 0x0c;

cPackagedTextureTexelSizeTable[0] = 0x08; 
cPackagedTextureTexelSizeTable[1] = 0x10; 
cPackagedTextureTexelSizeTable[2] = 0x10; 
cPackagedTextureTexelSizeTable[3] = 0x08;
cPackagedTextureTexelSizeTable[4] = 0x10; 
cPackagedTextureTexelSizeTable[5] = 0x10; 
cPackagedTextureTexelSizeTable[6] = 0x10; 
cPackagedTextureTexelSizeTable[7] = 0x08;
cPackagedTextureTexelSizeTable[8] = 0x10; 
cPackagedTextureTexelSizeTable[9] = 0x08; 
cPackagedTextureTexelSizeTable[10] = 0x08; 
cPackagedTextureTexelSizeTable[11] = 0x08;
cPackagedTextureTexelSizeTable[12] = 0x10; 
cPackagedTextureTexelSizeTable[13] = 0x20; 
cPackagedTextureTexelSizeTable[14] = 0x20; 
cPackagedTextureTexelSizeTable[15] = 0x20;
cPackagedTextureTexelSizeTable[16] = 0x20; 
cPackagedTextureTexelSizeTable[17] = 0x08; 
cPackagedTextureTexelSizeTable[18] = 0x08; 
cPackagedTextureTexelSizeTable[19] = 0x10;
cPackagedTextureTexelSizeTable[20] = 0x10; 
cPackagedTextureTexelSizeTable[21] = 0x10; 
cPackagedTextureTexelSizeTable[22] = 0x10; 
cPackagedTextureTexelSizeTable[23] = 0x10;
cPackagedTextureTexelSizeTable[24] = 0x10; 
cPackagedTextureTexelSizeTable[25] = 0x10; 
cPackagedTextureTexelSizeTable[26] = 0x10; 
cPackagedTextureTexelSizeTable[27] = 0x10;
cPackagedTextureTexelSizeTable[28] = 0x10; 
cPackagedTextureTexelSizeTable[29] = 0x10; 
cPackagedTextureTexelSizeTable[30] = 0x10; 
cPackagedTextureTexelSizeTable[31] = 0x10;
cPackagedTextureTexelSizeTable[32] = 0x10; 
cPackagedTextureTexelSizeTable[33] = 0x02;
};
InitializeGfxImageSizeTables();

fn CalculateGfxImageSize(GfxChannelFormat channel_format, u32 width, u32 height, u32 depth) {
    u32 format = channel_format;

    /* Adjust width and height for compressed formats */
    u32 package_format = format - 0x1a;
    if (package_format < 0x21) {
        u32 variable_format = format - 0x27;
        u32 block_width     = 4;
        u32 block_height    = 4;
        if (variable_format < 0x14) {
            block_width  = cVariableBlockWidthTable[variable_format];
            block_height = cVariableBlockHeightTable[variable_format];
        }

        width  = (block_width != 0)  ? (width  + block_width  - 1) / block_width  : 0;
        height = (block_height != 0) ? (height + block_height - 1) / block_height : 0;
    }

    /* Find texel size */
    u32 texel_size = 0;
    if (package_format < 0x22) {
        texel_size = cPackagedTextureTexelSizeTable[package_format];
    } else if (format < 0x3) {
        texel_size = 1;
    } else if (format < 0xb) {
        texel_size = 2;
    } else if (format < 0x15) {
        texel_size = 4;
    } else if (format < 0x18) {
        texel_size = 8;
    } else {
        texel_size = 12;
        if (format != 0x18) {
            texel_size = 16;
        }
    }

    /* Calculate */
    return texel_size * width * height * depth;
};

fn CalculateGfxAttributeSize(GfxChannelFormat channel_format, u32 count) {
        
    u32 format         = channel_format;
    u32 attribute_size = 0;
    if (format < 0x3) {
        attribute_size = 1;
    } else if (format < 0xb) {
        attribute_size = 2;
    } else if (format < 0x15) {
        attribute_size = 4;
    } else if (format < 0x18) {
        attribute_size = 8;
    } else {
        attribute_size = 12;
        if (format != 0x18) {
            attribute_size = 16;
        }
    }
    
    return attribute_size * count;
};

/* Bntx */
struct ResBntxTextureData : ResNintendoWareSubHeader {/*...*/};

using ResBntxTextureInfo;

struct ResBntxTextureInfoOffset {
    u64 texture_info;
    
    ResBntxTextureInfo o_texture_info @ texture_info + s_pointer_base;
};

struct ResBntxTextureContainer {
    u32 magic;
    u32 texture_count;
    u64 texture_info_array;
    u64 texture_data;
    u64 texture_dictionary;
    u64 runtime_memory_pool;
    u64 runtime_user_memory_pool;
    s32 base_memory_pool_offset;
    u32 reserve0;
    
    if (texture_info_array != 0) {
        ResBntxTextureInfoOffset o_texture_info_array[texture_count] @ texture_info_array + s_pointer_base;
    }
    if (texture_data != 0) {
        ResBntxTextureData o_texture_data @ texture_data + s_pointer_base;
    }
    if (texture_dictionary != 0) {
        ResNintendoWareDictionary o_texture_dictionary @ texture_dictionary + s_pointer_base;
    }
    if (runtime_memory_pool != 0) {
        char o_runtime_memory_pool[cMaxGfxMemoryPoolSize] @ runtime_memory_pool + s_pointer_base;
    }
};

u64 s_last_channel_format = 0;
u64 s_last_width  = 0;
u64 s_last_height = 0;
u64 s_last_depth  = 0;
struct ResBntxTextureMipLevel {
    u64 mip_level;
    
    char o_texture_mip[CalculateGfxImageSize(s_last_channel_format, s_last_width, s_last_height, s_last_depth)] @ mip_level + s_pointer_base;
    s_last_width  = s_last_width >> 1;
    s_last_height = s_last_height >> 1;
};

struct ResBntxTextureInfo : ResNintendoWareSubHeader {
    ResGfxTextureInfo texture_info;
    u8                texture_layout[4];
    u8                reserve0[0x14];
    u32               mip_map_total_size;
    u32               texture_data_alignment;
    GfxChannelSource  channel_sources[0x4];
    GfxImageDimension image_dimension;
    u8                reserve2[0x3];
    u64               name;
    u64               container;
    u64               mip_level_array;
    u64               user_data_array;
    u64               runtime_texture;
    u64               runtime_texture_view;
    u64               runtime_descriptor_slot;
    u64               user_data_dictionary;
    
    u32 c_image_format    = u32(texture_info.image_format);
    s_last_channel_format = (c_image_format >> 8) & 0xff;
    s_last_width  = texture_info.width;
    s_last_height = texture_info.height;
    s_last_depth  = texture_info.depth;
    
    if (name != 0) {
        ResNintendoWareString o_name @ name + s_pointer_base;
    }
    if (mip_level_array != 0) {
        ResBntxTextureMipLevel o_mip_level_array[texture_info.mip_levels] @ mip_level_array + s_pointer_base;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array @ user_data_array + s_pointer_base;
    }
    if (runtime_texture != 0) {
        char o_runtime_texture[0x100] @ runtime_texture + s_pointer_base;
    }
    if (runtime_texture_view != 0) {
        char o_runtime_texture_view[0x100] @ runtime_texture_view + s_pointer_base;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary + s_pointer_base;
    }
};

fn GetBntxGpuRegionBase(u64 header_offset) {
    u64 data @ header_offset + 0x30;
    return data + 0x10;
};

struct ResBntx : ResNintendoWareFileHeader {
    
    u64 c_last_gpu_base = s_gpu_region_base;
    s_gpu_region_base   = GetBntxGpuRegionBase(addressof(this));
    
    u64 c_last_base = s_pointer_base;
    s_pointer_base  = addressof(this);

    ResBntxTextureContainer texture_container;
    
    s_pointer_base = c_last_base;
    s_gpu_region_base   = c_last_gpu_base;
};

/* Bfres forward declares */
using ResBfresExternalOptions;

ResBfresExternalOptions g_external_options @ 0xee;

u64 s_bfres_base = 0;

/* Bfres shape */
struct ResBfresVertexBufferStride {
    u32 stride;
    u32 divisor;
    u32 reserve0;
    u32 reserve1;
};

bitfield ResBfresBufferMask {
    buffer_mask_offset : 6;
    buffer_flag_offset : 2;
};
struct ResBfresVertexAttribute {
    ResNintendoWareString *attribute_name : u64;
    GfxAttributeFormat     attribute_format;
    u16                    buffer_offset;
    ResBfresBufferMask     buffer_mask;
    u8                     is_dynamic_vbo;
};

struct ResBfresVertex {
    u32 magic;
    u32 reserve0;
    u64 vertex_attribute_array;
    u64 vertex_attribute_dictionary;
    u64 runtime_memory_pool_pointer;
    u64 runtime_vertex_buffer_array;
    u64 user_vertex_buffer_array;
    u64 vertex_buffer_info_array;
    u64 vertex_buffer_stride_info_array;
    u64 user_pointer;
    u32 base_gpu_region_offset;
    u8  vertex_attribute_count;
    u8  vertex_buffer_count;
    u16 section_index;
    u32 vertex_count;
    u16 reserve1;
    u16 vertex_buffer_alignment;
    
    if (vertex_attribute_array != 0) {
        ResBfresVertexAttribute o_vertex_attribute_array[vertex_attribute_count] @ vertex_attribute_array;
    }
    if (vertex_attribute_dictionary != 0) {
        ResNintendoWareDictionary o_vertex_attribute_dictionary @ vertex_attribute_dictionary;
    }
    if (runtime_vertex_buffer_array != 0) {
        char o_runtime_vertex_buffer_array[cMaxGfxBufferSize * vertex_buffer_count] @ runtime_vertex_buffer_array;
    }
    if (user_vertex_buffer_array != 0) {
        u64 o_user_vertex_buffer_array[vertex_buffer_count] @ user_vertex_buffer_array;
    }
    if (vertex_buffer_info_array != 0) {
        ResGfxBufferInfo o_user_vertex_buffer_info_array[vertex_buffer_count] @ vertex_buffer_info_array;
    }
    if (vertex_buffer_stride_info_array != 0) {
        ResBfresVertexBufferStride o_user_vertex_buffer_stride_info_array[vertex_buffer_count] @ vertex_buffer_stride_info_array;
    }
};

struct ResBfresSubMeshRange {
    u32 base_gpu_region_offset;
    u32 index_count;
};

struct ResBfresMesh {
    u64                  sub_mesh_range_array;
    u64                  runtime_memory_pool_pointer;
    u64                  runtime_index_buffer;
    u64                  index_buffer_info;
    u32                  index_buffer_memory_offset;
    GfxPrimitiveTopology primitive_topology;
    GfxIndexFormat       index_format;
    u32                  index_count;
    u32                  base_index;
    u16                  sub_mesh_count;
    u16                  reserve0;
    
    if (sub_mesh_range_array != 0) {
        ResBfresSubMeshRange o_sub_mesh_range_array[sub_mesh_count] @ sub_mesh_range_array;
    }
    if (runtime_index_buffer != 0) {
        char o_runtime_index_buffer[cMaxGfxBufferSize] @ runtime_index_buffer;
    }
    if (index_buffer_info != 0) {
        ResGfxBufferInfo o_index_buffer_info @ index_buffer_info;
    }
};

struct ResBfresKeyShape {
    u8 key_shape_attribute_location_array[18];
    u8 reserve[2];
};

struct ResBfresBounding {
    float center_position_x;
    float center_position_y;
    float center_position_z;
    float extent_x;
    float extent_y;
    float extent_z;
};

struct ResBfresBoundingSphere {
    float center_position_x;
    float center_position_y;
    float center_position_z;
    float radius;
};

bitfield ResBfresShapeFlags {
    reserve0                    : 1;
    is_bounding_consistent      : 1;
    has_vertex_buffer           : 1;
    is_skip_setup_index_buffers : 1;
    reserve1                    : 28;
};
struct ResBfresShape {
    u32                    magic;
    ResBfresShapeFlags     flags;
    ResNintendoWareString *shape_name : u64;
    u64                    vertex;
    u64                    mesh_array;
    u64                    skin_bone_index_array;
    u64                    key_shape_array;
    u64                    key_shape_dictionary;
    u64                    bounding_box_array;
    u64                    bounding_sphere_array;
    u64                    runtime_user_pointer;
    u16                    section_index;
    u16                    material_index;
    u16                    bone_index;
    u16                    vertex_index;
    u16                    skin_bone_index_count;
    u8                     max_bone_influences_per_vertex;
    u8                     mesh_count;
    u8                     key_shape_count;
    u8                     target_attribute_count;
    u16                    reserve0;
    
    if (vertex != 0) {
        ResBfresVertex o_vertex @ vertex;
    }
    if (mesh_array != 0) {
        ResBfresMesh o_mesh_array[mesh_count] @ mesh_array;
    }
    if (skin_bone_index_array != 0) {
        u16 o_skin_bone_index_array[skin_bone_index_count] @ skin_bone_index_array;
    }
    if (key_shape_array != 0) {
        ResBfresKeyShape o_key_shape_array[key_shape_count] @ key_shape_array;
    }
    if (key_shape_dictionary != 0) {
        ResNintendoWareDictionary o_key_shape_dictionary @ key_shape_dictionary;
    }
    if (bounding_box_array != 0) {
        ResBfresBounding o_bounding_box_array[mesh_count] @ bounding_box_array;
    }
    if (bounding_sphere_array != 0) {
        ResBfresBoundingSphere o_bounding_sphere_array @ bounding_sphere_array;
    }
};

/* Bfres Material */
enum BfresRenderInfoDataType : u8 {
    S32    = 0x0,
    Float  = 0x1,
    String = 0x2,
};

u64 s_render_info_index_iter        = 0;
u64 s_last_render_info_value_array  = 0;
u64 s_last_render_info_count_array  = 0;
u64 s_last_render_info_offset_array = 0;

fn GetRenderInfoCount() {
    u16 count @ s_last_render_info_count_array + 0x2 * s_render_info_index_iter;
    return count;
};
fn GetRenderInfoOffset() {
    u16 offset @ s_last_render_info_offset_array + 0x2 * s_render_info_index_iter;
    return offset;
};

struct ResBfresRenderInfo {
    u64 render_info_name;
    BfresRenderInfoDataType  data_type;
    u8                       reserve0;
    u16                      reserve1;
    u32                      reserve2;
    
    u32 c_value_count  = GetRenderInfoCount();
    u32 c_value_offset = GetRenderInfoOffset();

    if (s_render_info_index_iter != 0 && s_last_render_info_count_array != 0 && s_last_render_info_offset_array != 0) {
        if (data_type == BfresRenderInfoDataType::S32) {
            s32 o_value_array[c_value_count] @ s_last_render_info_value_array + c_value_offset;
        } else if (data_type == BfresRenderInfoDataType::Float) {
            float o_value_array[c_value_count] @ s_last_render_info_value_array + c_value_offset;
        } else if (data_type == BfresRenderInfoDataType::String) {
            ResNintendoWareString *o_value_array[c_value_count] : u64 @ s_last_render_info_value_array + c_value_offset;
        }
    }
    
    if (g_external_options.requires_external_strings == false) {
        ResNintendoWareString o_render_info_name @ render_info_name;
    }
    
    s_render_info_index_iter = s_render_info_index_iter + 1;
};

enum BfresShaderParamDataType : u8 {
    Bool                      = 0x0,
    BoolVector2               = 0x1,
    BoolVector3               = 0x2,
    BoolVector4               = 0x3,
    S32                       = 0x4,
    S32Vector2                = 0x5,
    S32Vector3                = 0x6,
    S32Vector4                = 0x7,
    U32                       = 0x8,
    U32Vector2                = 0x9,
    U32Vector3                = 0xa,
    U32Vector4                = 0xb,
    Float                     = 0xc,
    FloatVector2              = 0xd,
    FloatVector3              = 0xe,
    FloatVector4              = 0xf,
    Matrix22f                 = 0x11,
    Matrix23f                 = 0x12,
    Matrix24f                 = 0x13,
    Matrix32f                 = 0x15,
    Matrix33f                 = 0x16,
    Matrix34f                 = 0x17,
    Matrix42f                 = 0x19,
    Matrix43f                 = 0x1a,
    Matrix44f                 = 0x1b,
    Srt2d                     = 0x1c,
    Srt3d                     = 0x1d,
    SrtTexture                = 0x1e,
    SrtTextureWithUserPointer = 0x1f,
};

struct ResBfresSrt2d {
    float scale_x;
    float scale_y;
    float rotation;
    float translation_x;
    float translation_y;
};

struct ResBfresSrt3d {
    float scale_x;
    float scale_y;
    float scale_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float translation_x;
    float translation_y;
    float translation_z;
};

enum BfresSrtMode : u32 {
    Maya      = 0x0,
    Max       = 0x1,
    SoftImage = 0x2,
};

struct ResBfresTextureSrt {
    BfresSrtMode srt_mode;
    float        scale_x;
    float        scale_y;
    float        rotation;
    float        translation_x;
    float        translation_y;
};

struct ResBfresTextureSrtWithUserPointer {
    BfresSrtMode srt_mode;
    float        scale_x;
    float        scale_y;
    float        rotation;
    float        translation_x;
    float        translation_y;
    u64          runtime_user_pointer;
};

struct Matrix22f {
    u32 m11;
    u32 m12;
    u32 m21;
    u32 m22;
};

struct Matrix23f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m21;
    u32 m22;
    u32 m23;
};

struct Matrix24f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m14;
    u32 m21;
    u32 m22;
    u32 m23;
    u32 m24;
};

struct Matrix32f {
    u32 m11;
    u32 m12;
    u32 m21;
    u32 m22;
    u32 m31;
    u32 m32;
};

struct Matrix33f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m21;
    u32 m22;
    u32 m23;
    u32 m31;
    u32 m32;
    u32 m33;
};

struct Matrix34f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m14;
    u32 m21;
    u32 m22;
    u32 m23;
    u32 m24;
    u32 m31;
    u32 m32;
    u32 m33;
    u32 m34;
};

struct Matrix42f {
    u32 m11;
    u32 m12;
    u32 m21;
    u32 m22;
    u32 m31;
    u32 m32;
    u32 m41;
    u32 m42;
};

struct Matrix43f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m21;
    u32 m22;
    u32 m23;
    u32 m31;
    u32 m32;
    u32 m33;
    u32 m41;
    u32 m42;
    u32 m43;
};

struct Matrix44f {
    u32 m11;
    u32 m12;
    u32 m13;
    u32 m14;
    u32 m21;
    u32 m22;
    u32 m23;
    u32 m24;
    u32 m31;
    u32 m32;
    u32 m33;
    u32 m34;
    u32 m41;
    u32 m42;
    u32 m43;
    u32 m44;
};

u64 s_last_shader_param_iter                = 0;
u64 s_last_shader_param_value_array         = 0;
u64 s_last_shader_param_ubo_offset_array    = 0;
u64 s_last_shader_param_convert_flags_array = 0;

struct ResBfresShaderParam {
    u64                        runtime_convert_texture_srt_callback;
    u64                        shader_param_name;
    u16                        shader_param_offset;
    BfresShaderParamDataType   data_type;
    u8                         reserve0;
    u32                        reserve1;

    if (s_last_shader_param_value_array != 0) {

        if (data_type == BfresShaderParamDataType::Bool) {
            bool o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::BoolVector2) {
            bool o_value[2] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::BoolVector3) {
            bool o_value[3] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::BoolVector4) {
            bool o_value[4] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::S32) {
            s32 o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::S32Vector2) {
            s32 o_value[2] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::S32Vector3) {
            s32 o_value[3] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::S32Vector4) {
            s32 o_value[4] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::U32) {
            u32 o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::U32Vector2) {
            u32 o_value[2] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::U32Vector3) {
            u32 o_value[3] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::U32Vector4) {
            u32 o_value[4] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Float) {
            float o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::FloatVector2) {
            float o_value[2] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::FloatVector3) {
            float o_value[3] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::FloatVector4) {
            float o_value[4] @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix22f) {
            Matrix22f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix23f) {
            Matrix23f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix24f) {
            Matrix24f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix32f) {
            Matrix32f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix33f) {
            Matrix33f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix34f) {
            Matrix34f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix42f) {
            Matrix42f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix43f) {
            Matrix43f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Matrix44f) {
            Matrix44f o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Srt2d) {
            ResBfresSrt2d o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::Srt3d) {
            ResBfresSrt3d o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::SrtTexture) {
            ResBfresTextureSrt o_value @ s_last_shader_param_value_array + shader_param_offset;
        } else if (data_type == BfresShaderParamDataType::SrtTextureWithUserPointer) {
            ResBfresTextureSrtWithUserPointer o_value @ s_last_shader_param_value_array + shader_param_offset;
        }
    
        if (s_last_shader_param_ubo_offset_array != 0) {
            u16 o_ubo_offset @ s_last_shader_param_ubo_offset_array + 0x2 * s_last_shader_param_iter;
        }
        
        if (s_last_shader_param_convert_flags_array != 0) {
            u32 o_shader_param_convert_flags_array @ s_last_shader_param_convert_flags_array + 0x4 * (s_last_shader_param_iter >> 5);
        }
    }
    
    if (g_external_options.requires_external_strings == false) {
        ResNintendoWareString o_shader_param_name @ shader_param_name;
    }
    
    s_last_shader_param_iter = s_last_shader_param_iter + 1;
};

u64 s_last_render_info_array  = 0;
u64 s_last_shader_param_array = 0;

struct ResBfresShaderReflection {
    ResNintendoWareString *shader_archive_name : u64;
    ResNintendoWareString *shader_name         : u64;
    u64 render_info_array;
    u64 render_info_dictionary;
    u64 shader_param_array;
    u64 shader_param_dictionary;
    u64 vertex_attribute_dictionary;
    u64 sampler_dictionary;
    u64 static_shader_option_dictionary;
    u16 render_info_count;
    u16 shader_param_count;
    u16 shader_param_data_size;
    u16 reserve0;
    u64 reserve1;
    
    s_last_render_info_array  = render_info_array;
    s_last_shader_param_array = shader_param_array;
    
    s_external_strings_guard = g_external_options.requires_external_strings;
    if (render_info_array != 0) {
        ResBfresRenderInfo o_render_info_array[render_info_count] @ render_info_array;
    }
    if (render_info_dictionary != 0) {
        ResNintendoWareDictionary o_render_info_dictionary @ render_info_dictionary;
    }
    if (shader_param_array != 0) {
        ResBfresShaderParam o_shader_param_array[shader_param_count] @ shader_param_array;
    }
    if (shader_param_dictionary != 0) {
        ResNintendoWareDictionary o_shader_param_dictionary @ shader_param_dictionary;
    }
    s_external_strings_guard = false;
    
    if (vertex_attribute_dictionary != 0) {
        ResNintendoWareDictionary o_vertex_attribute_dictionary @ vertex_attribute_dictionary;
    }
    if (sampler_dictionary != 0) {
        ResNintendoWareDictionary o_sampler_dictionary @ sampler_dictionary;
    }
    
    s_external_strings_guard = g_external_options.requires_external_strings;
    if (static_shader_option_dictionary != 0) {
        ResNintendoWareDictionary o_static_shader_option_dictionary @ static_shader_option_dictionary;
    }
    s_external_strings_guard = false;
};

struct ResBfresNamePointerArray {
    ResNintendoWareString *string : u64;
};

struct ResBfresMaterialShaderData {
    u64 shader_reflection;
    u64 vertex_attribute_name_array;
    u64 vertex_attribute_index_array;
    u64 sampler_name_array;
    u64 sampler_index_array;
    u64 static_shader_option_packed_bool_value_array;
    u64 static_shader_option_string_value_array;
    u64 static_option_indice_array;
    u32 reserve0;
    u8  vertex_attribute_count;
    u8  sampler_count;
    u16 bool_static_option_count;
    u16 total_static_option_count;
    u16 reserve1;
    u32 reserve2;
    
    if (shader_reflection != 0) {
        ResBfresShaderReflection o_shader_reflection @ shader_reflection;
    }
    if (vertex_attribute_name_array != 0) {
        ResBfresNamePointerArray o_vertex_attribute_name_array[vertex_attribute_count] @ vertex_attribute_name_array;
    }
    if (vertex_attribute_index_array != 0) {
        u8 o_vertex_attribute_index_array[vertex_attribute_count] @ vertex_attribute_index_array;
    }
    if (sampler_name_array != 0) {
        ResBfresNamePointerArray o_sampler_name_array[sampler_count] @ sampler_name_array;
    }
    if (vertex_attribute_name_array != 0) {
        u8 o_sampler_index_array[sampler_count] @ sampler_index_array;
    }
    if (static_shader_option_packed_bool_value_array != 0 && bool_static_option_count != 0) {
        u32 o_static_shader_option_packed_bool_value_array[(bool_static_option_count >> 5) + 1] @ static_shader_option_packed_bool_value_array;
    }
    if (static_shader_option_string_value_array != 0) {
        ResBfresNamePointerArray o_static_shader_option_string_value_array[total_static_option_count - bool_static_option_count] @ static_shader_option_string_value_array;
    }
    if (static_option_indice_array != 0) {
        /* one to one with static option resdic */
        u16 o_static_option_indice_array[total_static_option_count] @ static_option_indice_array;
    }
};


bitfield ResBfresMaterialFlags {
    is_visible : 1;
    reserve0   : 31;
};
struct ResBfresMaterial {
    u32                    magic;
    ResBfresMaterialFlags  flags;
    ResNintendoWareString *material_name : u64;
    u64 material_shader_data;
    u64 runtime_texture_view_array;
    u64 texture_name_array;
    u64 runtime_sampler_array;
    u64 sampler_info_array;
    u64 sampler_dictionary;
    u64 render_info_value_array;
    u64 render_info_value_count_array;
    u64 render_info_value_offset_array;
    u64 shader_param_value_array;
    u64 shader_param_ubo_offset_array;
    u64 reserve0;
    u64 user_data_array;
    u64 user_data_dictionary;
    u64 shader_param_convert_flags_array;
    u64 runtime_user_pointer;
    u64 runtime_sampler_descriptor_slot_array;
    u64 runtime_texture_descriptor_slot_array;
    u16 section_index;
    u8  sampler_count;
    u8  texture_count;
    u16 reserve1;
    u16 user_data_count;
    u16 reserve_size;
    u16 user_shading_model_option_ubo_size;
    u32 reserve2;

    s_render_info_index_iter        = 0;
    s_last_render_info_value_array  = 0;
    s_last_render_info_count_array  = 0;
    s_last_render_info_offset_array = 0;
    
    s_last_shader_param_iter                = 0;
    s_last_shader_param_value_array         = 0;
    s_last_shader_param_ubo_offset_array    = 0;
    s_last_shader_param_convert_flags_array = 0;

    if (material_shader_data != 0) {
        ResBfresMaterialShaderData o_material_shader_data @ material_shader_data;
    }
    if (runtime_texture_view_array != 0) {
        u64 o_runtime_texture_view_array[texture_count] @ runtime_texture_view_array;
    }
    if (texture_name_array != 0) {
        ResBfresNamePointerArray o_texture_name_array[texture_count] @ texture_name_array;
    }
    if (sampler_info_array != 0) {
        ResGfxSamplerInfo o_sampler_info_array[sampler_count] @ sampler_info_array;
    }
    if (sampler_dictionary != 0) {
        ResNintendoWareDictionary o_sampler_dictionary[sampler_count] @ sampler_dictionary;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary[user_data_count] @ user_data_dictionary;
    }
    if (runtime_sampler_descriptor_slot_array != 0) {
        u64 o_runtime_sampler_descriptor_slot_array[sampler_count] @ runtime_sampler_descriptor_slot_array;
    }
    if (runtime_texture_descriptor_slot_array != 0) {
        u64 o_runtime_texture_descriptor_slot_array[texture_count] @ runtime_texture_descriptor_slot_array;
    }

    /* Get shader params */
    u32 c_render_info_count  = s_render_info_index_iter;
    u32 c_shader_param_count = s_last_shader_param_iter;
    
    s_render_info_index_iter        = 0;
    s_last_render_info_value_array  = render_info_value_array;
    s_last_render_info_count_array  = render_info_value_count_array;
    s_last_render_info_offset_array = render_info_value_offset_array;
    
    s_last_shader_param_iter                = 0;
    s_last_shader_param_value_array         = shader_param_value_array;
    s_last_shader_param_ubo_offset_array    = shader_param_ubo_offset_array;
    s_last_shader_param_convert_flags_array = shader_param_convert_flags_array;
    
    if (s_last_render_info_array != 0) {
        ResBfresRenderInfo o_render_info_array_with_values[c_render_info_count] @ s_last_render_info_array;
    }
    if (s_last_shader_param_array != 0) {
        ResBfresShaderParam o_shader_param_array_with_values[c_shader_param_count] @ s_last_shader_param_array;
    }
     
    s_render_info_index_iter        = 0;
    s_last_render_info_value_array  = 0;
    s_last_render_info_count_array  = 0;
    s_last_render_info_offset_array = 0;
    
    s_last_shader_param_iter                = 0;
    s_last_shader_param_value_array         = 0;
    s_last_shader_param_ubo_offset_array    = 0;
    s_last_shader_param_convert_flags_array = 0;
};

/* Bfres Skeleton */
enum BfresBoneBillboardMode : u8 {
    None             = 0,
    Child            = 1,
    WorldViewVector  = 2,
    WorldViewPoint   = 3,
    ScreenViewVector = 4,
    ScreenViewPoint  = 5,
    YAxisViewVector  = 6,
    YAxisViewPoint   = 7,
};
enum BfresBoneLocalTransformMode : u8 {
    None                    = (1 << 0),
    SegmentScaleCompensate  = (1 << 1),
    ScaleUniform            = (1 << 2),
    ScaleVolumeOne          = (1 << 3),
    NoRotation              = (1 << 4),
    NoTranslation           = (1 << 5),
};
enum BfresBoneHierarchyTransformMode : u8 {
    None                    = (1 << 0),
    ScaleUniform            = (1 << 1),
    ScaleVolumeOne          = (1 << 2),
    NoRotation              = (1 << 3),
    NoTranslation           = (1 << 4),
};

bitfield ResBfresBonePacked {
    reserve0        : 8;
    reserve1        : 4;
    is_bone_visible : 1;
    reserve2        : 1; 
    BfresBoneBillboardMode billboard_mode : 3;
    reserve3        : 1;
    reserve4        : 3;
    BfresBoneLocalTransformMode local_transform_mode        : 5;
    BfresBoneHierarchyTransformMode hierarcy_transform_mode : 4;
};
struct ResBfresBone {
    ResNintendoWareString *bone_name : u64;
    u64 user_data_array;
    u64 user_data_dictionary;
    u64 reserve0;
    u16 bone_index;
    u16 bone_parent_index;
    u16 smooth_bone_index;
    u16 rigid_bone_index;
    u16 billboard_index;
    u16 user_data_count;
    ResBfresBonePacked bone_packed;
    float translation_x;
    float translation_y;
    float translation_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float rotation_w;
    float scale_x;
    float scale_y;
    float scale_z;
    
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

enum BfresSkeletonMirrorMode : u8 {
    X  = 0,
    XY = 1,
    XZ = 2,
};
enum BfresSkeletonScaleMode : u8 {
    None      = 0,
    Standard  = 1,
    Maya      = 2,
    SoftImage = 3,
};
enum BfresSkeletonRotationMode : u8 {
    Quarternion = 0,
    EulerXYZ    = 1,
};
bitfield ResBfresSkeletonFlags {
    has_user_pointer : 2;
    reserve0         : 4;
    BfresSkeletonMirrorMode mirror_mode      : 2;
    BfresSkeletonScaleMode  scale_mode       : 2;
    reserve1         : 2;
    BfresSkeletonRotationMode rotation_mode    : 2;
    reserve2         : 18;
};
struct ResBfresSkeleton {
    u32 magic;
    ResBfresSkeletonFlags skeleton_flags;
    u64 bone_dictionary;
    u64 bone_array;
    u64 bone_index_table;
    u64 inverse_trasform_matrix_array;
    u64 runtime_user_pointer;
    u64 reversed_bone_index_table;
    u16 bone_count;
    u16 smooth_bone_count;
    u16 rigid_bone_count;
    u16 reserve0;
    
    if (bone_dictionary != 0) {
        ResNintendoWareDictionary o_bone_dictionary @ bone_dictionary;
    }
    if (bone_array != 0) {
        ResBfresBone o_bone_array[bone_count] @ bone_array;
    }
    if (bone_index_table != 0) {
        u16 o_bone_index_table[bone_count] @ bone_index_table;
    }
    if (inverse_trasform_matrix_array != 0) {
        Matrix34f o_inverse_trasform_matrix_array[bone_count] @ inverse_trasform_matrix_array;
    }
    if (reversed_bone_index_table != 0) {
        u16 o_reversed_bone_index_table[bone_count] @ reversed_bone_index_table;
    }
};

/* Bfres model */
struct ResBfresModel {
    u32                    magic;
    u32                    reserve0;
    ResNintendoWareString *model_name : u64;
    ResNintendoWareString *reserve1   : u64;
    u64 skeleton;
    u64 vertex_array;
    u64 shape_array;
    u64 shape_dictionary;
    u64 material_array;
    u64 material_dictionary;
    u64 shader_reflection_array;
    u64 user_data_array;
    u64 user_data_dictionary;
    u64 runtime_user_pointer;
    u16 vertex_count;
    u16 shape_count;
    u16 material_count;
    u16 shader_reflection_count;
    u16 user_data_count;
    u16 reserve2;
    u32 reserve3;
    
    if (skeleton != 0) {
        ResBfresSkeleton o_skeleton @ skeleton;
    }
    if (vertex_array != 0) {
        ResBfresVertex o_vertex_array[vertex_count] @ vertex_array;
    }
    if (shape_array != 0) {
        ResBfresShape o_shape_array[shape_count] @ shape_array;
    }
    if (shape_dictionary != 0) {
        ResNintendoWareDictionary o_shape_dictionary @ shape_dictionary;
    }
    if (material_array != 0) {
        ResBfresMaterial o_material_array[material_count] @ material_array;
    }
    if (material_dictionary != 0) {
        ResNintendoWareDictionary o_material_dictionary @ material_dictionary;
    }
    if (shader_reflection_array != 0) {
        ResBfresShaderReflection o_shader_reflection_array[shader_reflection_count] @ shader_reflection_array;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

/* Bfres Anim Curve */
enum BfresAnimCurveFrameDataType : u8 {
    Float = 0,
    S16   = 1,
    U8    = 2,
};
enum BfresAnimCurveValueDataType : u8 {
    Float = 0,
    S32   = 0,
    S16   = 1,
    S8    = 2,
};
enum BfresAnimCurveCurveType : u8 {
    CubicFloat   = 0,
    LinearFloat  = 1,
    BakedFloat   = 2,
    StepInteger  = 3,
    BakedInteger = 4,
    StepBoolean  = 5,
    BakedBoolean = 6,
};
enum BfresAnimCurveWrapMode : u8 {
    Clamp          = 0,
    Repeat         = 1,
    Mirror         = 2,
    RelativeRepeat = 3,
};

struct ResBfresAnimCurveCubic<T> {
    T point0;
    T tangent0;
    T point1;
    T tangent1;
};
struct ResBfresAnimCurveLinear<T> {
    T point;
    T tangent;
};

bitfield ResBfresAnimCurvePacked {
    BfresAnimCurveFrameDataType frame_data_type : 2;
    BfresAnimCurveValueDataType value_data_type : 2;
    BfresAnimCurveCurveType curve_type      : 3;
    reserve0        : 1;
    BfresAnimCurveWrapMode pre_wrap_mode   : 2;
    reserve1        : 2;
    BfresAnimCurveWrapMode post_wrap_mode  : 2;
    reserve2        : 2;

};

struct ResBfresAnimCurve {
    u64 frame_array;
    u64 value_array;
    ResBfresAnimCurvePacked packed;
    u16   frame_count;
    u32   base_result_offset;
    float start_key;
    float end_key;
    float frame_data_scale;
    float frame_data_add;
    float frame_delta;
    u32   reserve3;
    
    if (packed.frame_data_type == BfresAnimCurveFrameDataType::Float) {
        float o_frame_array[frame_count] @ frame_array;
    } else if (packed.frame_data_type == BfresAnimCurveFrameDataType::S16) {
        s16   o_frame_array[frame_count] @ frame_array;
    } else if (packed.frame_data_type == BfresAnimCurveFrameDataType::U8) {
        u8    o_frame_array[frame_count] @ frame_array;
    }
    
    if (packed.value_data_type == BfresAnimCurveValueDataType::Float) {
    
        if (packed.curve_type == BfresAnimCurveCurveType::CubicFloat) {
            ResBfresAnimCurveCubic<float> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::LinearFloat) {
            ResBfresAnimCurveLinear<float> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedFloat) {
            ResBfresAnimCurveLinear<float> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::StepInteger) {
            s32 o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedInteger) {
            s32 o_value_array[frame_count] @ value_array;
        }
        
    } else if (packed.value_data_type == BfresAnimCurveValueDataType::S16) {
    
        if (packed.curve_type == BfresAnimCurveCurveType::CubicFloat) {
            ResBfresAnimCurveCubic<s16> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::LinearFloat) {
            ResBfresAnimCurveLinear<s16> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedFloat) {
            ResBfresAnimCurveLinear<s16> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::StepInteger) {
            s16 o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedInteger) {
            s16 o_value_array[frame_count] @ value_array;
        }
        
    } else if (packed.value_data_type == BfresAnimCurveValueDataType::S8) {
    
        if (packed.curve_type == BfresAnimCurveCurveType::CubicFloat) {
            ResBfresAnimCurveCubic<s8> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::LinearFloat) {
            ResBfresAnimCurveLinear<s8> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedFloat) {
            ResBfresAnimCurveLinear<s8> o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::StepInteger) {
            s8 o_value_array[frame_count] @ value_array;
        } else if (packed.curve_type == BfresAnimCurveCurveType::BakedInteger) {
            s8 o_value_array[frame_count] @ value_array;
        }
        
    }
    
    if (packed.curve_type == BfresAnimCurveCurveType::StepBoolean) {
        u32 o_value_bit_array[(frame_count >> 5) + 1] @ value_array;
    } else if (packed.curve_type == BfresAnimCurveCurveType::BakedBoolean) {
        u32 o_value_bit_array[(frame_count >> 5) + 1] @ value_array;
    }
};
u32 cBfresAnimCurveSize = 0x30;

/* Bfres Skeletal Anim */
enum BfresBoneAnimCurveType : u16 {
    ScaleX      = (1 << 0),
    ScaleY      = (1 << 1),
    ScaleZ      = (1 << 2),
    RotateX     = (1 << 3),
    RotateY     = (1 << 4),
    RotateZ     = (1 << 5),
    RotateW     = (1 << 6),
    TranslateX  = (1 << 7),
    TranslateY  = (1 << 8),
    TranslateZ  = (1 << 9),
};
struct ResBfresBoneAnimResultDefault {
    float translation_x;
    float translation_y;
    float translation_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float rotation_w;
    float scale_x;
    float scale_y;
    float scale_z;
};

bitfield ResBfresBoneAnimPacked {
    reserve0            : 3;
    is_use_scale        : 1;
    is_use_rotation     : 1;
    is_use_translation  : 1;
    BfresBoneAnimCurveType curve_type_mask : 10;
    reserve1            : 5;
    transform_mode      : 5;
    reserve2            : 6;
};
struct ResBfresBoneAnim {
    ResNintendoWareString *bone_name : u64;
    u64 anim_curve_array;
    u64 default_result;
    u64 user_data_array;
    u64 user_data_dictionary;
    ResBfresBoneAnimPacked packed;
    u8  reserve3;
    u8  reserve4;
    u8  anim_curve_count;
    u8  reserve5;
    u32 base_curve_index;
    u16 user_data_count;
    u16 reserve6;
    
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result != 0) {
        ResBfresBoneAnimResultDefault o_default_result @ default_result;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

bitfield ResBfresSkeletalAnimFlags {
    is_baked       : 1;
    reserve0       : 1;
    is_looping     : 1;
    reserve1       : 5;
    BfresSkeletonScaleMode scale_mode     : 2;
    reserve2       : 2;
    BfresSkeletonRotationMode rotation_mode  : 1;
    reserve3       : 19;
};
struct ResBfresSkeletalAnim {
    u32 magic;
    ResBfresSkeletalAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    ResNintendoWareString *reserve0  : u64;
    u64 runtime_bound_skeleton;
    u64 bind_table;
    u64 bone_anim_array;
    u64 user_data_array;
    u64 user_data_dictionary;
    u32 frame_count;
    u32 total_anim_curves;
    u32 baked_size;
    u16 bone_anim_count;
    u16 user_data_count;
    
    if (bind_table != 0) {
        u16 o_bind_table @ bind_table;
    }
    if (bone_anim_array != 0) {
        ResBfresBoneAnim o_bone_anim_array[bone_anim_count] @ bone_anim_array;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

/* Bfres Material Anim */
struct ResBfresShaderParamAnim {
    u64 shader_param_name;
    u16 base_curve;
    u16 float_curve_count;
    u16 int_curve_count;
    u16 base_constant;
    u16 constant_count;
    u16 material_sub_shader_param_index;
    u32 reserve0;
    
    if (g_external_options.requires_external_strings == false) {
        ResNintendoWareString o_shader_param_name @ shader_param_name;
    }
};

struct ResBfresTexturePatternAnim {
    ResNintendoWareString *sampler_name : u64;
    u16 base_curve;
    u16 base_constant;
    u8  material_sub_sampler_index;
    u8  reserve0;
    u16 reserve1;
};

struct ResBfresPerMaterialAnim {
    ResNintendoWareString *model_name : u64;
    u64 shader_param_anim_array;
    u64 texture_pattern_anim_array;
    u64 anim_curve_array;
    u64 constant_array;
    u16 base_shader_param_curve_index;
    u16 base_texture_pattern_curve_index;
    u16 base_visibility_curve_index;
    u16 visibility_curve_index;
    u16 visibility_constant_index;
    u16 shader_param_anim_count;
    u16 texture_pattern_anim_count;
    u16 constant_count;
    u16 anim_curve_count;
    u16 reserve0;
    u32 reserve1;
    
    if (shader_param_anim_array != 0) {
        ResBfresShaderParamAnim o_shader_param_anim_array[shader_param_anim_count] @ shader_param_anim_array;
    }
    if (texture_pattern_anim_array != 0) {
        ResBfresTexturePatternAnim o_texture_pattern_anim_array[texture_pattern_anim_count] @ texture_pattern_anim_array;
    }
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (constant_array != 0) {
        u32 o_constant_array[constant_count] @ constant_array;
    }
};

bitfield ResBfresMaterialAnimFlags {
    is_baked        : 1;
    reserve0        : 1;
    is_looping      : 1;
    reserve1        : 29;
};
struct ResBfresMaterialAnim {
    u32 magic;
    ResBfresMaterialAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    ResNintendoWareString *reserve0  : u64;
    u64 runtime_bound_model;
    u64 bind_table;
    u64 per_material_anim_array;
    u64 runtime_texture_view_array;
    u64 texture_name_array;
    u64 user_data_array;
    u64 user_data_dictionary;
    u64 runtime_texture_descriptor_slot_array;
    u32 frame_count;
    u32 baked_size;
    u16 user_data_count;
    u16 per_material_anim_count;
    u16 total_anim_curves;
    u16 shader_param_anim_count;
    u16 texture_pattern_anim_count;
    u16 material_visibility_anim_count;
    u16 texture_count;
    u16 reserve3;
    
    if (bind_table != 0) {
        u16 o_bind_table @ bind_table;
    }
    if (per_material_anim_array != 0) {
        ResBfresPerMaterialAnim o_per_material_anim_array[per_material_anim_count] @ per_material_anim_array;
    }
    if (runtime_texture_view_array != 0) {
        u64 o_runtime_texture_view_array[texture_count] @ runtime_texture_view_array;
    }
    if (texture_name_array != 0) {
        ResBfresNamePointerArray o_texture_name_array[texture_count] @ texture_name_array;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
    if (runtime_texture_descriptor_slot_array != 0) {
        u64 o_runtime_texture_descriptor_slot_array[texture_count] @ runtime_texture_descriptor_slot_array;
    }
};

/* Bfres Bone Visibility Anim */
bitfield ResBfresBoneVisibilityAnimFlags {
    is_baked        : 1;
    reserve0        : 1;
    is_looping      : 1;
    reserve1        : 29;
};
struct ResBfresBoneVisibilityAnim {
    u32 magic;
    ResBfresBoneVisibilityAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    ResNintendoWareString *reserve0  : u64;
    u64 runtime_bound_model;
    u64 bind_table;
    u64 anim_curve_array;
    u64 default_result_array;
    u64 bound_bone_name_array;
    u64 user_data_array;
    u64 user_data_dictionary;
    u32 frame_count;
    u32 baked_size;
    u16 bone_count;
    u16 anim_curve_count;
    u16 user_data_count;
    u16 reserve1;
    
    if (bind_table != 0) {
        u16 o_bind_table @ bind_table;
    }
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result_array != 0) {
        bool o_default_result_array[anim_curve_count] @ default_result_array;
    }
    if (bound_bone_name_array != 0) {
        ResBfresNamePointerArray o_bound_bone_name_array[bone_count] @ bound_bone_name_array;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

/* Bfres Shape Anim */
struct ResBfresKeyShapeAnim {
    ResNintendoWareString *key_shape_anim_name : u64;
    u8          anim_curve_index;
    u8          reserve0;
    u16         reserve1;
    u32         reserve2;
};

struct ResBfresVertexShapeAnim {
    ResNintendoWareString *vertex_shape_anim_name : u64;
    u64 anim_curve_array;
    u64 default_result_array;
    u64 key_shape_anim_array;
    u16 anim_curve_count;
    u16 key_shape_anim_count;
    u32 base_curve;
    u32 base_key_shape_anim;
    u32 reserve0;
    
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result_array != 0) {
        float o_default_result_array[anim_curve_count] @ default_result_array;
    }
    if (key_shape_anim_array != 0) {
        ResBfresKeyShapeAnim o_key_shape_anim_array[key_shape_anim_count] @ key_shape_anim_array;
    }
};

bitfield ResBfresShapeAnimFlags {
    is_baked        : 1;
    reserve0        : 1;
    is_looping      : 1;
    reserve1        : 29;
};
struct ResBfresShapeAnim {
    u32 magic;
    ResBfresShapeAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    ResNintendoWareString *reserve0  : u64;
    u64 runtime_bound_model;
    u64 bind_table;
    u64 vertex_shape_anim_array;
    u64 user_data_array;
    u64 user_data_dictionary;
    u32 frame_count;
    u32 baked_size;
    u16 user_data_count;
    u16 vertex_shape_anim_count;
    u16 total_key_shape_anim_count;
    u16 total_anim_curve_count;

    if (bind_table != 0) {
        u16 o_bind_table @ bind_table;
    }
    if (vertex_shape_anim_array != 0) {
        ResBfresVertexShapeAnim o_vertex_shape_anim_array[vertex_shape_anim_count] @ vertex_shape_anim_array;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

/* Bfres Scene Anim */
struct ResBfresCameraAnimResultDefault {
    float near;
    float far;
    float aspect;
    float fovy;
    float translation_x;
    float translation_y;
    float translation_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float twist;
};

enum BfresCameraAnimRotationMode   : u8 {
    At       = 0,
    EulerZXY = 1,
};

enum BfresCameraAnimProjectionMode : u8 {
    Orthographic = 0,
    Perspective  = 1,
};

bitfield ResBfresCameraAnimFlags {
    is_baked        : 1;
    reserve0        : 1;
    is_looping      : 1;
    reserve1        : 1;
    BfresCameraAnimRotationMode rotation_mode   : 1;
    reserve2        : 1;
    BfresCameraAnimProjectionMode projection_mode : 1;
    reserve3        : 25;
};
struct ResBfresCameraAnim {
    u32 magic;
    ResBfresCameraAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    u64 anim_curve_array;
    u64 default_result;
    u64 user_data_array;
    u64 user_data_dictionary;
    u32 frame_count;
    u32 baked_size;
    u16 user_data_count;
    u8  anim_curve_count;
    u8  reserve0;
    u32 reserve1;
    
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result != 0) {
        ResBfresCameraAnimResultDefault o_default_result @ default_result;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

struct ResBfresLightAnimResultDefault {
    s32   enable;
    float translation_x;
    float translation_y;
    float translation_z;
    float rotation_x;
    float rotation_y;
    float rotation_z;
    float distance_attenuation_x;
    float distance_attenuation_y;
    float angle_attenuation_x;
    float angle_attenuation_y;
    float color0_r;
    float color0_g;
    float color0_b;
    float color1_r;
    float color1_g;
    float color1_b;
};

bitfield ResBfresLightAnimFlags {
    is_baked                    : 1;
    reserve0                    : 1;
    is_looping                  : 1;
    reserve1                    : 5;
    is_use_curves               : 1;
    is_use_enable               : 1;
    is_use_position             : 1;
    is_use_rotation             : 1;
    is_use_distance_attenuation : 1;
    is_use_angle_attenuation    : 1;
    is_use_color0               : 1;
    is_use_color1               : 1;
    reserve2                    : 16;
};
struct ResBfresLightAnim {
    u32 magic;
    ResBfresLightAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    u64 anim_curve_array;
    u64 default_result;
    u64 user_data_array;
    u64 user_data_dictionary;
    ResNintendoWareString *light_type_name : u64;
    ResNintendoWareString *distance_attenuation_type_name : u64;
    ResNintendoWareString *angle_attenuation_type_name : u64;
    u32 frame_count;
    u32 baked_size;
    u16 user_data_count;
    u8  anim_curve_count;
    s8  light_type;
    s8  distance_attenuation_type;
    s8  angle_attenuation_type;
    u16 reserve0;
    
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result != 0) {
        ResBfresLightAnimResultDefault o_default_result @ default_result;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

struct ResBfresFogAnimResultDefault {
    float distance_attenuation_x;
    float distance_attenuation_y;
    float color_r;
    float color_g;
    float color_b;
};

bitfield ResBfresFogAnimFlags {
    is_baked        : 1;
    reserve0        : 1;
    is_looping      : 1;
    reserve1        : 29;
};
struct ResBfresFogAnim {
    u32 magic;
    ResBfresFogAnimFlags flags;
    ResNintendoWareString *anim_name : u64;
    u64 anim_curve_array;
    u64 default_result;
    u64 user_data_array;
    u64 user_data_dictionary;
    ResNintendoWareString *distance_attenuation_type_name : u64;
    u32 frame_count;
    u32 baked_size;
    u16 user_data_count;
    u8  anim_curve_count;
    s8  distance_attenuation_type;
    u32 reserve0;
    
    if (anim_curve_array != 0) {
        ResBfresAnimCurve o_anim_curve_array[anim_curve_count] @ anim_curve_array;
    }
    if (default_result != 0) {
        ResBfresFogAnimResultDefault o_default_result @ default_result;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

struct ResBfresSceneAnim {
    u32 magic;
    u32 reserve0;
    ResNintendoWareString *anim_name : u64;
    ResNintendoWareString *reserve1  : u64;
    u64 camera_anim_array;
    u64 camera_anim_dictionary;
    u64 light_anim_array;
    u64 light_anim_dictionary;
    u64 fog_anim_array;
    u64 fog_anim_dictionary;
    u64 user_data_array;
    u64 user_data_dictionary;
    u16 user_data_count;
    u16 camera_anim_count;
    u16 light_anim_count;
    u16 fog_anim_count;

    if (camera_anim_array != 0) {
        ResBfresCameraAnim o_camera_anim_array[camera_anim_count] @ camera_anim_array;
    }
    if (camera_anim_dictionary != 0) {
        ResNintendoWareDictionary o_camera_anim_dictionary @ camera_anim_dictionary;
    }
    if (light_anim_array != 0) {
        ResBfresLightAnim o_light_anim_array[light_anim_count] @ light_anim_array;
    }
    if (light_anim_dictionary != 0) {
        ResNintendoWareDictionary o_light_anim_dictionary @ light_anim_dictionary;
    }
    if (fog_anim_array != 0) {
        ResBfresFogAnim o_fog_anim_array[fog_anim_count] @ fog_anim_array;
    }
    if (fog_anim_dictionary != 0) {
        ResNintendoWareDictionary o_fog_anim_dictionary @ fog_anim_dictionary;
    }
    if (user_data_array != 0) {
        ResGfxUserData o_user_data_array[user_data_count] @ user_data_array;
    }
    if (user_data_dictionary != 0) {
        ResNintendoWareDictionary o_user_data_dictionary @ user_data_dictionary;
    }
};

/* Bfres */
fn GetBfresGpuRegionBase(u64 header_offset) {
    u64 memory_pool_info @ header_offset + 0xb0;
    u64 base @ memory_pool_info + 0x8;
    return base;
};

bitfield ResBfresExternalOptions {
    requires_external_model_initialization : 1;
    requires_external_strings              : 1;
    holds_external_strings                 : 1;
    is_extenral_gpu_region                 : 1;
    reserve0                               : 4;
};
struct ResBfres : ResNintendoWareFileHeader {
    u64 fres_name;
    u64 model_array;
    u64 model_dictionary;
    u64 reserve0;
    u64 reserve1;
    u64 reserve2;
    u64 reserve3;
    u64 skeletal_anim_array;
    u64 skeletal_anim_dictionary;
    u64 material_anim_array;
    u64 material_anim_dictionary;
    u64 bone_visibility_anim_array;
    u64 bone_visibility_anim_dictionary;
    u64 shape_anim_array;
    u64 shape_anim_dictionary;
    u64 scene_anim_array;
    u64 scene_anim_dictionary;
    u64 runtime_user_memory_pool;
    u64 memory_pool_info;
    u64 embed_file_array;
    u64 embed_file_dictionary;
    u64 transform_tree_or_user_pointer;
    u64 empty_string;
    u32 reserve5;
    u16 model_count;
    u16 reserve6;
    u16 reserve7;
    u16 skeletal_anim_count;
    u16 material_anim_count;
    u16 bone_visibility_anim_count;
    u16 shape_anim_count;
    u16 scene_anim_count;
    u16 embed_file_count;
    ResBfresExternalOptions external_options;
    u8 reserve8;

    u64 c_last_gpu_base = s_gpu_region_base;
    s_gpu_region_base   = GetBfresGpuRegionBase(addressof(this));

    u64 c_last_base = s_pointer_base;
    s_pointer_base  = addressof(this);
    
    if (fres_name != 0) {
        ResNintendoWareString o_fres_name @ fres_name + s_pointer_base;
    }
    if (empty_string != 0) {
        ResNintendoWareString o_empty_string @ empty_string + s_pointer_base;
    }
    if (model_array != 0) {
        ResBfresModel o_model_array[model_count] @ model_array + s_pointer_base;
    }
    if (model_dictionary != 0) {
        ResNintendoWareDictionary o_model_dictionary @ model_dictionary + s_pointer_base;
    }
    if (skeletal_anim_array != 0) {
        ResBfresSkeletalAnim o_skeletal_anim_array[skeletal_anim_count] @ skeletal_anim_array + s_pointer_base;
    }
    if (skeletal_anim_dictionary != 0) {
        ResNintendoWareDictionary o_skeletal_anim_dictionary @ skeletal_anim_dictionary + s_pointer_base;
    }
    if (material_anim_array != 0) {
        ResBfresMaterialAnim o_material_anim_array[material_anim_count] @ material_anim_array + s_pointer_base;
    }
    if (material_anim_dictionary != 0) {
        ResNintendoWareDictionary o_material_anim_dictionary @ material_anim_dictionary + s_pointer_base;
    }
    if (bone_visibility_anim_array != 0) {
        ResBfresBoneVisibilityAnim o_bone_visibility_anim_array[bone_visibility_anim_count] @ bone_visibility_anim_array + s_pointer_base;
    }
    if (bone_visibility_anim_dictionary != 0) {
        ResNintendoWareDictionary o_bone_visibility_anim_dictionary @ bone_visibility_anim_dictionary + s_pointer_base;
    }
    if (shape_anim_array != 0) {
        ResBfresShapeAnim o_shape_anim_array[shape_anim_count] @ shape_anim_array + s_pointer_base;
    }
    if (shape_anim_dictionary != 0) {
        ResNintendoWareDictionary o_shape_anim_dictionary @ shape_anim_dictionary + s_pointer_base;
    }
    if (scene_anim_array != 0) {
        ResBfresSceneAnim o_scene_anim_array[scene_anim_count] @ scene_anim_array + s_pointer_base;
    }
    if (scene_anim_dictionary != 0) {
        ResNintendoWareDictionary o_scene_anim_dictionary @ scene_anim_dictionary + s_pointer_base;
    }
    if (embed_file_count != 0) {
        ResGfxEmbedFile o_embed_file_array[embed_file_count] @ embed_file_array + s_pointer_base;
    }
    if (embed_file_dictionary != 0) {
        ResNintendoWareDictionary o_embed_file_dictionary @ embed_file_dictionary + s_pointer_base;
    }
    if (memory_pool_info != 0) {
        ResGfxMemoryPoolInfo o_memory_pool_info @ memory_pool_info + s_pointer_base;
    }
   s_pointer_base = c_last_base;
   s_gpu_region_base = c_last_gpu_base;
};

ResBfres head @ 0x0;