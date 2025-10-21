// Processing 4.x  (Java mode)
// 在先前「矩陣燈」範例基礎上：加入語意→色彩，並支援多色漸層
// 你可以直接整份貼上跑；若你已經有前一版，只要替換新增的函式與 draw 中取得 hLocal 的幾行即可。

int cols = 10, rows = 1;
float margin = 20;

float t = 0;
int dir = 1;                // 1 右, -1 左
float speed = 0.6f;

float hueDeg = 0, sat = 0.95f, bri = 1.0f; // 單色模式的基色
ArrayList<Float> conceptHues = new ArrayList<Float>(); // 多概念色相
boolean useGradient = false; // 是否啟動概念漸層

String input = "";

void setup() {
  size(960, 420);
  surface.setTitle("Matrix Light + 語意配色 Demo");
  colorMode(HSB, 360, 1, 1, 1);
  textFont(createFont("Noto Sans CJK TC", 16));
  setColorByName("紅");
}

void draw() {
  background(235, 0.06, 0.06);

  float cellW = (width - 2*margin) / (float)cols;
  float cellH = (height - 80 - 2*margin) / (float)rows;

  t += speed * 0.016f;
  float wavePeriod = 16.0;
  float bandWidth  = 0.9;

  noStroke();
  for (int y=0; y<rows; y++) {
    for (int x=0; x<cols; x++) {
      float phase = (x/(float)wavePeriod - t*dir) % 1.0f;
      if (phase < 0) phase += 1.0f;
      float d = abs(phase - 0.0f);
      float glow = smoothstep(1.0f, 1.0f-bandWidth, 1.0f - d);

      float phaseY = (y*0.25f + t*0.5f) % 1.0f;
      float glowY = smoothstep(1.0f, 0.4f, abs(phaseY-0.0f));
      float val = constrain(glow*0.9f + glowY*0.1f, 0, 1);
      float alpha = pow(val, 1.4f);

      // --- 針對每一欄決定顏色：若有概念漸層，用 x 在多色間插值 ---
      float hLocal = hueDeg;
      float sLocal = sat, bLocal = bri;
      if (useGradient && conceptHues.size() > 0) {
        float u = (cols<=1)? 0 : x/(cols-1.0f);
        hLocal = hueGradient(conceptHues, u);
        sLocal = 0.95f; bLocal = 1.0f;
      }

      fill(hLocal, sLocal, max(0.2f, bLocal*alpha), 1);
      float px = margin + x*cellW;
      float py = margin + y*cellH;
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);

      fill(235, 0.06, 0.02, 0.35);
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);
    }
  }

  drawInputBar();
}

// ---- 指令解析：加入「語意配色」----
void applyCommand(String s) {
  String cmd = s.replace("，", " ").replace(",", " ").trim();

  // 方向
  if (cmd.matches(".*(向左|往左|左).*")) dir = -1;
  else if (cmd.matches(".*(向右|往右|右).*")) dir = 1;

  // 速度
  if (cmd.matches(".*很慢.*"))      speed = 0.15f;
  else if (cmd.matches(".*慢.*"))   speed = 0.4f;
  else if (cmd.matches(".*中等.*")) speed = 0.6f;
  else if (cmd.matches(".*很快.*")) speed = 2.0f;
  else if (cmd.matches(".*快.*"))   speed = 1.2f;

  // 先嘗試語意→色彩（可多色）
  if (!mapConceptColors(cmd)) {
    // 若沒有命中語意，就回退到基本色名
    if      (cmd.matches(".*(紅|紅色).*")) setColorByName("紅");
    else if (cmd.matches(".*(橙|橘).*"))   setColorByName("橙");
    else if (cmd.matches(".*(黃|黃色).*")) setColorByName("黃");
    else if (cmd.matches(".*(綠|綠色).*")) setColorByName("綠");
    else if (cmd.matches(".*(青|青色).*")) setColorByName("青");
    else if (cmd.matches(".*(藍|藍色).*")) setColorByName("藍");
    else if (cmd.matches(".*(紫|紫色).*")) setColorByName("紫");
    else if (cmd.matches(".*(粉|粉色).*")) setColorByName("粉");
    else if (cmd.matches(".*(白|白色).*")) setColorByName("白");
  }
}

