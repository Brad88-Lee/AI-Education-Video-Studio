# Operating Rules

- 每個任務第一步先確認環境：若 `/workspace/tools/env.sh` 不存在，先在 repo 根目錄執行 `sh env/setup.sh`（可能要數分鐘；完成後會自動跑驗收場景）。然後執行 `source /workspace/tools/env.sh`；此檔會設定 HOME、PATH 與 Manim 的 conda 環境。
- `env/setup.sh` 內的 `apt-get download` 加 `dpkg-deb -x` 是允許的（它不安裝套件、不需要 root）。除此之外不使用 `sudo` 或 `apt install`；需要新套件時先回報，不要自行安裝。
- 若 `setup.sh` 失敗，貼出完整錯誤後停止，不要改用系統的 ffmpeg 或 Python 繼續做。
- 一律使用該環境的 `python`、`manim` 與 `ffmpeg`，不使用系統 Python。
- 中文文字使用 Manim 的 `Text`，字型指定 `Noto Sans CJK TC`；`MathTex` 只放純數學符號。
- 先以低畫質（480p、15fps）測試，確認沒有問題後才產出正式畫質。
- 輸出檔案放在 `/workspace/scratch/out`，不得放進 repo，也不得提交 MP4 等大型檔案。
- 開始製作前先執行 `sh env/verify.sh`（渲染 `env/tests/` 內的 `ChineseText` 與 `FormulaTest` 兩個驗收場景），確認環境正常。
