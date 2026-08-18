# VXRD Water-Bottom Autotile Pair Authority I — v1.06.58

## 目的
Random Hunt 四張水域 Hunt 原本自 v1.06.42 統一使用 A1 base `2096`。該 base 對應深水／不透明水家族，實機看不到水底。

本版依 RPG Maker VX 原生 A1 autotile kind 配置改成兩種「可見底」水：

- `2048`：A1 kind 0，冰山／浮冰裝飾左側的自然底水，給草地／土底／自然濕地。
- `2240`：A1 kind 4，冰山／浮冰裝飾右側的石質底水，給石路／岩地／冰雪等硬質地表。
- `2096`：A1 kind 1，舊深水家族，從 Random Hunt 正式水域配置撤銷。

VX A1 從 tile ID 2048 起算，每個 autotile kind 佔 48 個 shape ID，所以：

- kind 0 = 2048
- kind 1 = 2096
- kind 4 = 2240

## Hunt 對應

| Hunt | 地表語意 | 水 autotile base | 水底語意 |
|---|---|---:|---|
| H02 苔溪濕地 | 草／自然濕地 | 2048 | grass_bottom_clear |
| H07 霧澤泥地 | 岩／硬質泥地 | 2240 | stone_bottom_clear |
| H12 霜湖雪原 | 雪／冰硬質地表 | 2240 | stone_bottom_clear |
| H17 深潮冰灣 | 冰／硬質地表 | 2240 | stone_bottom_clear |

## 不變 Authority
- 水域仍只在 H02/H07/H12/H17。
- rectangle-only；不新增河流／橋。
- 水仍為不可步行 A1 water region。
- A2 shoreline border 仍沿用 v1.06.42 Native Autotile Authority。
- 不改 Map090 / Map091 結構。
- 不改 Landmark / Route Safety / Loading Overlay。
- automatic B/C/D/E scatter/stamping 仍禁止。
- 不動 Battle AI / Damage / Attack Speed / Focus-C2 / Reward / Progression。

## Windows/RMVX 驗收
只需優先看 H02 與 H07；H12/H17 再做冰雪相容性快速確認。

1. H02 水面應能看見自然／草土感水底，不再是舊深水色塊。
2. H07 水面應能看見較石質的水底。
3. H12/H17 應使用硬質底版本，不應透出明顯草地感。
4. 水仍正常動畫與 autotile 拼接。
5. 岸線不能破格、出現黑角或 tile fragment。
6. 水仍不可步行。
7. Loading Overlay、Landmark、Route Safety 無回歸。
