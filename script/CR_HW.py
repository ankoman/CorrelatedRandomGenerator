from fire import Fire
from CR import CRG, simd_sub, simd_mul, split_int, PRNG_256

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
        pp = a[i] * b
        ps, sc = CSA_256(ps, sc << 1, pp << i*32)

    return ps & mask, sc & mask

def simd_muland_hw(x, y, mode, width):
    """ AND or Multiply x and y
    Args:
        x,y: Operational input
        mode: 'a', 'e', or 'b'. When 'a' or 'e', run multiply operation. Otherwise when 'b', run and operation.
        width: SIMD operation width
    Returns:
        CSA form 256 bits integer, ps and sc.
    """
    mask32 = bytes([0xff, 0xff, 0xff, 0xff])
    zeros_4 = bytes([0, 0, 0, 0])
    mask64, mask128, mask256 = zeros_4, zeros_4, zeros_4
    if mode == 'b':
        mask64, mask128, mask256 = mask32, mask32, mask32   ### 256
    else:
        if width == 64:
            mask64, mask128, mask256 = mask32, zeros_4, zeros_4
        elif width == 128:
            mask64, mask128, mask256 = mask32, mask32, zeros_4
        elif width == 256:
            mask64, mask128, mask256 = mask32, mask32, mask32
    
    is_a = 0 if mode == 'b' else 1
    mask_in = 2**256-1
    x_in = x & (y | (mask_in * is_a))
    y_in = (y & (mask_in * is_a)) | (1 ^ is_a)
    y_in = split_int(y_in, 32, False)
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
        ps, sc = CSAMUL_256_32(x_in & mask, y_in[i])
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

def adder_tree(list_ps_32, list_sc_32, tab_carrychain):

    ### First stage adder
    list_sum = [0] * 8
    list_cy = [0] * 8
    for i in range(8):
        list_sum[i], list_cy[i] = ADD_32(list_ps_32[i], list_sc_32[i], 0)

    ### Second to eigth stage adder
    prev_cy = 0
    for i in range(7):
        sum, cy = ADD_32(list_sum[i+1], 0, (list_cy[i] | prev_cy) & tab_carrychain[i])
        prev_cy = list_cy[i+1]
        list_sum[i+1] = sum
        list_cy[i+1] = cy

    ret = 0
    for i in range(8):
        ret <<= 32
        ret |= list_sum[7-i]
    
    return ret

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

    tab_carrychain = [is64, is128, is64, is256, is64, is128, is64]

    ### CSA
    ps, sc = CSA_256(x, y, 0)
    sc <<= 1
    sc &= (2**256-1) ^ make_carry_mask(width)
    list_ps_32 = split_int(ps, 32, False)
    list_sc_32 = split_int(sc, 32, False)

    return adder_tree(list_ps_32, list_sc_32, tab_carrychain)

def simd_subxor_hw(x, y, mode, width, extra_term = None):
    """ XOR or Subtruct x and y
    Args:
        x,y: Operational input
        mode: 'a', 'e', or 'b'. When 'a' or 'e', run subtruct. Otherwise when 'b', run xor operation.
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

    tab_carrychain = [is64, is128, is64, is256, is64, is128, is64]

    ### CSA
    sub = 0 if mode == 'b' else 1
    ps, sc = CSA_addsub_256(x, y, sub, width)
    sc <<= 1
    sc &= (2**256-1) ^ make_carry_mask(width)
    sc = 0 if mode == 'b' else sc
    if extra_term is not None:
        ps, sc = CSA_256(ps, sc, extra_term)
        sc <<= 1
        sc &= (2**256-1) ^ make_carry_mask(width)
        
    list_ps_32 = split_int(ps, 32, False)
    list_sc_32 = split_int(sc, 32, False)

    return adder_tree(list_ps_32, list_sc_32, tab_carrychain)

class CRG_HW(CRG):
    
    def _gen_cr(self):
        ### Random number generation
        a0 = self.PRNG256_0.gen()
        a  = self.PRNG256_1.gen()
        b  = self.PRNG256_2.gen()
        b0 = self.PRNG256_3.gen()
        c0 = self.PRNG256_4.gen()

        ### Correlation calculation
        mask = 0x0000000100000001000000010000000100000001000000010000000100000001 if self.width == 32 else 0x0000000000000001000000000000000100000000000000010000000000000001 if self.width == 64 else None
        if self.abe == 'e':
            a = a & mask
        a1 = simd_subxor_hw(a, a0, self.abe, self.width)
        b1 = simd_subxor_hw(b, b0, self.abe, self.width)
        ps, sc  = simd_muland_hw(a, b, self.abe, self.width)
        c = simd_add_hw(ps, sc << 1, self.width)    # Not necessary, but remains for debugging purposes
        c1 = simd_subxor_hw(ps, c0, self.abe, self.width, sc << 1)

        ### For extended triples
        if self.cnt_ext == 0:
            self.e0_raw = self.PRNG256_5.gen()
            self.cnt_ext = 10
        else:
            self.cnt_ext -= 1
            self.e0_raw >>= 8
        e0 = self.e0_raw & 0xff

        e = 0
        for i in range(8):
            a_bit = (a >> (32 * i)) & 1
            e |= a_bit << i
        e1 = e ^ e0

        ### Store
        self.stored_a0 = split_int(a0, self.width)
        self.stored_a1 = split_int(a1, self.width)
        self.stored_a  = split_int(a, self.width)
        self.stored_b0 = split_int(b0, self.width)
        self.stored_b1 = split_int(b1, self.width)
        self.stored_b  = split_int(b, self.width)
        self.stored_c0 = split_int(c0, self.width)
        self.stored_c1 = split_int(c1, self.width)
        self.stored_c  = split_int(c, self.width)   # Not necessary, but remains for debugging purposes

        self.stored_e0 = list(map(int, bin(e0)[2:].zfill(8)))
        self.stored_e1 = list(map(int, bin(e1)[2:].zfill(8)))
        if self.width == 64:
            self.stored_e0 = [self.stored_e0[1], self.stored_e0[3], self.stored_e0[5], self.stored_e0[7]]
            self.stored_e1 = [self.stored_e1[1], self.stored_e1[3], self.stored_e1[5], self.stored_e1[7]]

        self.n_stored_cr = self.cr_unit

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

    key = 0x2b7e151628aed2a6abf7158809cf4f3c
    prng = PRNG_256(key.to_bytes(16, 'big'), 0)
    for i in range(256):
        print(hex(prng.gen()))

if __name__ == "__main__":
    Fire(main)
