# env/ — 製作環境重建

Codex Cloud 任務沒有 root，且已發布環境的快照不一定可靠。這個目錄把「建環境的步驟」放進 repo，讓它可以重現。

## 用法

```sh
sh env/setup.sh        # 建置（已完成會自動略過；FORCE=1 強制重建）
. /workspace/tools/env.sh
sh env/verify.sh       # 以 480p15 渲染兩個驗收場景
```

## 內容

- `setup.sh`：micromamba（conda-forge）建立 `manim312`（Python 3.12、manim 0.22.1、ffmpeg），並以 `apt-get download` 加 `dpkg-deb -x` 取得 `dvisvgm`，最後產生 `/workspace/tools/env.sh`。
- `verify.sh`：渲染 `tests/text_scene.py` 的 `ChineseText` 與 `tests/math_scene.py` 的 `FormulaTest`。
- 全部安裝在 `/workspace/tools`（repo 之外）。暫存放 `/workspace/scratch/tmp`，避免占用記憶體型的 `/tmp`。

## 已知限制（尚待實測）

- 需要能連到 conda-forge、micro.mamba.pm、Debian 鏡像（`deb.debian.org`，失敗時改用 snapshot.debian.org）。
- 預計耗時與下載量以第一次實測為準。
- libass 會警告 `ASS_FEATURE_WRAP_UNICODE` 不支援，中文長句字幕需手動斷行。
- 本 repo 為公開，請勿放入金鑰或帳密。
