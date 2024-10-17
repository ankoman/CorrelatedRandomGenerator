# Usage
```
python3 -m unittest

# 未実施部分
- PRNG256をちゃんとしたやつに
- Adderの最適化(1bitしか入力したい際は、最適化できるかも)
- ~~MUL_256_32のCSA化~~
- 上位桁から出力している部分
- ビットスライス実装
- 128bitデータパス
- extended用のラウンド実装PRNG
- c1減算をmulandへ取り込み
- extended実装
