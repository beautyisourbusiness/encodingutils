
################ WARNING : LIB UNDER DEVELOPMENT #######################
# WARNING: This funcions don't check the values you are passing
# Please be aware of weird behavior if the values overflow
# Note that: a felt has 251 available bits
# The number of patterns (including repetitions) and values must match
################ WARNING : LIB UNDER DEVELOPMENT #######################

# THIS SET OF FUNCTIONS ALLOW ENCODING AND DECODING FELTS BITWISE USING BIT-PATTERNS
#
# Revision: 0.1 - 2022-04-05

%builtins output range_check bitwise

from pow2 import pow2

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin


###################### BIT PATTERN STRUCT ###############################
# You need to import this struct to use this file
# This struct allows you to fix a pattern of bits, allowing (not nested)
# repetitions to make it easier. 

struct BitPattern:
    member bit_size: felt
    member repetition: felt
end

###################### ENCODING UTIL #################################
# This function uses the BitPattern struct to encode a felt, taking
# full advantage of the 251 bits. There should be more efficient ways
# to take advantage of the representation system in the cyclic P group,
# but for now this seems to be acceptable.
# The first bitpattern of the array will use the less significant bits.

func pattern_encoder {range_check_ptr} (
        words: felt*, patterns: BitPattern*, patterns_size: felt) -> (encoded_felt: felt):
    alloc_locals
    let (bit_sizes : felt*) = alloc()
    let (bit_sizes_size) = unfold_patterns(bit_sizes, patterns, patterns_size)
    let (encoded_felt) = encode_words (words, bit_sizes, bit_sizes_size)

    return (encoded_felt = encoded_felt)
end

# This function encodes the n words in words:felt* with bit_sizes:felt* lengths. Both arrays have the same size. Last In First Out model.
func encode_words {range_check_ptr} (words: felt*, bit_sizes: felt*, size: felt) -> (encoded_felt: felt):
    if size == 0:
        return (encoded_felt = 0)
    end
    let (temp_encoded_felt) = encode_words(words + 1, bit_sizes + 1, size - 1)
    let this_word = [words]
    let this_bit_size = [bit_sizes]
    let (encoded_felt) = encode_word (temp_encoded_felt, this_word, this_bit_size)

    return (encoded_felt = encoded_felt)
end

func encode_word {range_check_ptr} (encoded_felt: felt, word: felt, word_bit_size: felt) -> (new_code: felt):
    let (bit_size_pow) = pow2 (word_bit_size)
    tempvar new_code = encoded_felt * bit_size_pow + word
    return (new_code = new_code)
end

# Concatenate wrapper for the above func, as a word can be seen also as a complete code.
func concatenate_codes {range_check_ptr} (code_1: felt, code_2: felt, word_bit_size: felt) -> (new_code: felt):
    let (new_code) = encode_word (code_1, code_2, word_bit_size)
    return (new_code = new_code)
end

###################### DECODING UTIL ###############################
# Corresponding decoding functions

func pattern_decoder {range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        encoded_felt: felt, patterns: BitPattern*, patterns_size: felt) -> (decoded_words: felt*):
    alloc_locals
    let (bit_sizes : felt*) = alloc()
    let (bit_sizes_size) = unfold_patterns(bit_sizes, patterns, patterns_size)

    let(decoded_words: felt*) = alloc()

    let (decoded_words) = decode_words (encoded_felt, bit_sizes, bit_sizes_size)

    return (decoded_words = decoded_words)
end

# Decode_words wrapper. Better coding ideas here?
func decode_words {range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        encoded_felt: felt, bit_sizes: felt*, size: felt) -> (decoded_words: felt*):
    alloc_locals
    let (decoded_words: felt*) = alloc()
    decode_words_inner (decoded_words, encoded_felt, bit_sizes, size, 0)
    return (decoded_words = decoded_words)
end

# This function decodes size words in a given in a felt. The words are decoded according with the sizes in bit_sizes.
# Follows the LIFO model (see encode_words func)
func decode_words_inner {range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        decoded_words: felt*, encoded_felt: felt, bit_sizes: felt*, size: felt, index: felt):
    if index == size:
        return ()
    end
    let this_bit_size = [bit_sizes + index]
    let (remaining_encoded_felt, temp_word) = decode_word(encoded_felt, this_bit_size)
    assert [decoded_words + index] = temp_word
    decode_words_inner (decoded_words, remaining_encoded_felt, bit_sizes, size, index + 1)
    return()
