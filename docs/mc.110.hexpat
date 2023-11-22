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
#pragma loop_limit 5000000

#include <std/io.pat>
#include <std/mem.pat>
#include <std/core.pat>

/* Helpers for magic */
fn TCharCode32LittleEndian(str string) {
    u32 magic = (string[0] << 0x0) + (string[1] << 0x8) + (string[2] << 0x10) + (string[3] << 0x18);
    return magic;
};
fn TCharCode32BigEndian(str string) {
    u32 magic = (string[0] << 0x18) + (string[1] << 0x10) + (string[2] << 0x8) + (string[3] << 0x0);
    return magic;
};

/* NintendoWare MeshCodec header */
enum DecompressionType : u8 {
    None  = 0,
    Zstd  = 1,
    Type2 = 2,
};
bitfield DecompressionFlags {
    DecompressionType decompression_type : 2;
    reserve1                             : 14; /* Must be less than 0x400 */
};
struct ResFmshContext {
    DecompressionFlags decompression_flags;
    u24                vertex_stream_size; /* 2 sizes, possibly index and vertex buffer sizes */
    u24                index_stream_size;
};

struct ResFmsh {
    u32            magic;
    u32            version;
    u32            required_work_memory;
    u32            reserve0;
    u32            index_output_size;
    u32            vertex_output_size;
    u8             index_alignment; /* Possibly index and vertex alignment? */
    u8             vertex_alignment;
    ResFmshContext fmsh_context;
};
u32 c_fmsh_magic = TCharCode32LittleEndian("FMSH");

/* Find FMSH section by iteration if it exists, since we don't have Zstd or Bfres implemented */
fn FindFMSHSection() {

    u32 offset = 0;
    while (offset != sizeof($)) {
        u32 magic @ offset;
        if (magic == c_fmsh_magic) { return offset; }
        offset = offset + 4;
    }
    return 0xffffffff;
};

const u32 c_fmsh_offset = FindFMSHSection();
std::print("FMSH offset: {:#08x}", c_fmsh_offset);

/* Nintendo EPD Mc header */
struct ResMc {
    u32 magic;
    u8  micro_version;
    u8  minor_version;
    u16 major_version;
    u32 packed_size;
    
    if (c_fmsh_offset != 0xffffffff) {
        ResFmsh o_fmsh @ c_fmsh_offset;
    }
};

ResMc head @ 0x0;

/* Print decompressed output size */
fn GetOutputBufferSize() {
    return (head.packed_size >> 5) << (head.packed_size & 0xf);
};
std::print("Output buffer size: {:#08x}", GetOutputBufferSize());

/* Print decompressed alignment */
fn GetDecompressedAlignment() {
    return 1 << (head.packed_size & 0xf);
};
std::print("Decompressed alignment: {:#08x}", GetDecompressedAlignment());