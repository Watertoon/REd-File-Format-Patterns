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
enum FcpxFontType : u32 {
    Res      = 0,
    Scalable = 1,
    Pair     = 2,
};

struct ResFcpxTree {
    FcpxFontType font_type;
    
    if (font_type == FcpxFontType::Res) {
        u32 font_name_offset;
        
        
        char o_font_name[] @ addressof(this) + font_name_offset;
    } else if (font_type == FcpxFontType::Scalable) {
        float reserve0;
        
    } else if (font_type == FcpxFontType::Pair) {
        u32 left_font_offset;
        u32 right_font_offset;
    
        ResFcpxTree o_left_font @ addressof(this) + left_font_offset;
        ResFcpxTree o_right_font @ addressof(this) + right_font_offset;
    }
    
};

struct ResFcpx {
    u32 magic;
    u16 endianess;
    u16 header_size;
    u32 version;
    u32 file_size;
    u32 section_count;
    u32 tree_offset;
    
    ResFcpxTree o_root @ addressof(tree_offset) + tree_offset;
};

ResFcpx head @ 0x0;
