from fire import Fire
from CR import CRG, simd_sub, simd_mul, split_int

def make_carry_mask(width):
    not64, not128, not256 = 1,1,1
    if width == 64:
        not64, not128, not256 = 0,1,1
    elif width == 128:
        not64, not128, not256 = 0,0,1
    elif width == 256:
        not64, not128, not256 = 0,0,0

    return (not64 << 224) + (not128 << 192) + (not64 << 160) + (not256 << 128) + (not64 << 96) + (not128 << 64) + (not64 << 32) 
    

def CSA_256(a, b, c):
    ### Carry Save Adder
    mask = 2**256 - 1
    ps = a ^ b ^ c
    sc = (a & b) | (a & c) | (b & c)
    return ps & mask, sc & mask

def CSA_addsub_256(a, b, sub, width):
    ### Two's complement
    mask = 2**256-1 if sub else 0
    b = b ^ mask
    ones = make_carry_mask(width)*sub + sub
    return CSA_256(a, b, ones)
 
def ADD_32(a, b, c):
    """ Calculate a + b + c
    Args:
        a, b: Adder input less than 32 bits
        c: One-bit adder input 
    Returns:
        s: 32 bits a + b + c
        cy: 1 bit carry
    """
    sum = a + b + c
    s = sum & (2**32 -1)
    cy = sum >> 32
    return s, cy

def CSAMUL_256_32(a, b):
    """ 256 times 32 bits multiplier
    Args:
        a: Multiplicand
        b: Multiplier
    Returns:
        CSA form 256 bits integer, ps and sc.
    """

    mask = 2**256-1
    a = split_int(a, 32, False)
    ps, sc = 0, 0
    for i in range(8):
        pp = a[i] * b & mask
        ps, sc = CSA_256(ps, sc << 1, pp << i*32)

    return ps & mask, sc & mask

def simd_muland_hw(x, y, mode, width):
    """ AND or Multiply x and y
    Args:
        x,y: Operational input
        mode: 'a' or 'b'. When 'a'/'b', run multiply/and operation.
        width: SIMD operation width
    Returns:
        CSA form 256 bits integer, ps and sc.
    """
    mask32 = bytes([0xff, 0xff, 0xff, 0xff])
    zeros_4 = bytes([0, 0, 0, 0])
    mask64, mask128, mask256 = zeros_4, zeros_4, zeros_4
    if width == 64:
        mask64, mask128, mask256 = mask32, zeros_4, zeros_4
    elif width == 128:
        mask64, mask128, mask256 = mask32, mask32, zeros_4
    elif width == 256:
        mask64, mask128, mask256 = mask32, mask32, mask32
    
    y = split_int(y, 32, False)
    masks = [
        mask256 + mask256 + mask256 + mask256 + mask128 + mask128 + mask64  + mask32,
        mask256 + mask256 + mask256 + mask256 + mask128 + mask128 + mask32  + mask64,
        mask256 + mask256 + mask256 + mask256 + mask64  + mask32  + mask128 + mask128,
        mask256 + mask256 + mask256 + mask256 + mask32  + mask64  + mask128 + mask128,
        mask128 + mask128 + mask64  + mask32  + mask256 + mask256 + mask256 + mask256,
        mask128 + mask128 + mask32  + mask64  + mask256 + mask256 + mask256 + mask256,
        mask64  + mask32  + mask128 + mask128 + mask256 + mask256 + mask256 + mask256,
        mask32  + mask64  + mask128 + mask128 + mask256 + mask256 + mask256 + mask256
    ]
    shifts = [
        [0,0,0,0,0,0,0,0], # 32
        [0, 32, 0, 32, 0, 32, 0, 32], # 64
        [0, 32, 64, 96, 0, 32, 64, 96], # 128
        [0, 32, 64, 96, 128, 160, 192, 224] # 256
    ]
    tab = {32:0, 64:1, 128:2, 256:3}

    acc_ps, acc_sc = 0, 0
    for i in range(8):
        mask = int.from_bytes(masks[i], 'big')
        ps, sc = CSAMUL_256_32(x & mask, y[i])
        ps <<= shifts[tab[width]][i]
        sc <<= shifts[tab[width]][i] + 1
        ps &= mask
        sc &= mask
        # sc &= (2**256-1) ^ make_carry_mask(width) ### Probably unnecessary
        tmp_ps, tmp_sc = CSA_256(acc_ps, ps, sc)
        tmp_sc <<= 1
        tmp_sc &= (2**256-1) ^ make_carry_mask(width)
        acc_sc <<= 1
        acc_sc &= (2**256-1) ^ make_carry_mask(width)
        acc_ps, acc_sc = CSA_256(tmp_ps, tmp_sc, acc_sc)

    acc_sc &= ((2**256-1) ^ make_carry_mask(width) >> 1)
    return acc_ps, acc_sc

