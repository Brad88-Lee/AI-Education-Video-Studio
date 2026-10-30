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

## 重要運作規則（已實測）

- **Edit（設定）對話有外網；一般 Cloud 任務的 shell 沒有外網。** Cloud 任務連 `proxy:8080` 失敗（多次重現），所以 `setup.sh` 只能在 Edit 對話執行，不能依賴 Cloud 任務自行重建。
- **發佈抓取的是「按發佈的那個 Edit 對話」的檔案系統。** 流程：開一個新的 Edit 對話 → 在同一個對話執行 `sh env/setup.sh` → 同一個對話按「發佈」。中途換對話（或手機旋轉後重開）會從舊快照重來，工具就會遺失。
- 發佈後，用**全新的 Cloud 任務**驗收：`/workspace/tools/.setup-complete` 的 built 時間應早於任務開機時間（`uptime -s`）。
- 每個 Cloud 任務是各自獨立的容器（約 2 核 CPU 配額、8 GiB 記憶體）；同時開多個互不影響，但 CPU 型號不同時速度會差約 30%。
- Cloud 任務的 shell 無法對外傳檔；成果要靠 GitHub 連接器（Issue 留言、小檔）回傳。大檔取回方式尚未解決。

## 已知限制（尚待實測）

- 需要能連到 conda-forge、micro.mamba.pm、Debian 鏡像（`deb.debian.org`，失敗時改用 snapshot.debian.org）。
- 預計耗時與下載量以第一次實測為準。
- libass 會警告 `ASS_FEATURE_WRAP_UNICODE` 不支援，中文長句字幕需手動斷行。
- 本 repo 為公開，請勿放入金鑰或帳密。
