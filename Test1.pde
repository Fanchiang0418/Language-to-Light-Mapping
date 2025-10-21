import oscP5.*;
import netP5.*;

OscP5 oscP5;

int    LISTEN_PORT = 9000; // 要和 Python 發送的 port 一致
boolean enable     = true;
int    direction   = 1;    // 1: 右, -1: 左
float  speed       = 1.0;  // 可接收浮點
int    colR = 0, colG = 128, colB = 255;

float  flowX = 0;          // 流動位移

void setup() {
  size(1280, 720, P2D);
  frameRate(60);
  oscP5 = new OscP5(this, LISTEN_PORT);
  noStroke();
}

void draw() {
  background(0);
  if (!enable) {
    // 關閉就以暗背景顯示
    fill(40);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("Flow disabled (/flow/enable = 0)", width/2, height/2);
    return;
  }

  // 根據 speed + direction 推進位移
  flowX += (direction * speed) * 3.0;  // 3.0 是視覺上的比例尺，你可調
  // 讓位移不會爆表
  if (flowX > width)  flowX -= width;
  if (flowX < -width) flowX += width;

  // 畫一些往左/往右移動的條紋
  int stripeW = 64; // 條紋寬度
  for (int x = -stripeW*2; x < width + stripeW*2; x += stripeW) {
    float offset = (x + flowX) % (stripeW * 2);
    // 交錯透明度，形成條紋
    float alpha = (offset < stripeW) ? 220 : 80;
    fill(colR, colG, colB, alpha);
    rect(x + flowX, 0, stripeW, height);
  }

  // 顯示目前參數（除錯用）
  fill(255);
  textSize(14);
  text("enable: " + enable +
       "   direction: " + direction +
       "   speed: " + nf(speed, 1, 2) +
       "   color: (" + colR + "," + colG + "," + colB + ")",
       16, height - 24);
}

// 這裡處理收到的 OSC 訊息
void oscEvent(OscMessage m) {
  String addr = m.addrPattern();

  if (addr.equals("/flow/enable")) {
    enable = m.get(0).intValue() == 1;

  } else if (addr.equals("/flow/direction")) {
    int d = m.get(0).intValue();
    direction = (d >= 0) ? 1 : -1; // 只允許 1 或 -1

    } else if (addr.equals("/flow/speed")) {
    // oscP5 會自動幫你轉成 float 或 int
    try {
      speed = m.get(0).floatValue();
    } catch(Exception e) {
      speed = (float)m.get(0).intValue();
    }
    speed = constrain(speed, 0.0, 5.0);


  } else if (addr.equals("/flow/color_r")) {
    colR = constrain(m.get(0).intValue(), 0, 255);
  } else if (addr.equals("/flow/color_g")) {
    colG = constrain(m.get(0).intValue(), 0, 255);
  } else if (addr.equals("/flow/color_b")) {
    colB = constrain(m.get(0).intValue(), 0, 255);
  } else {
    println("Unhandled OSC: " + addr + "  -> " + m.toString());
  }
}
