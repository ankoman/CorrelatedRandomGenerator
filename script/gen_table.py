
HW = [0, 1, 1, 2, 1, 2, 2, 3]

def cbd3():
    for i in range(2**6):
        a = HW[i & 0x7]
        b = HW[(i >> 3) & 0x7]

        c = a - b
        c = 0x1000 + c
        c = c & 0x7

        print(f'6\'b{i:06b}: table_cbd3 = 3\'b{c:03b};')

if __name__ == "__main__":
    cbd3()


    #     always_comb begin : FSM_KEM_output
    #     case (current_state)
    #         KEYGEN:  en_kem_funcs_o = 3'b100;
    #         ENCAP:   en_kem_funcs_o = 3'b010;
    #         DECAP:   en_kem_funcs_o = 3'b001;
    #         default: en_kem_funcs_o = 3'b000; // default
    #     endcase
    # end