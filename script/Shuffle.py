import numpy as np
import Crypto.Cipher.AES as AES
from Crypto.Util import Counter
from dataclasses import dataclass
N = 10
KEY = 0x1234567890abcdef1234567890abcdef

@dataclass
class d_LGA_prep:
    r: np.ndarray
    rp: np.ndarray
    a: np.ndarray
    ap: np.ndarray
    r_raw: np.ndarray   ### Only for checking correctness, not used in actual protocol

# class PRNG_128:
#     def __init__(self, key, n_prefix):
#         """ Instanciate 128 bits output PRNG using two AES-CTRs.
#         Args:
#         key: Counter mode AES key.
#         n_prefix: The number to specify unique PRNG. 0 <= n_prefix <= 127.
#         """
#         ctr = Counter.new(64, prefix = (n_prefix << 56).to_bytes(8, 'big'), little_endian=False, initial_value=0)
#         self.PRNG_128 = AES.new(key=key, mode=AES.MODE_CTR , counter=ctr)

#     def gen(self, mode = 1):
#         zero_txt = bytes.fromhex("00000000000000000000000000000000")
#         rnd = self.PRNG_128.encrypt(zero_txt)
#         rnd = int.from_bytes(rnd, 'big')
#         if mode == 0:
#             ### 32 bit mode
#             return rnd >> 96, rnd >> 64 & 0xffffffff, rnd >> 32 & 0xffffffff, rnd & 0xffffffff
#         else:
#             ### 64 bit mode
#             return (rnd >> 64) & 0xffffffffffffffff, rnd & 0xffffffffffffffff

class PRNG_128:
    def __init__(self, key, prefix):
        self.prefix = prefix
        self.PRNG_128 = AES.new(key=key, mode=AES.MODE_ECB)

    def gen(self, cnt, mode = 1):
        cnt = int(cnt)
        din = (self.prefix << 56).to_bytes(8, 'big') + cnt.to_bytes(8, 'big')
        rnd = self.PRNG_128.encrypt(din)
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

def _PERM(x, Pi):
    ### dout = x*Pi = Pi(x)
    dout = []
    for i in range(len(dout)):
        dout.append(x[Pi[i]])
    return dout

def INV(dout, din):
    ### dout = din^-1
    for i in range(len(dout)):
        dout[din[i]] = i

def general_add(din1, din2, mode = 'a64', sub=False):
    MASK = 0xffffffffffffffff
    a = int(din1)
    b = int(din2)

    if mode == 'a64':
        if sub:
            dout = (a - b) & MASK
        else:
            dout = (a + b) & MASK
    elif mode == 'b64' or mode == 'b32':
        dout = a ^ b
    else:
        raise NotImplementedError('Only a64 and b64 modes are implemented')

    return dout

def general_add_list(din1, din2, mode = 'a64', sub=False):
    dout = []
    for i in range(len(din1)):
        dout.append(general_add(din1[i], din2[i], mode=mode, sub=sub))
    return dout

class Shuffle:
    def __init__(self, seed = 0, party = 0):
        self.party = party
        self.rng = np.random.default_rng(seed)
        self.cnt = 0
        self.AES1 = PRNG_128(key=seed.to_bytes(16, 'big'), prefix=0)
        self.AES2 = PRNG_128(key=seed.to_bytes(16, 'big'), prefix=1)
        self.PERM_AES = PRNG_128(key=seed.to_bytes(16, 'big'), prefix=0)
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

        ### Step 2
        if self.party == 1:
            INV(self.M4, self.M2) # r1^-1
            INV(self.M5, self.M3) # r1'^-1

        ### Step 3
        if self.party == 1:
            PERM(self.M2, self.M1, self.M5) # M2 = r*r1'^-1=r2
            PERM(self.M3, self.M4, self.M1) # M3 = r1^-1*r=r2'
        self.M5 = self.M6.copy()

        return save_r
    
    def step_3_2(self, M1_RPG = True, lastloop = False):
        ### Step 3-2
        self.M7 = self.M3.copy()
        if M1_RPG == True:
            INV(self.M6, self.M1) # r^-1
        if lastloop:
            self.M1 = self.M5.copy()
        else:
            PERM(self.M1, self.M5, self.M1)

        return self.M2, self.M3

    def gen_mask(self, n, mode):
        ### Step 4, 5

        list_out_ai = []
        list_out_aip = []
        offset = self.cnt
        for i in range(n):
            ai = self.AES1.gen(self.cnt)[self.party]
            _aip = self.PERM_AES.gen(offset + self.M7[i])[1 - self.party]
            c = self.AES2.gen(self.cnt)[0]
            ### 32 mode未実装
            aip = general_add(_aip, c, mode = mode, sub = self.party == 1)    # aip = _aip +- c
            self.cnt += 1
            
            list_out_ai.append(ai)
            list_out_aip.append(aip)

        return list_out_ai, list_out_aip


    def LGA_prep(self, rows, mode = 'a64', M1_RPG = True, lastloop = False):
        r = self.double_share(rows, M1_RPG)
        ri, rip = self.step_3_2(M1_RPG, lastloop)
        ai, aip = self.gen_mask(rows, mode)
        dout = d_LGA_prep(r = ri, rp = rip, a = ai, ap = aip, r_raw = r)
        return dout

    def radix_prep(self, rows, bitlen, mode = 0):
        '''
        mode = 0: 32, mode = 1: 64
        digits > 1
        '''

        mode_a = 'a64' if mode else 'a32'
        mode_b = 'b64' if mode else 'b32'
        self.M6 = np.arange(rows)  ### Init as identity
        dout = self.LGA_prep(rows, mode_b)    ### <pi_2>
        ai_2, aip_2 = self.gen_mask(rows, mode_a)     ### Arithmetic for pi_2
        list_dout = [dout, (ai_2, aip_2)]
        
        for i in range(bitlen-2):
            dout = self.LGA_prep(rows, mode_b)    ### <pi_i>
            list_dout.append(dout)

            lastloop = (i == bitlen-3)
            dout = self.LGA_prep(rows, mode_a, False, lastloop)    ### <pi_{i-1}^{-1}*pi_i>
            list_dout.append(dout)

        dout = self.LGA_prep(rows, mode_a, False)    ### <pi_l^-1>
        list_dout.append(dout)

        return list_dout

        
