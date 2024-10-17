import unittest, random
from CR_HW import simd_subxor_hw, CSA_256, CSA_addsub_256, CRG_HW, simd_muland_hw, simd_add_hw, CSAMUL_256_32
from CR import simd_sub, split_int, CRG, simd_mul
import concurrent.futures

N = 10000000
JOBS = 8

class CRG_HW_Test(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.seed = 0
        cls.seed = random.randint(0,2**128-1)
        print(f'{cls.seed = }\n')

    # @classmethod
    # def tearDownClass(cls):
    #     print(f'Completed {N} * {JOBS} random test cases')

    def test_CSAMUL_256_32(self):
            for _ in range(N):
                a = random.randint(0, 2**256-1)
                b = random.randint(0, 2**32-1)
                exp = a*b & (2**256-1)
                ps, sc = CSAMUL_256_32(a, b)
                act = ps + (sc << 1) & (2**256-1)
                self.assertEqual(exp, act, f'{exp = :x}, {act = :x}')

    def test_simd_subxor_hw(self):
        for width in [32, 64, 128, 256]:
            for _ in range(N):
                a = random.randint(0, 2**256-1)
                b = random.randint(0, 2**256-1)
                exp = simd_sub(a, b, width)
                act = simd_subxor_hw(a, b, 'a', width)
                self.assertEqual(exp, act)

    def test_simd_muland_hw(self):
        for width in [32, 64, 128, 256]:
            for _ in range(N):
                a = random.randint(0, 2**256-1)
                b = random.randint(0, 2**256-1)
                exp = simd_mul(a, b, width)
                ps, sc = simd_muland_hw(a, b, 'a', width)
                act = simd_add_hw(ps, sc << 1, width)
                self.assertEqual(exp, act, f'{width = }, {exp - act = :x}')

    def test_CSA_256(self):
        for _ in range(N):
            ### Addition
            a = random.randint(0, 2**256-1)
            b = random.randint(0, 2**256-1)
            c = random.randint(0, 2**256-1)
            exp = a + b + c
            ps, sc = CSA_256(a, b, c)
            act = ps + 2*sc
            self.assertEqual(exp, act)

    def test_CSA_sub_256(self):
        for _ in range(N):
            ### Subtraction
            a = random.randint(0, 2**256-1)
            b = random.randint(0, 2**256-1)
            exp = (a - b) & 2**256-1
            ps, sc = CSA_addsub_256(a, b, 1, 256)
            act = (ps + 2*sc) & 2**256-1
            self.assertEqual(exp, act)

    def crg_mode_test_N(self, mode):
        crg = CRG(self.seed, 1, mode)
        crg_hw = CRG_HW(self.seed, 1, mode)

        for _ in range(N):
            exp = crg.get_cr()
            act = crg_hw.get_cr()
            self.assertEqual(exp, act)

    def test_a32(self):
        self.crg_mode_test_N('a32')

    def test_a64(self):
        self.crg_mode_test_N('a64')

    def test_a128(self):
         self.crg_mode_test_N('a128')

    def test_a256(self):
        self.crg_mode_test_N('a256')

    def test_b32(self):
        self.crg_mode_test_N('b32')

    def test_b64(self):
        self.crg_mode_test_N('b64')

    def test_b128(self):
         self.crg_mode_test_N('b128')

    def test_b256(self):
        self.crg_mode_test_N('b256')