void setColorByName(String name) {
  useGradient = false; conceptHues.clear();
  if (name.contains("紅")) hueDeg = 0;
  else if (name.contains("橙") || name.contains("橘")) hueDeg = 25;
  else if (name.contains("黃")) hueDeg = 55;
  else if (name.contains("綠")) hueDeg = 120;
  else if (name.contains("青")) hueDeg = 180;
  else if (name.contains("藍")) hueDeg = 220;
  else if (name.contains("紫")) hueDeg = 280;
  else if (name.contains("粉")) hueDeg = 330;
  else if (name.contains("白")) { sat = 0; hueDeg = 0; bri = 1; return; }
  sat = 0.95f; bri = 1.0f;
}

// ---- 語意→色彩（你可持續擴充） ----
boolean mapConceptColors(String s) {
  conceptHues.clear();
  useGradient = false;

  // 景色
  if (s.matches(".*(山|群山|森林).*")) conceptHues.add(120f);   // 綠
  if (s.matches(".*(水|河|海|湖|雨|依山傍水).*")) conceptHues.add(190f); // 青藍
  if (s.matches(".*(夕陽|黃昏).*")) conceptHues.add(30f);        // 橙金
  if (s.matches(".*(晨|清晨|黎明).*")) conceptHues.add(55f);     // 柔黃
  if (s.matches(".*(春|春天|春暖花開|花|花開|花園).*")) {       // 春季意象
    conceptHues.add(330f); // 粉紅
    conceptHues.add(55f);  // 柔黃
    conceptHues.add(120f); // 嫩綠
  }

  // 情緒
  if (s.matches(".*(開心|喜悅|興奮).*")) conceptHues.add(50f);   // 暖黃
  if (s.matches(".*(平靜|放鬆|冥想).*")) conceptHues.add(180f);  // 青綠
  if (s.matches(".*(憂鬱|傷心|孤獨).*")) conceptHues.add(220f);  // 藍
  if (s.matches(".*(生氣|憤怒).*")) conceptHues.add(0f);         // 紅
  if (s.matches(".*(浪漫|溫柔).*")) conceptHues.add(330f);       // 粉

  // 物件
  if (s.matches(".*(蘋果).*")) { conceptHues.add(0f); conceptHues.add(120f); } // 紅+綠
  if (s.matches(".*(香蕉).*")) conceptHues.add(55f);
  if (s.matches(".*(葡萄).*")) conceptHues.add(280f);

  // 若抓到 >=2 個概念 → 啟用左右漸層；抓到 1 個 → 單色；0 個 → 回傳 false
  if (conceptHues.size() >= 2) {
    useGradient = true;
    sat = 0.95f; bri = 1.0f;
    return true;
  } else if (conceptHues.size() == 1) {
    setColorByHue(conceptHues.get(0));
    return true;
  }
  return false;
}

void setColorByHue(float h) {
  useGradient = false;
  hueDeg = (h%360+360)%360;
  sat = 0.95f; bri = 1.0f;
}

// 多點色相漸層（依 x 比例 u 0..1 在多色之間插值，色相走最短弧）
float hueGradient(ArrayList<Float> H, float u) {
  if (H.size()==1) return H.get(0);
  float seg = 1.0f / (H.size()-1);
  int i = int(constrain(floor(u/seg), 0, H.size()-2));
  float localU = (u - i*seg) / seg;
  return hueLerpShortest(H.get(i), H.get(i+1), localU);
}

// 在色相圓上走最短路徑的插值
float hueLerpShortest(float a, float b, float u) {
  float da = ((b - a + 540) % 360) - 180; // -180..180
  return (a + da*u + 360) % 360;
}

float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x-edge0)/(edge1-edge0), 0, 1);
  return t*t*(3 - 2*t);
}

void drawInputBar() {
  float h = 50;
  fill(0, 0, 0, 0.75);
  rect(0, height - h, width, h);
  fill(0, 0, 1, 1);
  textAlign(LEFT, CENTER);
  text("指令（Enter 套用）: " + input, 16, height - h/2);

  textAlign(RIGHT, CENTER);
  String info = "方向: " + (dir==1?"右":"左") + " | 速度: " + nf(speed,1,2) +
                (useGradient ? " | 配色: 漸層" : " | 配色: 單色 H="+int(hueDeg));
  fill(0, 0, 0.8, 1);
  text(info, width - 12, height - h/2);
}

void keyTyped() {
  if (key == ENTER || key == RETURN) {
    applyCommand(input);
    input = "";
  } else if (key == BACKSPACE) {
    if (input.length() > 0) input = input.substring(0, input.length()-1);
  } else if (key != CODED) {
    input += key;
  }
}
