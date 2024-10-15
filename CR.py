import Crypto.Cipher.AES as AES
from Crypto.Util import Counter
import random
from fire import Fire


def print_shares():
    global a0, a1, a, b0, b1, b, c0, c1, c
    print(f"{a0 = :064x}")
    print(f"{a1 = :064x}")
    print(f"{a  = :064x}")
    print(f"{b0 = :064x}")
    print(f"{b1 = :064x}")
    print(f"{b  = :064x}")
    print(f"{c0 = :064x}")
    print(f"{c1 = :064x}")
    print(f"{c  = :064x}")

def simd_mulsub(x, y, width, is_mul = True):
    cr_unit = 256//width
    mask = 2**width - 1

    z = 0
    for i in range(cr_unit):
        x_t = x & mask
        y_t = y & mask
        if is_mul:
            z_t = (x_t * y_t) & mask
        else:
            z_t = (x_t - y_t) & mask
        z |= z_t << i*width
        x >>= width
        y >>= width

    return z

def simd_sub(x, y, width):
    return simd_mulsub(x, y, width, False)

def simd_mul(x, y, width):
    return simd_mulsub(x, y, width, True)

def split_int(val, width, reverse = True):
    list_t = []
    mask = 2**width - 1
    for i in range(256//width):
        list_t.append(val& mask)
        val >>= width
    if reverse:
        list_t.reverse()

    return list_t

class PRNG_256:
    def __init__(self, key, n_prefix):
        """ Instanciate 256 bits output PRNG using two AES-CTRs.
        Args:
        key: Counter mode AES key.
        n_prefix: The number to specify unique PRNG. 0 <= n_prefix <= 127.
        """
        ctr = Counter.new(64, prefix = (n_prefix << 56).to_bytes(8, 'big'), little_endian=False, initial_value=0)
        self.PRNG_128_1 = AES.new(key=key, mode=AES.MODE_CTR , counter=ctr)
        ctr = Counter.new(64, prefix = ((128 + n_prefix) << 56).to_bytes(8, 'big'), little_endian=False, initial_value=0)
        self.PRNG_128_2 = AES.new(key=key, mode=AES.MODE_CTR , counter=ctr)

    def gen(self, out_integer = True):
        zero_txt = bytes.fromhex("00000000000000000000000000000000")
        rnd = self.PRNG_128_1.encrypt(zero_txt) + self.PRNG_128_2.encrypt(zero_txt)
        if out_integer:
            return int.from_bytes(rnd, 'big')
        else:
            return rnd
        
class CRG:

    stored_a0 = []
    stored_a1 = []
    stored_a  = []
    stored_b0 = []
    stored_b1 = []
    stored_b  = []
    stored_c0 = []
    stored_c1 = []
    stored_c  = []
    stored_a0_B = []
    stored_a1_B = []
    n_stored_cr = 0
    party = 0
    abe = None
    width = None
    cr_unit = None

    def __init__(self, seed = 0, party = 0, cr_mode = None):
        a0, a1, a, b0, b1, b, c0, c1, c = [0]*9

        assert cr_mode in ['b32', 'b64', 'b128', 'b256', 'a32', 'a64', 'a128', 'a256', 'e32', 'e64'], f'cr_type argument error: {cr_mode}'
        self.party = party

        self.abe = cr_mode[0]
        self.width = int(cr_mode[1:])
        self.cr_unit = 256//self.width

        random.seed(seed)
        key = random.randint(0, 2**128-1).to_bytes(16, 'big')

        self.PRNG256_0 = PRNG_256(key, 0)
        self.PRNG256_1 = PRNG_256(key, 1)
        self.PRNG256_2 = PRNG_256(key, 2)
        self.PRNG256_3 = PRNG_256(key, 3)
        self.PRNG256_4 = PRNG_256(key, 4)
            
    def get_cr(self):
        """
        Returns:
            Shares of a, b, c. And boolean share of c when e32/64.
        """
        if self.n_stored_cr < 1:
            self._gen_cr()
        
        self.n_stored_cr -= 1
        if self.party == 0:
            retval = self.stored_a0.pop(0), self.stored_b0.pop(0), self.stored_c0.pop(0)
            if self.abe == 'e':
                return retval + (self.stored_a0_B.pop(0),)
            else:
                return retval
        elif self.party == 1:
            retval = self.stored_a1.pop(0), self.stored_b1.pop(0), self.stored_c1.pop(0)
            if self.abe == 'e':
                return retval + (self.stored_a1_B.pop(0),)
            else:
                return retval

    def get_raw_val_for_test(self):
        """
        Returns:
            Raw values of a, b, c. This function must be excuted right after gen_cr() function.
        """

        retval = self.stored_a.pop(0), self.stored_b.pop(0), self.stored_c.pop(0)
        return retval

            
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
        print(hex(c))

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

    crg = CRG(0, party, cr_mode)
    crg._gen_cr()
    print(crg.get_raw_val_for_test())


    # print(f"{c0 = :064x}")
    # print(f"{c1 = :064x}")
    # print(f"{c  = :064x}")
    # print(f"{r0 = :064x}")
    # print(f"{r1 = :064x}")
    # print(f"{r  = :064x}")
    # print(f"{z0 = :064x}")
    # print(f"{z1 = :064x}")
    # print(f"{z  = :064x}")

    # print_shares()


if __name__ == "__main__":
    Fire(main)


