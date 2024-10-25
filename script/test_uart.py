# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      sakamoto
#
# Created:     24/11/2017
# Copyright:   (c) sakamoto 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------
from serial import Serial
import random, time, subprocess
import Crypto.Cipher.AES as AES

len_din = 256//8
len_dout = 768//8

#######################################################################################
######################################Commands#########################################
#######################################################################################
WRITE = 0x10
READ = 0x20
SWRST = 0x30
RUN = 0x40

#######################################################################################
######################################Function#########################################
#######################################################################################
def sendCommand(command, addr, value, com):
    if addr == None:
        com.write([command])
    else:
        list_send_buf = []
        length = int(len(hex(value)[2:].rstrip("L")) / 2)
        for i in range(length + 1):
            list_send_buf.insert(0, (value >> i * 8) & 0xFF)
        for i in range(length, len_din):
            list_send_buf.insert(0, 0x00)
        list_send_buf.reverse()
        list_send_buf.insert(0, addr)
        list_send_buf.insert(0, command)
        com.write(list_send_buf)

def getResult(addr, com):
    com.write([READ, addr])
    str = com.read(len_dout).hex()
    return int(str, 16)

def main():
    random.seed(0)
    with Serial(port="COM4",baudrate=115200,bytesize=8, parity="N", stopbits=1, timeout=3, xonxoff=0, rtscts=0, writeTimeout=3, dsrdtr=None) as com:
            for loop in range(10):
                # print('\nLoop: %d' %loop)
                                
                key = 123
                aes0 = AES.new(key.to_bytes(16, 'big'), AES.MODE_ECB)
                aes1 = AES.new((key+1).to_bytes(16, 'big'), AES.MODE_ECB)
                aes2 = AES.new((key+2).to_bytes(16, 'big'), AES.MODE_ECB)

                print(f'{key = :x}')
                #入力
                sendCommand(WRITE, 0x00, key, com)

                #RUN
                sendCommand(RUN, None, None, com)

                #出力
                res = getResult(0x00, com)
                print(f'{res = :x}')

                ans = aes0.encrypt((0).to_bytes(16, 'big'))
                ans = int.from_bytes(ans, 'big')
                print(f'{ans = :x}')
                ans = aes1.encrypt((0).to_bytes(16, 'big'))
                ans = int.from_bytes(ans, 'big')
                print(f'{ans = :x}')
                ans = aes2.encrypt((0).to_bytes(16, 'big'))
                ans = int.from_bytes(ans, 'big')
                print(f'{ans = :x}')

if __name__ == '__main__':
    start = time.time()
    main()
    process_time = time.time() - start
    print(process_time)