from fire import Fire
from CR import CRG, simd_sub, simd_mul, split_int


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
