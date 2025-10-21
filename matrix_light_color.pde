// Processing 4.x  (Java mode)
// 輸入詞彙 → 呼叫本機 color_service（Ollama/DeepSeek）→ 取得顏色（單色或漸層）
// 以矩陣條帶呈現，具左右流動效果（以亮度 alpha 做流動），顏色以 RGB 準確顯示。
// 先啟動 Python 服務：py -m uvicorn color_service:app --port 8010

import java.net.URLEncoder;

// ===== 服務設定 =====
String COLOR_SERVER = "http://127.0.0.1:8010/color";

// ===== 視覺網格設定（你現在要 1x10 條） =====
int cols = 10, rows = 1;
float margin = 20;

// ===== 動畫參數 =====
float t = 0;
int dir = 1;               // 1 右, -1 左（左右方向）
float speed = 0.6;         // 速度（+ / - 可調）

// ===== 顏色狀態（RGB 版本） =====
boolean useGradient = false;
ArrayList<int[]> rgbList = new ArrayList<int[]>();  // 每個元素是 {r,g,b} (0..255)
int[] rgbSingle = new int[]{20,200,120};            // 預設單色（隨便放一色）

// ===== UI/輸入 =====
String inputText = "";
boolean svcOK = true;

void setup() {
  size(960, 520);
  surface.setTitle("矩陣燈 × LLM 顏色服務（Enter 查色，左右調方向，+/- 調速度）");
  // HUD 用 HSB 比較好看；但繪圖主體我們會切到 RGB
  colorMode(HSB, 360, 1, 1, 1);
  textFont(createFont("Noto Sans CJK TC", 16));
  svcOK = pingService();
}

void draw() {
  background(235, 0.06, 0.06);

  float cellW = (width - 2*margin) / (float)cols;
  float cellH = (height - 100 - 2*margin) / (float)rows; // 底部留輸入列

  // 流動參數
  t += speed * 0.016f;
  float wavePeriod = 16.0;
  float bandWidth  = 0.9;

  // === 用 RGB 模式繪色，確保 HEX 呈現準確 ===
  pushStyle();
  colorMode(RGB, 255);

  noStroke();
  for (int y=0; y<rows; y++) {
    for (int x=0; x<cols; x++) {

      // 亮帶流動（決定透明度）
      float phase = (x*1.0f*dir/wavePeriod - t) % 1.0f;
      if (phase < 0) phase += 1.0f;
      float d = abs(phase - 0.0f);
      float glow = smoothstep(1.0, 1.0 - bandWidth, 1.0 - d);

      float phaseY = (y*0.25f + t*0.5f) % 1.0f;
      float glowY = smoothstep(1.0, 0.4, abs(phaseY-0.0f));
      float val = constrain(glow*0.9 + glowY*0.1, 0, 1);
      float alpha255 = 255 * pow(val, 1.4);

      // 取得此欄顏色：單色或漸層（RGB 插值）
      int[] rgb;
      if (useGradient && rgbList.size() >= 2) {
        float u = (cols<=1)? 0 : x/(cols-1.0);
        rgb = rgbGradient(rgbList, u);
      } else {
        rgb = rgbSingle;
      }

      float px = margin + x*cellW;
      float py = margin + y*cellH;

      // 主塊
      fill(rgb[0], rgb[1], rgb[2], alpha255);
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);

      // 暗格邊框以強化矩陣感
      fill(0, 0, 0, 90);
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);
    }
  }

  popStyle();

  drawHUD();
}

// ====== UI & 輸入 ======
void drawHUD() {
  float h = 70;
  fill(0, 0, 0, 0.8);
  rect(0, height - h, width, h);

  fill(0, 0, 1, 1);
  textAlign(LEFT, CENTER);
  text("輸入詞彙（Enter 查色）： " + inputText, 16, height - h/2);

  textAlign(RIGHT, CENTER);
  String colorModeStr = useGradient ? "漸層" : "單色";
  String svcStr = svcOK ? "服務: 正常" : "服務: 未連線";
  text( "配色: " + colorModeStr + "  |  " + svcStr,
       width - 16, height - h/2);

  if (!svcOK) {
    fill(0,0,1,1);
    textAlign(LEFT, TOP);
    text("⚠ 顏色服務未連線：請先執行  py -m uvicorn color_service:app --port 8010", 16, 16);
  }
}

