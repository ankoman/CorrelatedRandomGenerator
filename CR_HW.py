from fire import Fire
from CR import CRG, simd_sub, simd_mul, split_int

def CSA_256(a, b, c):
    ### Carry Save Adder
    mask = 2**256 - 1
    ps = a ^ b ^ c
    sc = (a & b) | (a & c) | (b & c)
    return ps & mask, sc & mask

def CSA_addsub_256(a, b, sub):
    ### CSA
    mask = 2**256-1 if sub else 0
    b = b ^ mask
    return CSA_256(a, b, sub)
 

def ADD_32(a, b, c):
    """ Calculate a + b + c
    Args:
        a, b: Adder input less than 32 bits
        c: One-bit adder input 
    Returns:
        s = 32 bits a + b + c
        cy = 1 bit carry
    """
    sum = a + b + c
    s = sum & (2**32 -1)
    cy = sum >> 32
    return s, cy

def TreeAdder(x, y, mode, width):
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
    ps, sc = CSA_addsub_256(x, y, sub)
    sc <<= 1
    list_ps_32 = split_int(ps, 32)
    list_sc_32 = split_int(sc, 32)

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

        if self.abe == 'b':
            ### Boolean
            a1 = a ^ a0
            b1 = b ^ b0
            c  = a & b
            c1 = c ^ c0
        elif self.abe == 'a':
            ### Arithmetic
            a1 = simd_sub(a, a0, self.width)
            b1 = simd_sub(b, b0, self.width)
            c  = simd_mul(a, b, self.width)
            c1 = simd_sub(c, c0, self.width)
        elif self.abe == 'e':
            ### Extended
            mask = 0x0000000100000001000000010000000100000001000000010000000100000001 if self.width == 32 else 0x10000000000000001000000000000000100000000000000010000000000000001 if self.width == 64 else None
            a = a & mask

            tmp_a_B = 0
            for i in range(8 - 1):
                a_bit = (a >> (32 * (i + 1))) & 1
                tmp_a_B |= a_bit << i

            a1 = simd_sub(a, a0, self.width)
            a1_B = (tmp_a_B ^ a0) & 0x7f
            a1 = a1 >> 7
            a1 = a1 << 7
            a1 = a1 | a1_B
            b1 = simd_sub(b, b0, self.width)
            c  = simd_mul(b, a, self.width)
            c1 = simd_sub(c, c0, self.width)

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


def main(cr_mode, n_cr = 1):
    """
    Args:
        cr_mode: [REQUIRED] One of b256/128/64/32, a256/128/64/32, e64/32.
        n_cr:    The number of CRs to be generated.
    Returns:
        n_cr correlated random numbers.
    """

    crg = CRG_HW(0, 0, cr_mode)
    print(crg.get_cr())

if __name__ == "__main__":
    Fire(main)
