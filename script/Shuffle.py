import numpy as np
import Crypto.Cipher.AES as AES
from Crypto.Util import Counter
from typing import NamedTuple

N = 10
KEY = 0x1234567890abcdef1234567890abcdef

class d_LGA_prep(NamedTuple):
    r: np.ndarray
    rp: np.ndarray
    a: np.ndarray
    ap: np.ndarray
    r_raw: np.ndarray   ### Only for checking correctness, not used in actual protocol

class PRNG_128:
    def __init__(self, key, n_prefix):
        """ Instanciate 128 bits output PRNG using two AES-CTRs.
        Args:
        key: Counter mode AES key.
        n_prefix: The number to specify unique PRNG. 0 <= n_prefix <= 127.
        """
        ctr = Counter.new(64, prefix = (n_prefix << 56).to_bytes(8, 'big'), little_endian=False, initial_value=0)
        self.PRNG_128 = AES.new(key=key, mode=AES.MODE_CTR , counter=ctr)

    def gen(self, mode = 1):
        zero_txt = bytes.fromhex("00000000000000000000000000000000")
        rnd = self.PRNG_128.encrypt(zero_txt)
        rnd = int.from_bytes(rnd, 'big')
        if mode == 0:
            ### 32 bit mode
            return rnd >> 96, rnd >> 64 & 0xffffffff, rnd >> 32 & 0xffffffff, rnd & 0xffffffff
        else:
            ### 64 bit mode
            return (rnd >> 64) & 0xffffffffffffffff, rnd & 0xffffffffffffffff

def PERM(dout, x, Pi):
    ### dout = x*Pi = Pi(x)
    for i in range(len(dout)):
        dout[i] = x[Pi[i]]

def INV(dout, din):
    ### dout = din^-1
    for i in range(len(dout)):
        dout[din[i]] = i

def general_add(din1, din2, mode = 'a64', sub=False):
    dout = []
    MASK = 0xffffffffffffffff

    for i in range(len(din1)):
        a = int(din1[i])
        b = int(din2[i])

        if mode == 'a64':
            if sub:
                dout.append((a - b) & MASK)
            else:
                dout.append((a + b) & MASK)
        elif mode == 'b64' or mode == 'b32':
            dout.append(a ^ b)
        else:
            raise NotImplementedError('Only a64 and b64 modes are implemented')

    return dout

