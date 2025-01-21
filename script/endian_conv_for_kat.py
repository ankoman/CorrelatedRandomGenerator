def KAT_itzmeanjan(N):
    for idx in range(N):
        # print(f'#{idx} test vector...')
        start = idx * 8
        with open(r'./dat/ml_kem_512.kat', 'r') as f:
            tv = f.readlines()[start:start+7]

        tv_d = bytes.fromhex(tv[0].split('=')[1])
        tv_z = bytes.fromhex(tv[1].split('=')[1])
        tv_pk = bytes.fromhex(tv[2].split('=')[1])
        tv_sk = bytes.fromhex(tv[3].split('=')[1])
        tv_m = bytes.fromhex(tv[4].split('=')[1])
        tv_ct = bytes.fromhex(tv[5].split('=')[1])
        tv_ss = bytes.fromhex(tv[6].split('=')[1])

        list_tv = [tv_d, tv_z, tv_pk, tv_sk, tv_m, tv_ct, tv_ss]

        for tv in list_tv:
            for val in reversed(tv):
                print(f'{val:02x}', end='')
            print('_', end='')
        print()


if __name__ == "__main__":
    # KAT_ref(N)
    KAT_itzmeanjan(100)