def simd_add_hw(x, y, width):
    """ Add x and y
    Args:
        x,y: Operational input
        width: SIMD operation width
    Returns:
        256 bits integer
    """
    is64, is128, is256 = 0,0,0
    if width == 64:
        is64, is128, is256 = 1,0,0
    elif width == 128:
        is64, is128, is256 = 1,1,0
    elif width == 256:
        is64, is128, is256 = 1,1,1

    ### CSA
    ps, sc = CSA_256(x, y, 0)
    sc <<= 1
    sc &= (2**256-1) ^ make_carry_mask(width)
    list_ps_32 = split_int(ps, 32, False)
    list_sc_32 = split_int(sc, 32, False)

    ### First stage adder
    list_sum_1 = [0] * 8
    list_cy_1 = [0] * 8
    for i in range(8):
        list_sum_1[i], list_cy_1[i] = ADD_32(list_ps_32[i], list_sc_32[i], 0)

    ### Second stage
    list_sum_2 = list_sum_1.copy()
    list_cy_2 = list_cy_1.copy()
    sum, cy = ADD_32(list_sum_1[1], 0, list_cy_1[0] & is64)
    list_sum_2[1] = sum
    list_cy_2[1] = cy

    ### Third stage
    list_sum_3 = list_sum_2.copy()
    list_cy_3 = list_cy_2.copy()
    sum, cy = ADD_32(list_sum_2[2], 0, (list_cy_2[1] | list_cy_1[1]) & is128)
    list_sum_3[2] = sum
    list_cy_3[2] = cy

    ### Fourth stage
    list_sum_4 = list_sum_3.copy()
    list_cy_4 = list_cy_3.copy()
    sum, cy = ADD_32(list_sum_3[3], 0, (list_cy_3[2] | list_cy_2[2]) & is64)
    list_sum_4[3] = sum
    list_cy_4[3] = cy

    ### Fifth stage
    list_sum_5 = list_sum_4.copy()
    list_cy_5 = list_cy_4.copy()
    sum, cy = ADD_32(list_sum_4[4], 0, (list_cy_4[3] | list_cy_3[3]) & is256)
    list_sum_5[4] = sum
    list_cy_5[4] = cy

    ### Sixth stage
    list_sum_6 = list_sum_5.copy()
    list_cy_6 = list_cy_5.copy()
    sum, cy = ADD_32(list_sum_5[5], 0, (list_cy_5[4] | list_cy_4[4]) & is64)
    list_sum_6[5] = sum
    list_cy_6[5] = cy

    ### Sevnth stage
    list_sum_7 = list_sum_6.copy()
    list_cy_7 = list_cy_6.copy()
    sum, cy = ADD_32(list_sum_6[6], 0, (list_cy_6[5] | list_cy_5[5]) & is128)
    list_sum_7[6] = sum
    list_cy_7[6] = cy

    ### Eigth stage
    list_sum_8 = list_sum_7.copy()
    list_cy_8 = list_cy_7.copy()
    sum, cy = ADD_32(list_sum_7[7], 0, (list_cy_7[6] | list_cy_6[6]) & is64)
    list_sum_8[7] = sum
    list_cy_8[7] = cy

    ret = 0
    for i in range(8):
        ret <<= 32
        ret |= list_sum_8[7-i]

    return ret

