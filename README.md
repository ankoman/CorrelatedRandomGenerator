
- verible-ls option: `--rules=-no-trailing-spaces,-package-filename,-parameter-name-style,+line-length=length:150,-no-tabs,-module-port,-module-filename`

- Kyber NTT repositoty `https://github.com/vivadomacnchen/kyberVerilog.git`

- Keccak source `https://github.com/Chair-for-Security-Engineering/Low-Latency_Keccak`

- Keccak reset下げで動作するので微妙
- Keccak reset かけてない
- SampleCBD後の変数に12bitは不要。NTTの多くは12bitフル精度いらない（片入力は3bitとかでいい）