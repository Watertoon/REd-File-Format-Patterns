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
u32 s_file_base = 0;

/* Epd Binary Wave (bwav) */
struct ResBwavChannelInfo {
    u16 reserve0;
    u16 channel_pan;
    u32 sample_rate;
    u32 non_prefetch_sample_count;
    u32 sample_count;
    u16 dsp_adpcm_coefficients[16];
    u32 non_prefetch_samples_offset;
    u32 samples_offset;
    u32 is_looping;
    u32 loop_end;
    u32 loop_start;
    u16 reserve1;
    u16 reserve2;
    u16 reserve3;
    u16 reserve4;
    
    u32 aligned_sample_size   = ((sample_count / 14) * 8);
    u32 unaligned_sample_size = ((sample_count % 14) == 0) ? 0 : ((sample_count % 14) / 2) + (sample_count % 2) + 1;
 
    u8  o_samples[(aligned_sample_size + unaligned_sample_size)] @ s_file_base + samples_offset;
};

struct ResBwav {
    u32 magic;
    u16 endianess;
    u16 version;
    u32 samples_crc32;
    u16 is_prefetch;
    u16 channel_count;
    
    u32 last_base = s_file_base;
    s_file_base   = addressof(this);

    ResBwavChannelInfo channel_info_array[channel_count];

    s_file_base   = last_base;
};

/* Epd Meta Info? (minf) */
struct ResMinfTable0Entry {
    u32 reserve0;
    u16 reserve1;
    u8  reserve2;
    u8  reserve3;
    u16 reserve4;
    u16 reserve5;
};

struct ResMinfTable0 {
    u16 count;
    u16 reserve0;
    ResMinfTable0Entry entry_array[count];
};

struct ResMinfTable1Entry {
    u32 reserve0;
    u32 reserve1;
    u32 reserve2;
    u32 reserve3;
};

struct ResMinfTable1 {
    u16 count;
    u16 reserve0;
    ResMinfTable1Entry entry_array[count];
};

struct ResMinfTable2Entry {
    u32 reserve0;
    u32 reserve1;
    u32 reserve2;
    float reserve3;
    u32 reserve4;
};

struct ResMinfTable2 {
    u16 count;
    u16 reserve0;
    ResMinfTable2Entry entry_array[count];
};

struct ResMinfPair {
    u32 reserve0;
    u32 reserve1;
}; /* sample offset, some id or count? */

struct ResMinfPairTable {
    u16 count;
    u16 reserve0;
    ResMinfPair pair_array[count];
};

struct ResMinfOffsetTable {
    u16 count;
    u16 reserve0;
    u32 offset_array[count];
};

struct ResMinfInstrument {
    u32 instrument_name_offset;
    u32 reserve0;
    u32 reserve1;
    
    char o_instrument_name[] @ addressof(instrument_name_offset) + instrument_name_offset;
};

struct ResMinfInstrumentInfo {
    u32 reserve0;
    u32 instrument_offset;
    
    ResMinfInstrument o_instrument @ addressof(instrument_offset) + instrument_offset;
};

struct ResMinfInstrumentInfoTable {
    u16 count;
    u16 reserve0;
    
    ResMinfInstrumentInfo instrument_info_array[count];
};

struct ResMinf {
    u32 magic;
    u16 endianess;
    u8  major_version;
    u8  minor_version;
    u32 file_size;
    u32 name_offset;
    u32 reserve0;
    u32 sample_rate;
    u32 reserve1;
    u32 reserve2;
    u32 reserve3;
    u16 reserve4;
    u8  reserve5;
    u8  reserve6;
    u16 reserve7;
    u16 reserve8;
    u32 table0_offset;
    u32 table1_offset;
    u32 table2_offset;
    u32 pair_table_offset;
    u32 offset_table_offset;
    u32 instrument_info_table_offset;
    u32 reserve15;
    u32 reserve16;
    
    ResMinfTable0      o_table0 @ addressof(table0_offset) + table0_offset;
    ResMinfTable1      o_table1 @ addressof(table1_offset) + table1_offset;
    ResMinfTable2      o_table2 @ addressof(table2_offset) + table2_offset;
    ResMinfPairTable   o_pair_table @ addressof(pair_table_offset) + pair_table_offset;
    ResMinfOffsetTable o_offset_table @ addressof(offset_table_offset) + offset_table_offset;
    ResMinfInstrumentInfoTable o_instrument_info_table @ addressof(instrument_info_table_offset) + instrument_info_table_offset;
    //u32 offset_count;
    //u32 offset_array[offset_count];
    
    char o_name[] @ addressof(name_offset) + name_offset;
};

/* Epd Binary Audio Meta Data (bamta) */
struct ResBamtaPoint {
    u32   reserve0;
    float reserve1;
}; /* Float and maybe sample offset? */

struct ResBamtaData {
    u32   reserve0;
    float reserve1;
    float reserve2;
    float reserve3;
    float reserve4;
    u16   point_count;
    u16   reserve6;
    
    ResBamtaPoint point_array[point_count];
};

struct ResBamtaMarker {
    u32 id;
    u32 name_offset;
    u32 start;
    u32 length;

    char o_name[] @ addressof(name_offset) + name_offset;
};

struct ResBamtaMarkerTable {
    u32            marker_count;
    ResBamtaMarker marker_array[marker_count];
};

struct ResBamtaTag {
    u32 tag_offset;
    
    char o_tag[] @ addressof(tag_offset) + tag_offset;
};

struct ResBamtaTagTable {
    u32 count;
    ResBamtaTag tag_array[count];
};

struct ResBamta {
    u32 magic;
    u16 endianess;
    u8  minor_version;
    u8  major_version;
    u32 file_size;
    u32 reserve0;
    u32 data_offset;
    u32 marker_offset;
    u32 minf_offset;
    u32 tag_offset;
    u32 reserve4;
    u32 path_offset;
    u32 path_hash;
    u32 reserve6;
    u8  type;
    u8  channels;
    u8  reserve7;
    u8  flags;
    
    u32 last_base = s_file_base;
    s_file_base   = addressof(this);
    
    if (data_offset != 0) {
        ResBamtaData o_data @ s_file_base + data_offset;
    }
    if (marker_offset != 0) {
        ResBamtaMarkerTable o_marker_table @ s_file_base + marker_offset;
    }
    if (minf_offset != 0) {
        ResMinf o_minf @ s_file_base + minf_offset;
    }
    if (tag_offset != 0) {
        ResBamtaTagTable o_tag_table @ s_file_base + tag_offset;
    }
    char                o_path[]       @ addressof(path_offset) + path_offset;
     
    s_file_base   = last_base;
};

/* Epd Binary Audio Resources (bars) */
struct ResBarsEntry {
    u32 bamta_offset;
    u32 bwav_offset;
    
    ResBamta o_bamta @ bamta_offset;
    ResBwav  o_bwav @ bwav_offset;
};

struct ResBars {
    u32 magic;
    u32 file_size;
    u16 endianess;
    u8  minor_version;
    u8  major_version;
    u32 file_count;
    u32 file_path_hash_array[file_count];
    ResBarsEntry entry_array[file_count];
    u32 reserve_file_count;
    u32 reserve_path_hash_array[reserve_file_count];
    
    u32 last_base = s_file_base;
    s_file_base   = addressof(this);
    
    
    s_file_base   = last_base;
};

ResBars head @ 0x0;