def simd_subxor_hw(x, y, mode, width):
    """ XOR or Subtruct x and y
    Args:
        x,y: Operational input
        mode: 'a' or 'b'. When 'a'/'b', run subtruct/xor operation.
        width: SIMD operation width
    Returns:
        256 bits integer
    """
    is64, is128, is256 = 0,0,0
    if width == 64:
        is64, is128, is256 = 1,0,0
    elif width == 128:
        is64, is128, is256 = 1,1,0
    elif width == 256:
        is64, is128, is256 = 1,1,1

    ### CSA
    sub = 1 if mode == 'a' else 0
    ps, sc = CSA_addsub_256(x, y, sub, width)
    sc <<= 1
    sc &= (2**256-1) ^ make_carry_mask(width)
    sc = sc if mode == 'a' else 0
    list_ps_32 = split_int(ps, 32, False)
    list_sc_32 = split_int(sc, 32, False)

    ### First stage adder
    list_sum_1 = [0] * 8
    list_cy_1 = [0] * 8
    for i in range(8):
        list_sum_1[i], list_cy_1[i] = ADD_32(list_ps_32[i], list_sc_32[i], 0)

    ### Second stage
    list_sum_2 = list_sum_1.copy()
    list_cy_2 = list_cy_1.copy()
    sum, cy = ADD_32(list_sum_1[1], 0, list_cy_1[0] & is64)
    list_sum_2[1] = sum
    list_cy_2[1] = cy

    ### Third stage
    list_sum_3 = list_sum_2.copy()
    list_cy_3 = list_cy_2.copy()
    sum, cy = ADD_32(list_sum_2[2], 0, (list_cy_2[1] | list_cy_1[1]) & is128)
    list_sum_3[2] = sum
    list_cy_3[2] = cy

    ### Fourth stage
    list_sum_4 = list_sum_3.copy()
    list_cy_4 = list_cy_3.copy()
    sum, cy = ADD_32(list_sum_3[3], 0, (list_cy_3[2] | list_cy_2[2]) & is64)
    list_sum_4[3] = sum
    list_cy_4[3] = cy

    ### Fifth stage
    list_sum_5 = list_sum_4.copy()
    list_cy_5 = list_cy_4.copy()
    sum, cy = ADD_32(list_sum_4[4], 0, (list_cy_4[3] | list_cy_3[3]) & is256)
    list_sum_5[4] = sum
    list_cy_5[4] = cy

    ### Sixth stage
    list_sum_6 = list_sum_5.copy()
    list_cy_6 = list_cy_5.copy()
    sum, cy = ADD_32(list_sum_5[5], 0, (list_cy_5[4] | list_cy_4[4]) & is64)
    list_sum_6[5] = sum
    list_cy_6[5] = cy

    ### Sevnth stage
    list_sum_7 = list_sum_6.copy()
    list_cy_7 = list_cy_6.copy()
    sum, cy = ADD_32(list_sum_6[6], 0, (list_cy_6[5] | list_cy_5[5]) & is128)
    list_sum_7[6] = sum
    list_cy_7[6] = cy

    ### Eigth stage
    list_sum_8 = list_sum_7.copy()
    list_cy_8 = list_cy_7.copy()
    sum, cy = ADD_32(list_sum_7[7], 0, (list_cy_7[6] | list_cy_6[6]) & is64)
    list_sum_8[7] = sum
    list_cy_8[7] = cy

    ret = 0
    for i in range(8):
        ret <<= 32
        ret |= list_sum_8[7-i]

    return ret

class CRG_HW(CRG):
    
    def _gen_cr(self):
        ### Random number generation
        a0 = self.PRNG256_0.gen()
        a  = self.PRNG256_1.gen()
        b  = self.PRNG256_2.gen()
        b0 = self.PRNG256_3.gen()
        c0 = self.PRNG256_4.gen()

        a1 = simd_subxor_hw(a, a0, self.abe, self.width)
        b1 = simd_subxor_hw(b, b0, self.abe, self.width)
        if self.abe == 'a':
            c  = simd_mul(a, b, self.width) # simd_mul_hw(a, b, self.abe,self.width)
        else:
            c = a & b
        c1 = simd_subxor_hw(c, c0, self.abe, self.width)

        self.n_stored_cr = self.cr_unit
        if self.abe == 'e':
            self.n_stored_cr -= 1

        self.stored_a0 = split_int(a0, self.width)
        self.stored_a1 = split_int(a1, self.width)
        self.stored_a  = split_int(a, self.width)
        self.stored_b0 = split_int(b0, self.width)
        self.stored_b1 = split_int(b1, self.width)
        self.stored_b  = split_int(b, self.width)
        self.stored_c0 = split_int(c0, self.width)
        self.stored_c1 = split_int(c1, self.width)
        self.stored_c  = split_int(c, self.width)

        self.stored_a0_B = list(map(int, bin(self.stored_a0[-1] & 0x7f)[2:].zfill(7)))
        self.stored_a1_B = list(map(int, bin(self.stored_a1[-1] & 0x7f)[2:].zfill(7)))
        if self.width == 64:
            self.stored_a0_B = [self.stored_a0_B[1], self.stored_a0_B[3], self.stored_a0_B[5]]
            self.stored_a1_B = [self.stored_a1_B[1], self.stored_a1_B[3], self.stored_a1_B[5]]


def main(cr_mode, n_cr = 1, party = 0):
    """
    Args:
        cr_mode: [REQUIRED] One of b256/128/64/32, a256/128/64/32, e64/32.
        n_cr:    The number of CRs to be generated.
        party:   Party number 0/1.
    Returns:
        n_cr correlated random numbers.
    """

    crg = CRG_HW(0, party, cr_mode)
    print(crg.get_cr())

if __name__ == "__main__":
    Fire(main)
