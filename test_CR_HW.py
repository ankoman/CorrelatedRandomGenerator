import unittest, random
from CR_HW import simd_add_hw, CSA_256, CSA_addsub_256, CRG_HW
from CR import simd_sub, split_int, CRG

N = 1000000

class CRG_HW_Test(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.seed = 0
        cls.seed = random.randint(0,2**128-1)
        print(f'{cls.seed = }\n')

    def test_simd_add_hw(self):
        for _ in range(N):
            a = random.randint(0, 2**256-1)
            b = random.randint(0, 2**256-1)
            exp = simd_sub(a, b, 64)
            act = simd_add_hw(a, b, 'a', 64)
            self.assertEqual(exp, act)

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
        crg = CRG(self.seed, 0, mode)
        crg_hw = CRG_HW(self.seed, 0, mode)

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
