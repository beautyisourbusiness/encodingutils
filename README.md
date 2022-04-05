# encodingutils
Small utils for encoding/decoding in Cairo

* small_math__msb.cairo - This function computes the most significant bit of a felt. The number of steps stays around 250. Revision: 0.1 - 2022-04-05
* small_math_bitpattern.cairo - pattern_encoder() and pattern_decoder() are twin functions that encode/decode bitwise using the BitPattern struct. The encoder takes n values and a BitPattern representing the groups of bits reserved for them to be encoded and returns a unique felt representing those values. The decoder proceeds the other way around, taking an encoded felt and returning the array of values that are extracted from that felt.