class Shuffle:
    def __init__(self, seed = 0, party = 0):
        self.seed = seed
        self.party = party
        self.rng = np.random.default_rng(seed)
        self.AES1 = PRNG_128(key=seed.to_bytes(16, 'big'), n_prefix=0)
        self.AES2 = PRNG_128(key=seed.to_bytes(16, 'big'), n_prefix=1)
        self.M1, self.M2, self.M3, self.M4, self.M5, self.M6, self.M7 = [np.arange(N) for _ in range(7)]


    def RPG(self, n):
        return self.rng.permutation(n)
    
    def double_share(self, n, M1_RPG = True):
        ### Step1
        if M1_RPG == True:
            self.M1 = self.RPG(n) # r
        save_r = self.M1.copy()
        self.M2 = self.RPG(n) # r1
        self.M3 = self.RPG(n) # r1'
        self.M6 = self.M4.copy() # r-^-1

        ### Step 2
        if self.party == 1:
            INV(self.M4, self.M2) # r1^-1
            INV(self.M5, self.M3) # r1'^-1

        ### Step 3
        if self.party == 1:
            PERM(self.M2, self.M1, self.M5) # M2 = r*r1'^-1=r2
            PERM(self.M3, self.M4, self.M1) # M3 = r1^-1*r=r2'

        ### Step 3-2
        self.M7 = self.M3.copy()
        INV(self.M4, self.M1) # r^-1
        PERM(self.M1, self.M6, self.M1)

        return self.M2, self.M3, save_r

                
    def gen_mask(self, n, mode):
        ### Step 4-2
        a0 = []
        a1 = []
        c = []
        for i in range(n):
            temp = self.AES1.gen()
            a0.append(temp[0]) # a0
            a1.append(temp[1]) # a1
            c.append(self.AES2.gen()[0]) # c

        perm_in1 = a1 if self.party == 0 else a0
        aip = []
        for i in range(n):
            aip.append(perm_in1[self.M7[i]]) # 

        ### 32 mode未実装
        if self.party == 0:
            aip = general_add(aip, c, mode=mode)    # a0' = a1r1' + c
            return a0, aip
        else:
            aip = general_add(aip, c, mode=mode, sub=True)    # a1' = a0r2' - c
            return a1, aip


    def LGA_prep(self, rows, mode = 'a64', M1_RPG = True):
        ri, rip, r = self.double_share(rows, M1_RPG)
        ai, aip = self.gen_mask(rows, mode)
        dout = d_LGA_prep(r = ri, rp = rip, a = ai, ap = aip, r_raw = r)
        return dout

    def radix_prep(self, rows, digits, mode = 0):
        '''
        mode = 0: 32, mode = 1: 64
        '''

        mode_a = 'a64' if mode else 'a32'
        mode_b = 'b64' if mode else 'b32'
        self.M6 = np.arange(rows)  ### Init as identity
        dout = self.LGA_prep(rows, mode_b)    ### <pi_2>
        ai_2, aip_2 = self.gen_mask(rows, mode_a)     ### Arithmetic for pi_2
        list_dout = [dout]
        
        for i in range(digits-1):
            dout = self.LGA_prep(rows, mode_b)    ### <pi_k>
            list_dout.append(dout)

            if i == digits-2:
                self.M1 = np.arange(rows)  ### Init as identity
                dout = self.LGA_prep(rows, mode_a)    ### <pi_{n-1}^{-1}*pi_n>
            else:
                dout = self.LGA_prep(rows, mode_a, False)    ### <pi_{k-1}^{-1}*pi_k>
            list_dout.append(dout)

        dout = self.LGA_prep(rows, mode_a, False)    ### <pi_k^-1>
        list_dout.append(dout)
        list_dout.append((ai_2, aip_2))    ### Arithmetic for pi_2

        return list_dout

        
def check_LGA_correctness(P0, P1, mode='a64'):
        ### LGA part
        v0 = general_add(P0.r, P0.a, mode=mode) # a1r0
        v1 = general_add(P1.r, P1.a, mode=mode) # a1r2

        y0 = []
        for i in range(N):
            y0.append(v1[P0.rp[i]]) # a1r0'
        y0 = general_add(y0, P0.ap, mode=mode, sub=True)

        y1 = []
        for i in range(N):
            y1.append(v0[P1.rp[i]]) # a1r2'
        y1 = general_add(y1, P1.ap, mode=mode, sub=True)

        y = general_add(y0, y1, mode=mode)

        print(f'r = {P0.r_raw}')
        print(f'y = {y}')

        if mode == 'a64':
            return (P0.r_raw == np.array(y)//2).all()
        elif mode == 'b64':
            return not any(y)

def test_LGA():
    P0 = Shuffle(seed=KEY, party=0)
    P1 = Shuffle(seed=KEY, party=1)

    for _ in range(1):
        mode = 'a64'
        shares_P0 = P0.LGA_prep(N, mode=mode)
        shares_P1 = P1.LGA_prep(N, mode=mode)
        assert check_LGA_correctness(shares_P0, shares_P1, mode=mode), 'LGA correctness error'

        mode = 'b64'
        shares_P0 = P0.LGA_prep(N, mode=mode)
        shares_P1 = P1.LGA_prep(N, mode=mode)
        assert check_LGA_correctness(shares_P0, shares_P1, mode=mode), 'LGA correctness error'

def test_radix_prep():
    P0 = Shuffle(seed=KEY, party=0)
    P1 = Shuffle(seed=KEY, party=1)

    for _ in range(1):
        shares_P0 = P0.radix_prep(N, 2, 1)
        shares_P1 = P1.radix_prep(N, 2, 1)
        assert check_LGA_correctness(shares_P0, shares_P1, mode='a64'), 'LGA correctness error'


if __name__ == "__main__":
    test_LGA()