void keyTyped() {
  if (key == ENTER || key == RETURN) {
    if (inputText.trim().length() > 0) queryColor(inputText.trim());
    inputText = "";
  } else if (key == BACKSPACE) {
    if (inputText.length() > 0) inputText = inputText.substring(0, inputText.length()-1);
  } else if (key != CODED) {
    inputText += key;
  }
}

void keyPressed() {
  if (keyCode == LEFT)  dir = -1;
  if (keyCode == RIGHT) dir = 1;
  if (key == '+') speed = min(3.0, speed + 0.1);
  if (key == '-') speed = max(0.05, speed - 0.1);
}

// ====== 呼叫 Python 顏色服務 ======
void queryColor(String term) {
  try {
    String url = COLOR_SERVER + "?q=" + URLEncoder.encode(term, "UTF-8");
    JSONObject res = loadJSONObject(url);
    if (res == null) throw new RuntimeException("服務無回應");
    String mode = res.getString("mode");

    if (mode.equals("single")) {
      String hex = res.getString("hex");
      rgbSingle = hexToRGB(hex);
      useGradient = false;
      rgbList.clear();

    } else { // gradient
      JSONArray arr = res.getJSONArray("hex");
      rgbList.clear();
      if (arr != null) {
        for (int i=0; i<arr.size(); i++) {
          rgbList.add(hexToRGB(arr.getString(i)));
        }
      }
      if (rgbList.size() >= 2) {
        useGradient = true;
      } else {
        useGradient = false;
        if (rgbList.size()==1) rgbSingle = rgbList.get(0);
      }
    }
    svcOK = true;
    println("取得顏色：" + res);

  } catch (Exception e) {
    println("取得顏色失敗：" + e.getMessage());
    svcOK = false;
    // 保底：字串 hash 生成穩定顏色（RGB）
    int h = abs(term.hashCode());
    int r = 60 + (h & 0x7F);         // 60..187
    int g = 60 + ((h>>7) & 0x7F);
    int b = 60 + ((h>>14) & 0x7F);
    rgbSingle = new int[]{r,g,b};
    useGradient = false; rgbList.clear();
  }
}

// ====== 顏色工具（RGB 版本） ======

// #RRGGBB → {r,g,b}
int[] hexToRGB(String hex) {
  hex = hex.replace("#","");
  int r = unhex(hex.substring(0,2));
  int g = unhex(hex.substring(2,4));
  int b = unhex(hex.substring(4,6));
  return new int[]{r,g,b};
}

// RGB 線性插值
int[] mixRGB(int[] a, int[] b, float u) {
  u = constrain(u, 0, 1);
  int r = int(lerp(a[0], b[0], u));
  int g = int(lerp(a[1], b[1], u));
  int b2 = int(lerp(a[2], b[2], u));
  return new int[]{r,g,b2};
}

// 多點 RGB 漸層（u: 0..1）
int[] rgbGradient(ArrayList<int[]> C, float u) {
  if (C.size() == 1) return C.get(0);
  float seg = 1.0 / (C.size()-1);
  int i = int(constrain(floor(u/seg), 0, C.size()-2));
  float localU = (u - i*seg) / seg;
  return mixRGB(C.get(i), C.get(i+1), localU);
}

// 平滑步階（維持與原本一致）
float smoothstep(double edge0, double edge1, double x) {
  float t = constrain((float)((x-edge0)/(edge1-edge0)), 0, 1);
  return t*t*(3 - 2*t);
}

// 簡單 ping 服務
boolean pingService() {
  try {
    JSONObject j = loadJSONObject(COLOR_SERVER + "?q=ping");
    return j != null;
  } catch(Exception e) {
    return false;
  }
}