def check_LGA_correctness(P0, P1, mode='a64'):
        ### LGA part
        v0 = general_add_list(P0.r, P0.a, mode=mode) # a1r0
        #v1 = general_add_list(P1.r, P1.a, mode=mode) # a1r2
        v1 = P1.a

        y0 = []
        for i in range(N):
            y0.append(v1[P0.rp[i]]) # a1r0'
        y0 = general_add_list(y0, P0.ap, mode=mode, sub=True)

        y1 = []
        for i in range(N):
            y1.append(v0[P1.rp[i]]) # a1r2'
        y1 = general_add_list(y1, P1.ap, mode=mode, sub=True)

        y = general_add_list(y0, y1, mode=mode)

        print(f'r = {P0.r_raw} ', end='')
        print(f'y = {y}')

        # if mode == 'a64':
        #     return (P0.r_raw == np.array(y)//2).all()
        # elif mode == 'b64':
        #     return not any(y)
        return (P0.r_raw == y).all()

def check_radix_prep_correctness(P0, P1, bitlen):
        pi_tmp = np.arange(N)
        pi_inv = np.arange(N)

        ### Check for pi_2
        pi_2_P0 = P0.pop(0)
        pi_2_P1 = P1.pop(0)
        assert check_LGA_correctness(pi_2_P0, pi_2_P1, mode='b64'), 'pi_2 check error Bool'
        pi_2_P0.a, pi_2_P0.ap = P0.pop(0)
        pi_2_P1.a, pi_2_P1.ap = P1.pop(0)
        assert check_LGA_correctness(pi_2_P0, pi_2_P1, mode='a64'), 'pi_2 check error Arithmetic'
        pi_0 = pi_2_P0.r_raw
        print(pi_0)

        ### Check for pi_i
        for i in range(bitlen-2):
            pi_i_P0 = P0.pop(0)
            pi_i_P1 = P1.pop(0)
            assert check_LGA_correctness(pi_i_P0, pi_i_P1, mode='b64'), 'pi_i check error Bool'
            pi_1 = pi_i_P0.r_raw
            print(f'pi_{i+3} = {pi_1}')
            pi_i_P0 = P0.pop(0)
            pi_i_P1 = P1.pop(0)
            assert check_LGA_correctness(pi_i_P0, pi_i_P1, mode='a64'), 'pi_{i-1}^{-1}*pi_i check error Arithmetic'

            INV(pi_inv, pi_0)
            print(f'pi_{i+2}^-1 = {pi_inv}')
            PERM(pi_tmp, pi_inv, pi_1)
            print(pi_tmp, end=' ')
            print(pi_i_P0.r_raw)

            assert (pi_tmp == pi_i_P0.r_raw).all(), 'pi_{i-1}^{-1}*pi_i check error Permutation'
            pi_0 = pi_1

        ### Check for pi_ell^-1
        pi_ell_P0 = P0.pop(0)
        pi_ell_P1 = P1.pop(0)
        assert check_LGA_correctness(pi_ell_P0, pi_ell_P1, mode='a64'), 'pi_ell^-1 check error Arithmetic'
        INV(pi_inv, pi_1)
        assert (pi_inv == pi_ell_P0.r_raw).all(), 'pi_ell^-1 check error Inversion'


def test_LGA():
    P0 = Shuffle(seed=KEY, party=0)
    P1 = Shuffle(seed=KEY, party=1)

    for _ in range(10):
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

    bitlen = 10
    for _ in range(10):
        shares_P0 = P0.radix_prep(N, bitlen, 1)
        shares_P1 = P1.radix_prep(N, bitlen, 1)
        check_radix_prep_correctness(shares_P0, shares_P1, bitlen)


if __name__ == "__main__":
    test_LGA()
    test_radix_prep()
