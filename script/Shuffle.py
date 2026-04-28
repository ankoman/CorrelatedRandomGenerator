import numpy as np
import Crypto.Cipher.AES as AES
from Crypto.Util import Counter

N = 10
PARTY_I = 0
KEY = "1234567890abcdef1234567890abcdef"

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
        
def RPG(x: int):
    return np.random.permutation(x)

def PERM(dout, din, mode: int):
    if mode == 0:
        ### Permutation mode: dout <= din*dout
        for i in range(N):
            dout[i] = din[dout[i]]
    elif mode == 1:
        ### Inverse mode
        for i in range(N):
            dout[din[i]] = i
    else:
        raise ValueError("Invalid mode")

def ADD64(din1, din2, sub=False):
    dout = []
    MASK = 0xffffffffffffffff

    for i in range(N):
        a = int(din1[i])
        b = int(din2[i])

        if sub:
            dout.append((a - b) & MASK)
        else:
            dout.append((a + b) & MASK)

    return dout

### Init
M1, M2, M3, M4, M5 = [np.arange(N) for _ in range(5)]
AES1 = PRNG_128(key = bytes.fromhex(KEY), n_prefix = 0)
AES2 = PRNG_128(key = bytes.fromhex(KEY), n_prefix = 1)

### Step1
M1 = RPG(N) # r
save_M1 = M1.copy()
print(f'r = {M1}')
M2 = RPG(N) # r1
M3 = RPG(N) # r1'

### Step 2
PERM(M4, M2, 1) # r1^-1
PERM(M5, M3, 1) # r1'^-1

### Step 3
PERM(M5, M1, 0) # M5 = r*r1'^-1=r2
PERM(M1, M4, 0) # M4 = r1^-1*r=r2'

### Chech if r = r1r2' = r2r1'
# PERM(M1, M2, 0) # r
# PERM(M3, M5, 0) # r
# print(M1)
# print(M3)

### Step 4-2
temp_a1 = []
temp_a2 = []
temp_c = []
for i in range(N):
    temp = AES1.gen()
    temp_a1.append(temp[0]) # a1
    temp_a2.append(temp[1]) # a2
    temp = AES2.gen()
    temp_c.append(temp[0]) # c

temp_a1p = []
for i in range(N):
    temp_a1p.append(temp_a2[M3[i]]) # a2r1'
temp_a1p = ADD64(temp_a1p, temp_c) # a1' = a2r1' + c

temp_a2p = []
for i in range(N):
    temp_a2p.append(temp_a1[M1[i]]) # a1r2'
temp_a2p = ADD64(temp_a2p, temp_c, 1) # a2' = a1r2' - c

v1 = ADD64(M2, temp_a1)
v2 = ADD64(M5, temp_a2)

y1 = []
for i in range(N):
    y1.append(v2[M3[i]]) # a2r1'
y1 = ADD64(y1, temp_a1p, 1) # y1

y2 = []
for i in range(N):
    y2.append(v1[M1[i]]) # a1r2'
y2 = ADD64(y2, temp_a2p, 1) # y2

y = ADD64(y1, y2)
print(f'2r = {y}')

if (save_M1 == np.array(y)//2).all():
    print("Success!")
else:    
    print("Failure...")