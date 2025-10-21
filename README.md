# LanguageToLightMappingSystem
將語言與色彩、燈光動畫相結合。 使用者輸入任意詞彙，系統透過本機 AI 模型（Ollama）生成對應的語意顏色， 並以 Processing 視覺化呈現出流動的矩陣燈條效果。Python FastAPI 服務負責詞彙→顏色的語意映射，Processing 程式則即時顯示單色或漸層的燈光變化 ，本系統可作為「語言與光」之間關聯的研究平台，探索語意、情緒與視覺的跨域對應。

Python : 
1. 安裝 Python 3.9 以上版本
2. 安裝必要套件：pip install fastapi uvicorn requests pydantic
3. 安裝 Ollama 並執行 (確保可在終端機輸入 ollama run gemma3:4b)
4. 在終端機進入 color_service.py 層級的資料夾 
5. 終端機中啟動程式 : py -m uvicorn color_service:app --port 8010
6. 終端機會出現：表示正常啟動

    INFO: Started server process [xxxx]

    INFO: Application startup complete.	

Processing : 
1. 安裝 Processing 4.x 版本
2. 開啟 matrix_light_color.pde
3. 點擊播放執行
4. 在視窗輸入詞彙(中英都可)，按 Enter 程式會連線到 Python 並顯示對應顏色

	
小結 :
1. Processing 將使用者輸入詞彙送到本機 http://127.0.0.1:8010/color?q=...
2. color_service.py 呼叫 Ollama 模型生成顏色 JSON，例如：{"mode":"gradient","hex":["#1E90FF","#00CED1"]}
3. Processing 根據 JSON 回傳顏色繪出矩陣燈條（支援單色或漸層模式）
