from CR_HW import adder_tree
from CR import split_int
import random

N_TV = 100000

def get_tab_carrychain(width):
    is64, is128, is256 = 0,0,0
    if width == 64:
        is64, is128, is256 = 1,0,0
    elif width == 128:
        is64, is128, is256 = 1,1,0
    elif width == 256:
        is64, is128, is256 = 1,1,1

    return [is64, is128, is64, is256, is64, is128, is64]

def main():

    random.seed(0)
    list_tv = []
    for i in range(N_TV):
        ### tv_adder_tree
        ps = random.randint(0, 2**256 - 1)
        sc = random.randint(0, 2**256 - 1)
        list_ps_32 = split_int(ps, 32, False)
        list_sc_32 = split_int(sc, 32, False)

        ans_32 = adder_tree(list_ps_32, list_sc_32, get_tab_carrychain(32))
        ans_64 = adder_tree(list_ps_32, list_sc_32, get_tab_carrychain(64))
        ans_128 = adder_tree(list_ps_32, list_sc_32, get_tab_carrychain(128))
        ans_256 = adder_tree(list_ps_32, list_sc_32, get_tab_carrychain(256))

        tv = f'{ps:064x}_{sc:064x}_{ans_32:064x}_{ans_64:064x}_{ans_128:064x}_{ans_256:064x}\n'
        list_tv.append(tv)

    with open('./dat.txt', 'w') as f:
        f.writelines(list_tv)


if __name__ == "__main__":
    main()