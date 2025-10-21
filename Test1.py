from pythonosc import udp_client
import jieba
import colorsys  # 用來把 HSV 轉 RGB

# 建立 OSC client，指向 TouchDesigner 的 IP 與 port
client = udp_client.SimpleUDPClient("10.77.5.158", 9000)

def text_to_light_params(text: str):
    words = set(jieba.lcut(text))
    params = {
        "enable": 1,
        "direction": 1,   # 1 代表往右，-1 代表往左
        "speed": 1.0,
        "color_hsv": [0.58, 1.0, 1.0]  # 預設藍色（H, S, V）
    }

    # 方向
    if any(k in words for k in ["向左","左移","左流","往左"]):
        params["direction"] = -1
    elif any(k in words for k in ["向右","右移","右流","往右"]):
        params["direction"] = 1

    # 速度詞彙
    if any(k in words for k in ["慢","緩","悠悠"]):
        params["speed"] = 0.4
    elif any(k in words for k in ["快","迅速","急促"]):
        params["speed"] = 1.8
    elif any(k in words for k in ["爆衝","飛快","閃電"]):
        params["speed"] = 2.8

    # 顏色詞彙（用色相控制）
    color_map = {
        "紅": 0.0, "橘": 0.08, "黃": 0.15,
        "綠": 0.33, "藍": 0.58, "紫": 0.75
    }
    for c, h in color_map.items():
        if c in text:
            params["color_hsv"][0] = h

    # HSV → RGB (0~255)
    h, s, v = params["color_hsv"]
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    params["color_rgb"] = [int(r * 255), int(g * 255), int(b * 255)]

    return params

def send_light_command(text: str):
    p = text_to_light_params(text)
    client.send_message("/flow/enable", p["enable"])
    client.send_message("/flow/direction", p["direction"])
    client.send_message("/flow/speed", p["speed"])
    # 分開送三個 RGB 通道
    client.send_message("/flow/color_r", p["color_rgb"][0])
    client.send_message("/flow/color_g", p["color_rgb"][1])
    client.send_message("/flow/color_b", p["color_rgb"][2])
    print(f"✅ 已送出：{text} → {p}")

# 測試一句
send_light_command("燈光往右慢慢流動，紅色")
