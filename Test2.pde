// Processing 4.x  (Java mode)
// 中文指令例：
// 1) 燈光往右慢慢流動，紅色
// 2) 向左很快流動，綠色
// 3) 往右流動，紫色
// 方向：向右/往右/右、向左/往左/左
// 速度：很慢/慢/中等/快/很快
// 顏色：紅/橙/黃/綠/青/藍/紫/粉/白

int cols = 5;
int rows = 1;
float margin = 20;

float t = 0;                // 時間
int dir = 1;                // 1 往右，-1 往左
float speed = 0.6f;         // 0.15(很慢) ~ 2.0(很快)
float hueDeg = 0;           // 基本色相 (0~360)
float sat = 0.95f, bri = 1.0f;

String input = "";          // 輸入列
boolean typing = true;

void setup() {
  size(960, 420);
  surface.setTitle("Matrix Light Demo - 中文指令：按 Enter 套用");
  colorMode(HSB, 360, 1, 1, 1);
  textFont(createFont("Noto Sans CJK TC", 16));
  setColorByName("紅"); // 預設紅色
}

void draw() {
  background(235, 0.06, 0.06); // 微暗背景(近黑)
  
  float cellW = (width - 2*margin) / (float)cols;
  float cellH = (height - 80 - 2*margin) / (float)rows; // 留底部輸入列空間

  // 時間推進
  t += speed * 0.016f;  // 與 frameRate 無關的近似
  float wavePeriod = 16.0; // 波長(欄)數，越小越銳利
  float bandWidth  = 0.9;  // 發光帶寬（越大越柔）

  // 繪格
  noStroke();
  for (int y=0; y<rows; y++) {
    for (int x=0; x<cols; x++) {
      // 讓亮帶沿著欄位（x）流動；dir 控向左/右
      float phase = (x*1.0f*dir/wavePeriod + t) % 1.0f;
      if (phase < 0) phase += 1.0f;

      // 讓每幾欄出現一個亮點帶，使用平滑窗函數
      float d = abs(phase - 0.0f); // 離帶中心距離
      // 轉成 0..1 的亮度，距離越近越亮
      float glow = smoothstep(1.0f, 1.0f-bandWidth, 1.0f - d);

      // 增加一些縱向細節（行 y 位移），像「漸層流動」
      float phaseY = (y*0.25f + t*0.5f) % 1.0f;
      float glowY = smoothstep(1.0f, 0.4f, abs(phaseY-0.0f));
      float val = constrain(glow*0.9f + glowY*0.1f, 0, 1);

      // 基底色混合到背景
      float alpha = pow(val, 1.4f);  // 軟化
      fill(hueDeg, sat, max(0.2f, bri*alpha), 1);
      float px = margin + x*cellW;
      float py = margin + y*cellH;
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);
      
      // 邊框暗格，讓矩陣感更強
      fill(235, 0.06, 0.02, 0.35);
      rect(px, py, cellW*0.9f, cellH*0.9f, 4);
    }
  }

  // 輸入列 UI
  drawInputBar();
}

// ---- 指令解析 ----
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

  // 顏色（第一個匹配就套用）
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

void setColorByName(String name) {
  // 以常見中文色名設定色相
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

// 平滑步階（類 GLSL）
float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x-edge0)/(edge1-edge0), 0, 1);
  return t*t*(3 - 2*t);
}

// ---- 簡易輸入列 ----
void drawInputBar() {
  float h = 50;
  fill(0, 0, 0, 0.75);
  rect(0, height - h, width, h);
  fill(0, 0, 1, 1);
  textAlign(LEFT, CENTER);
  text("指令（Enter 套用）: " + input, 16, height - h/2);

  // 狀態提示
  textAlign(RIGHT, CENTER);
  String info = "方向: " + (dir==1?"右":"左") + " | 速度: " + nf(speed,1,2) +
                " | 顏色H: " + int(hueDeg);
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
