
- verible-ls option: `--rules=-no-trailing-spaces,-package-filename,-parameter-name-style,+line-length=length:150,-no-tabs,-module-port,-module-filename`

- Kyber NTT repositoty `https://github.com/acmert/kyber-polmul-hw`

- Keccak source `https://github.com/Chair-for-Security-Engineering/Low-Latency_Keccak`

# TBD
- Keccak reset下げで動作するので微妙
- Keccak reset かけてない
- SampleCBD後の変数に12bitは不要。NTTの多くは12bitフル精度いらない（片入力は3bitとかでいい）
- 各モジュールでレジスタに保存した後さらにレジスタに入れているので無駄
- NTTのロード部分は最適化の余地あり
- negative/positive reset混載