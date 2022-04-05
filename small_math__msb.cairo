
# THIS FUNCTION COMPUTES THE MOST SIGNIFICANT BIT OF ANY FELT
# The number of steps stays around 250.
#
# Revision: 0.1 - 2022-04-05

%builtins bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_not, bitwise_and

func Small_Math__msb{bitwise_ptr : BitwiseBuiltin*}(x: felt) -> (res: felt):
    alloc_locals

    # This array will contain the carrying value in the odd indexes and the coefficient in the even indexes
    let (local results : felt*) = alloc() 

    tempvar not_filter_128 = 340282366920938463463374607431768211455
    tempvar not_filter_64 = 6277101735386680763495507056286727952657427581105975853055
    tempvar not_filter_32 = 26959946660873538060741835960174461801791452538186943042387869433855
    tempvar not_filter_16 = 1766820105243087041267848467410591083712559083657179364930612997358944255
    tempvar not_filter_8 = 450552876409790643671482431940419874915447411150352389258589821042463539455
    tempvar not_filter_4 = 3192796578234821564988170542518968047424723841883471434911514264924075265807
    tempvar not_filter_2 = 1447401115466452442794637312608598848165874808320507050493219800098914120499
    tempvar not_filter_1 = 2412335192444087404657728854347664746943124680534178417488699666831523534165

    tempvar filter_128 = 3618502788666131106986593281521497120074404653880329162769674892815517089792
    tempvar filter_64 = 3618502788666131100709491546134816356919179964514539673575621919141309448192
    tempvar filter_32 = 3618502761706184446113055220779661160240225219009815088046106457859415867392
    tempvar filter_16 = 3616735968560888019945325433054086529330974461717610446868118887249926356992
    tempvar filter_8 = 3167949912256340463315110849581077245499239609650915236974459679204821761792
    tempvar filter_4 = 425706210431309541998422739002529072989963178917796191321535235323210035440
    tempvar filter_2 = 2171101673199678664191955968912898272248812212480760575739829700148371180748
    tempvar filter_1 = 1206167596222043702328864427173832373471562340267089208744349833415761767082

    # In the following 8 cycles, the value goes through 8 251-bits filters, e.g.:
    # filter_4 = 1111000011110000...
    # filter_8 = 1111111100000000...
    # In each cycle the algorithm computes if there's a significant bit in the most significant half and carries the significant part. 
    let (and_128) = bitwise_and(x, filter_128)
    if and_128 == 0:
        let(temp_128) = bitwise_and(x, not_filter_128)
        assert[results] = temp_128
        assert[results + 1] = 0
    else:
        assert[results] = and_128
        assert[results + 1] = 1
    end
    let (and_64) = bitwise_and([results], filter_64)
    if and_64 == 0:
        let(temp_64) = bitwise_and([results], not_filter_64)
        assert[results + 2] = temp_64
        assert[results + 3] = 0
    else:
        assert[results + 2] = and_64
        assert[results + 3] = 1
    end
    let (and_32) = bitwise_and([results+2], filter_32)
    if and_32 == 0:
        let(temp_32) = bitwise_and([results+2], not_filter_32)
        assert[results + 4] = temp_32
        assert[results + 5] = 0
    else:
        assert[results + 4] = and_32
        assert[results + 5] = 1
    end
    let (and_16) = bitwise_and([results+4], filter_16)
    if and_16 == 0:
        let(temp_16) = bitwise_and([results+4], not_filter_16)
        assert[results + 6] = temp_16
        assert[results + 7] = 0
    else:
        assert[results + 6] = and_16
        assert[results + 7] = 1
    end
    let (and_8) = bitwise_and([results+6], filter_8)
    if and_8 == 0:
        let(temp_8) = bitwise_and([results+6], not_filter_8)
        assert[results + 8] = temp_8
        assert[results + 9] = 0
    else:
        assert[results + 8] = and_8
        assert[results + 9] = 1
    end
    let (and_4) = bitwise_and([results+8], filter_4)
    if and_4 == 0:
        let(temp_4) = bitwise_and([results+8], not_filter_4)
        assert[results + 10] = temp_4
        assert[results + 11] = 0
    else:
        assert[results + 10] = and_4
        assert[results + 11] = 1
    end    
    let (and_2) = bitwise_and([results+10], filter_2)
    if and_2 == 0:
        let(temp_2) = bitwise_and([results+10], not_filter_2)
        assert[results + 12] = temp_2
        assert[results + 13] = 0
    else:
        assert[results + 12] = and_2
        assert[results + 13] = 1
    end    
    let (and_1) = bitwise_and([results+12], filter_1)
    if and_1 == 0:
        let(temp_1) = bitwise_and([results+12], not_filter_1)
        assert[results + 14] = temp_1
        assert[results + 15] = 0
    else:
        assert[results + 14] = and_1
        assert[results + 15] = 1
    end

    tempvar res = [results+15]+[results+13]*2+[results+11]*4+[results+9]*8+[results+7]*16+[results+5]*32+[results+3]*64+[results+1]*128 
    return(res = res)
end


func main {bitwise_ptr : BitwiseBuiltin*} ():
    alloc_locals

    # Use test_1 to check the most significant bit of any felt value
    local test_1 = 2**137 + 1643546843453453435453 
    let (msb_1) = Small_Math__msb(test_1)
    %{
        print(' msb('+str(ids.test_1)+'): '+str(ids.msb_1))
    %}
    return()
end