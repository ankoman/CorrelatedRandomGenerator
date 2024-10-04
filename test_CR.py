import unittest, random
from CR import CRG

N = 1000000

class CRGTest(unittest.TestCase):

    seed = 0
    prev_val = 0

    @classmethod
    def setUpClass(cls):
        cls.seed = 0
        cls.seed = random.randint(0,2**128-1)
        print(f'{cls.seed = }\n')

    def bool_unshare(self, a0, a1, b0, b1, c0, c1):
        a = a0 ^ a1
        b = b0 ^ b1
        c = c0 ^ c1

        return a, b, c

    def arith_unshare(self, a0, a1, b0, b1, c0, c1, width):
        mask = 2**width - 1
        a = (a0 + a1) & mask
        b = (b0 + b1) & mask
        c = (c0 + c1) & mask

        return a, b, c  
    
    def bool_test(self, crg_0, crg_1):
        a0, b0, c0 = crg_0.get_cr()
        a1, b1, c1 = crg_1.get_cr()
        exp_a, exp_b, exp_c = crg_0.get_raw_val_for_test()

        act_a, act_b, act_c = self.bool_unshare(a0, a1, b0, b1, c0, c1)

        self.assertEqual(exp_a, act_a)
        self.assertEqual(exp_b, act_b)
        self.assertEqual(exp_c, act_c)

        self.assertEqual(exp_c, exp_a & exp_b)
        self.assertEqual(exp_c, act_a & act_b)

        self.assertNotEqual(self.prev_val, a0)
        self.prev_val = a0

    def arith_test(self, crg_0, crg_1, width):
        mask = 2**width - 1
        a0, b0, c0 = crg_0.get_cr()
        a1, b1, c1 = crg_1.get_cr()
        exp_a, exp_b, exp_c = crg_0.get_raw_val_for_test()

        act_a, act_b, act_c = self.arith_unshare(a0, a1, b0, b1, c0, c1, width)

        self.assertEqual(exp_a, act_a)
        self.assertEqual(exp_b, act_b)
        self.assertEqual(exp_c, act_c)

        self.assertEqual(exp_c, (exp_a * exp_b) & mask)
        self.assertEqual(exp_c, (act_a * act_b) & mask)

        self.assertNotEqual(self.prev_val, a0)
        self.prev_val = a0

    def ext_test(self, crg_0, crg_1, width):
        ### c = a, r = b, z = c
        mask = 2**width - 1
        a0, b0, c0, a0_B = crg_0.get_cr()
        a1, b1, c1, a1_B = crg_1.get_cr()
        exp_a, exp_b, exp_c = crg_0.get_raw_val_for_test()

        act_a, act_b, act_c = self.arith_unshare(a0, a1, b0, b1, c0, c1, width)
        act_a_B = a0_B ^ a1_B

        self.assertEqual(exp_a, act_a)
        self.assertEqual(exp_a, act_a_B)        
        self.assertEqual(exp_b, act_b)
        self.assertEqual(exp_c, act_c)

        self.assertEqual(exp_c, (exp_a * exp_b) & mask)
        self.assertEqual(exp_c, (act_a * act_b) & mask)

        self.assertNotEqual(self.prev_val, a0)
        self.prev_val = a0

    def test_b32(self):
        crg_0 = CRG(self.seed, 0, 'b32')
        crg_1 = CRG(self.seed, 1, 'b32')

        for _ in range(N):
            self. bool_test(crg_0, crg_1)

    def test_a32(self):
        crg_0 = CRG(self.seed, 0, 'a32')
        crg_1 = CRG(self.seed, 1, 'a32')

        for _ in range(N):
            self. arith_test(crg_0, crg_1, 32)

    def test_b64(self):
        crg_0 = CRG(self.seed, 0, 'b64')
        crg_1 = CRG(self.seed, 1, 'b64')

        for _ in range(N):
            self. bool_test(crg_0, crg_1)

    def test_a64(self):
        crg_0 = CRG(self.seed, 0, 'a64')
        crg_1 = CRG(self.seed, 1, 'a64')

        for _ in range(N):
            self. arith_test(crg_0, crg_1, 64)

    def test_b128(self):
        crg_0 = CRG(self.seed, 0, 'b128')
        crg_1 = CRG(self.seed, 1, 'b128')

        for _ in range(N):
            self. bool_test(crg_0, crg_1)

    def test_a128(self):
        crg_0 = CRG(self.seed, 0, 'a128')
        crg_1 = CRG(self.seed, 1, 'a128')

        for _ in range(N):
            self. arith_test(crg_0, crg_1, 128)

    def test_b256(self):
        crg_0 = CRG(self.seed, 0, 'b256')
        crg_1 = CRG(self.seed, 1, 'b256')

        for _ in range(N):
            self. bool_test(crg_0, crg_1)

    def test_a256(self):
        crg_0 = CRG(self.seed, 0, 'a256')
        crg_1 = CRG(self.seed, 1, 'a256')

        for _ in range(N):
            self. arith_test(crg_0, crg_1, 256)

    def test_e32(self):
        crg_0 = CRG(self.seed, 0, 'e32')
        crg_1 = CRG(self.seed, 1, 'e32')

        for i in range(N):
            self. ext_test(crg_0, crg_1, 32)

    def test_e64(self):
        crg_0 = CRG(self.seed, 0, 'e64')
        crg_1 = CRG(self.seed, 1, 'e64')

        for _ in range(N):
            self. ext_test(crg_0, crg_1, 64)