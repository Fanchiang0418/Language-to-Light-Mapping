# filename: color_service.py
# run:  py -m uvicorn color_service:app --port 8010

from fastapi import FastAPI, Query
from pydantic import BaseModel
from typing import List, Union
import re, requests, hashlib, json

# ====== Ollama 設定 ======
OLLAMA_GEN_URL = "http://127.0.0.1:11434/api/generate"  # 用 /api/generate 較穩
OLLAMA_MODEL   = "gemma3:4b"   # 也可改 qwen3:30b / deepseek-r1:8b
TEMPERATURE    = 0.1             # 更保守，顏色較穩

# ====== 回傳資料模型 ======
class ColorResp(BaseModel):
    mode: str                      # "single" or "gradient"
    hex: Union[str, List[str]]     # "#RRGGBB" 或 ["#..", "#..", ...]

# ====== 工具 ======
HEX_RE = re.compile(r"#[0-9A-Fa-f]{6}")

def _pastel_from_hash(term: str) -> str:
    palette = ["#F44336","#E91E63","#9C27B0","#673AB7",
               "#3F51B5","#2196F3","#03A9F4","#00BCD4",
               "#009688","#4CAF50","#8BC34A","#FF9800"]
    h = hashlib.sha1(term.encode("utf-8")).hexdigest()
    return palette[int(h[:2], 16) % len(palette)]

# ====== 主要邏輯：問 Ollama 拿顏色（含容錯） ======
def llm_color_query(term: str) -> ColorResp:
    system = (
        "你是一個「詞彙→顏色」助手。收到一個中文（或英文）單詞，"
        "請回傳能代表該事物/情緒/景色的顏色。"
        "只能輸出『嚴格 JSON』，不能有多餘文字。\n"
        "格式：\n"
        '{"mode":"single","hex":"#RRGGBB"} '
        '或 '
        '{"mode":"gradient","hex":["#RRGGBB","#RRGGBB"]}\n'
        "原則：直覺、常識、文化慣例；若是乳製品或『牛奶/鮮奶/milk』，請選白/奶白(米白)。"
    )
    # few-shot 對齊
    examples = [
        {"term":"奶茶","json":'{"mode":"single","hex":"#C8A98F"}'},
        {"term":"蘋果","json":'{"mode":"gradient","hex":["#D62828","#59A52C"]}'},
        {"term":"牛奶","json":'{"mode":"single","hex":"#F2F0E9"}'},
        {"term":"海洋","json":'{"mode":"single","hex":"#1E90FF"}'},
        {"term":"開心","json":'{"mode":"single","hex":"#FFD54F"}'}
    ]
    fewshot = "\n".join([f'Term: {e["term"]}\nAnswer: {e["json"]}' for e in examples])

    prompt = f"{system}\n{fewshot}\nTerm: {term}\nAnswer:"

    body = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "format": "json",
        "stream": False,
        "options": {"temperature": TEMPERATURE}
    }

    try:
        r = requests.post(OLLAMA_GEN_URL, json=body, timeout=25)
        r.raise_for_status()
        data = r.json()
        raw = data.get("response", "")
        # 除錯可開：
        # print("DEBUG RAW:", raw)

        # 1) 優先當 JSON 解析
        try:
            obj = json.loads(raw)
        except Exception:
            # 2) 不是乾淨 JSON → 從原文抓 hex
            hexes = HEX_RE.findall(raw)
            if len(hexes) >= 2:
                return ColorResp(mode="gradient", hex=[h.upper() for h in hexes[:4]])
            elif len(hexes) == 1:
                return ColorResp(mode="single", hex=hexes[0].upper())
            # 3) 仍無 → 保底色
            return ColorResp(mode="single", hex=_pastel_from_hash(term))

        mode = str(obj.get("mode","")).lower()
        if mode == "single":
            hx = str(obj.get("hex","")).strip()
            if HEX_RE.fullmatch(hx):
                return ColorResp(mode="single", hex=hx.upper())
            # hex 無效 → 從原文抓
            hexes = HEX_RE.findall(raw)
            if hexes:
                return ColorResp(mode="single", hex=hexes[0].upper())
            return ColorResp(mode="single", hex=_pastel_from_hash(term))

        elif mode == "gradient":
            arr = obj.get("hex", [])
            cleaned = [h.upper() for h in arr if isinstance(h,str) and HEX_RE.fullmatch(h.strip())]
            if len(cleaned) >= 2:
                return ColorResp(mode="gradient", hex=cleaned[:4])
            # 不足兩色 → 從原文抓
            hexes = HEX_RE.findall(raw)
            if len(hexes) >= 2:
                return ColorResp(mode="gradient", hex=[h.upper() for h in hexes[:4]])
            elif len(hexes) == 1:
                return ColorResp(mode="single", hex=hexes[0].upper())
            return ColorResp(mode="single", hex=_pastel_from_hash(term))

        # 未知 mode → 保底
        return ColorResp(mode="single", hex=_pastel_from_hash(term))

    except Exception:
        return ColorResp(mode="single", hex=_pastel_from_hash(term))

# ====== FastAPI 應用與路由 ======
app = FastAPI()

@app.get("/color", response_model=ColorResp)
def get_color(q: str = Query(..., description="中文或任意詞彙")):
    return llm_color_query(q)
