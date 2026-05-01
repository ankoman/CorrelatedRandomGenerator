import numpy as np
import Crypto.Cipher.AES as AES
from Crypto.Util import Counter

N = 10
KEY = 0x1234567890abcdef1234567890abcdef

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

def ADD64(din1, din2, sub=False):
    dout = []
    MASK = 0xffffffffffffffff

    for i in range(len(din1)):
        a = int(din1[i])
        b = int(din2[i])

        if sub:
            dout.append((a - b) & MASK)
        else:
            dout.append((a + b) & MASK)

    return dout

class Shuffle:
    def __init__(self, seed = 0, party = 0):
        self.seed = seed
        self.party = party
        self.rng = np.random.default_rng(seed)
        self.AES1 = PRNG_128(key=seed.to_bytes(16, 'big'), n_prefix=0)
        self.AES2 = PRNG_128(key=seed.to_bytes(16, 'big'), n_prefix=1)
        self.M1, self.M2, self.M3, self.M4, self.M5, self.M6 = [np.arange(N) for _ in range(6)]


    def RPG(self, n):
        return self.rng.permutation(n)
    
    def double_share(self, n):
        ### Step1
        self.M1 = self.RPG(n) # r
        save_r = self.M1.copy()
        self.M2 = self.RPG(n) # r1
        self.M3 = self.RPG(n) # r1'

        if self.party == 1:
            ### Step 2
            INV(self.M5, self.M2) # r1^-1
            INV(self.M6, self.M3) # r1'^-1

            ### Step 3
            PERM(self.M2, self.M1, self.M6) # M2 = r*r1'^-1=r2
            PERM(self.M3, self.M5, self.M1) # M3 = r1^-1*r=r2'

        return self.M2, self.M3, save_r


    def double_share_radix(self, n):
        ### Step1
        self.M1 = self.RPG(n) # r
        save_r = self.M1.copy()
        self.M2 = self.RPG(n) # r1
        self.M3 = self.RPG(n) # r1'

        if self.party == 1:
            ### Step 2
            PERM(self.M4, self.M1, 1) # r^-1
            PERM(self.M5, self.M2, 1) # r1^-1
            PERM(self.M6, self.M3, 1) # r1'^-1

            ### Step 3
            self.M7 = self.M4.copy()  # M7 = r^-1
            PERM(self.M6, self.M1, 0) # M6 = r*r1'^-1=r2
            PERM(self.M1, self.M5, 0) # M1 = r1^-1*r=r2'

        ### Chech if r = r1r2' = r2r1'
        # PERM(M1, M2, 0) # r
        # PERM(M3, M5, 0) # r
        # print(M1)
        # print(M3)

        if self.party == 0:
            return self.M2, self.M3, save_r
        else:
            return self.M6, self.M1, save_r
                
    def gen_mask(self, n):
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
            aip.append(perm_in1[self.M3[i]]) # 

        if self.party == 0:
            aip = ADD64(aip, c)    # a0' = a1r1' + c
            return a0, aip
        else:
            aip = ADD64(aip, c, 1)    # a1' = a0r2' - c
            return a1, aip
        
    def LGA_prep(self, n):
        ri, rip, r = self.double_share(n)
        ai, aip = self.gen_mask(n)
        return ri, rip, ai, aip, r

    def radix_prep(self, n, k):
        ri, rip, r = self.double_share(n)
        for i in range(k):
            ai, aip = self.gen_mask(n)
            ri, rip, r = self.double_share_radix(n)

def main():
    P0 = Shuffle(seed=KEY, party=0)
    P1 = Shuffle(seed=KEY, party=1)

    r0, r0p, a0, a0p, r = P0.LGA_prep(N)
    r1, r1p, a1, a1p, r = P1.LGA_prep(N)

    ### LGA part
    v0 = ADD64(r0, a0)
    v1 = ADD64(r1, a1)

    y0 = []
    for i in range(N):
        y0.append(v1[r0p[i]]) # a1r0'
    y0 = ADD64(y0, a0p, 1) # y0

    y1 = []
    for i in range(N):
        y1.append(v0[r1p[i]]) # a1r2'
    y1 = ADD64(y1, a1p, 1) # y1

    y = ADD64(y0, y1)
    print(f'r = {r}')
    print(f'2r = {y}')

    if (r == np.array(y)//2).all():
        print("Success!")
    else:    
        print("Failure...")

if __name__ == "__main__":
    main()