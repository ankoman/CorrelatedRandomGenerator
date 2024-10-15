import unittest, random
from CR_HW import TreeAdder, CSA_256, CSA_addsub_256
from CR import simd_sub, split_int

N = 1000000

class CRG_HW_Test(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        random.seed(0)

    def test_TreeAdder(self):
        for _ in range(N):
            a = random.randint(0, 2**256-1)
            b = random.randint(0, 2**256-1)
            exp = simd_sub(a, b, 256)
            act = TreeAdder(a, b, 'a', 256)
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
            ### Addition
            a = random.randint(0, 2**256-1)
            b = random.randint(0, 2**256-1)
            exp = (a - b) & 2**256-1
            ps, sc = CSA_addsub_256(a, b, 1)
            act = (ps + 2*sc) & 2**256-1
            self.assertEqual(exp, act)