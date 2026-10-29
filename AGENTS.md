# Operating Rules

- 每個任務第一步先執行 `source /workspace/tools/env.sh`；此檔會設定 HOME、PATH、Manim 的 conda 環境與 TeX 路徑。
- 一律使用該環境的 `python`、`manim` 與 `ffmpeg`，不使用系統 Python。
- 不使用 `sudo` 或 `apt install`。需要新套件時先回報，不要自行安裝。
- 中文文字使用 Manim 的 `Text`，字型指定 `Noto Sans CJK TC`；`MathTex` 只放純數學符號。
- 先以低畫質（480p、15fps）測試，確認沒有問題後才產出正式畫質。
- 輸出檔案放在 `/workspace/scratch/out`，不得放進 repo，也不得提交 MP4 等大型檔案。
- 開始製作前先重跑 `/workspace/tools/tests/text_scene.py` 的 `ChineseText` 與 `/workspace/tools/tests/math_scene.py` 的 `FormulaTest` 兩個驗收場景，確認環境正常。