end

# This function decodes the word contained in the bit_sizes significant bits of the encoded_felt
# Returns the extracted word and the encoded felt shifted to the right bit_sizes
func decode_word {range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (encoded_felt: felt, bit_size: felt) -> (remaining_encoded_felt: felt, word: felt):
    let (bit_size_pow) = pow2 (bit_size)
    tempvar bit_size_ones = bit_size_pow - 1
    let (extracted_word) = bitwise_and (encoded_felt, bit_size_ones)
    tempvar encoded_felt_minus_word = encoded_felt - extracted_word
    tempvar shifted_encoded_felt = encoded_felt_minus_word / bit_size_pow
    return (remaining_encoded_felt = shifted_encoded_felt, word = extracted_word)
end


###################### BITPATTERN UTILS ###############################

func unfold_patterns (bit_sizes: felt*, patterns: BitPattern*, patterns_size: felt) -> (size: felt):
    alloc_locals
    if patterns_size == 0:
        return(size = 0)
    end
    tempvar this_pattern = [patterns]
    tempvar this_pattern_bit_size = this_pattern.bit_size
    tempvar this_pattern_repetition = this_pattern.repetition
    add_bit_size(bit_sizes, this_pattern_bit_size, this_pattern_repetition)
    let (temp_size) = unfold_patterns (bit_sizes + this_pattern_repetition, patterns + 2, patterns_size - 1)
    return(size = temp_size + this_pattern_repetition)
end

func add_bit_size (bit_sizes: felt*, this_pattern_bit_size: felt, this_pattern_repetition: felt):
    if this_pattern_repetition == 0:
        return()
    end
    assert [bit_sizes + this_pattern_repetition - 1] = this_pattern_bit_size
    add_bit_size (bit_sizes, this_pattern_bit_size, this_pattern_repetition - 1)
    return()
end


###################### SOME TESTING ###############################

func main {output_ptr: felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} ():
    alloc_locals

    # Constructing the BitPattern array
    let (my_patterns : BitPattern*) = alloc()
    # Two consecutive slots of 3 bits. Values range: 0-7, each.
    let pattern_1 : BitPattern = BitPattern(3, 2)
    # One more slot with 5 bits. Values range: 0-31, each.
    let pattern_2 : BitPattern = BitPattern(5, 1)
    # Filling the BitPattern array
    assert [my_patterns] = pattern_1
    assert [my_patterns + BitPattern.SIZE] = pattern_2

    # Constructing the values array
    let(my_values : felt*) = alloc()
    assert [my_values] = 7
    assert [my_values + 1] = 4
    assert [my_values + 2] = 21

    # The algorithm proceeds the following way:
    #
    # First step: places the value 21 in the 5 bits slot
    # code = ...00000010101
    # Second step: places the value 4 in the first 3 bits slot
    # code = ...00010101100
    # Third step: places the value 7 in the second 3 bits slot
    # code = ...10101100111

    # The my_patterns array has 2 BitPatterns, so the size is 2
    tempvar my_patterns_size = 2
    let (my_code) = pattern_encoder (my_values, my_patterns, my_patterns_size)
    # my_code = 1383 ~ 10101100111, 21 ~ 10101, 4 ~ 100, 7 ~ 111
    %{
        print (' ------------------------------')
        print (' Encoding results:')
        print (' my_code: ' + str(ids.my_code))
    %}

    let (decoded_felt_array) = pattern_decoder (my_code, my_patterns, my_patterns_size)
    tempvar decoded_felt_array_1 = [decoded_felt_array]
    tempvar decoded_felt_array_2 = [decoded_felt_array + 1]
    tempvar decoded_felt_array_3 = [decoded_felt_array + 2]
    %{
        print (' ------------------------------')
        print (' Decoding results:')
        print (' decoded_felt_array_1: '+ str(ids.decoded_felt_array_1))
        print (' decoded_felt_array_2: '+ str(ids.decoded_felt_array_2))
        print (' decoded_felt_array_3: '+ str(ids.decoded_felt_array_3))
        print (' ------------------------------')
    %}

    return()
end