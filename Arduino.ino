#include <FastLED.h>

#define NUM_LEDS 64
int num_lit[20];
int remind_lights[20];
int shooting_lights[15];

int red_light_backup[5];
int blue_light_backup[5];
int green_light_backup[5]; 


int red_light_backup_shoot[5];
int blue_light_backup_shoot[5];
int green_light_backup_shoot[5]; 


int num_index = 0;
String str_color = "";
bool restart = true;
bool ready_to_send = false;
bool gun_idle = true;
bool gun_loading = false;

CRGB leds[NUM_LEDS];
const int buttonPin_top = A1;
const int buttonPin_left = A3;
const int buttonPin_right = A0;
const int buttonPin_bottom = A2;
const int buttonPin_shoot = 27;
const int red_light_pin =14;
const int green_light_pin = 15;
const int blue_light_pin = 32;
const int led_pin = 13;
//const int ledPin = 13;
int buttonState_left = 0;
int buttonState_right = 0;
int buttonState_top = 0;
int buttonState_bottom = 0;
int buttonState_shoot = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial.setTimeout(3);
  pinMode(buttonPin_left,INPUT);
  pinMode(buttonPin_right, INPUT);
  pinMode(buttonPin_top, INPUT);
  pinMode(buttonPin_bottom, INPUT);
  pinMode(buttonPin_shoot,INPUT);

  pinMode(red_light_pin, OUTPUT);
  pinMode(green_light_pin, OUTPUT);
  pinMode(blue_light_pin, OUTPUT);
  FastLED.addLeds<WS2812,led_pin,GRB>(leds,NUM_LEDS);
  FastLED.setBrightness(250);
  //pinMode(ledPin, OUTPUT);

  for(int i=0;i<15;i++){
      remind_lights[i] = -1;
      shooting_lights[i] = -1;
  }
  for(int i=0;i<5;i++){
      red_light_backup[i] = -1;
      blue_light_backup[i] = -1;
      green_light_backup[i] = -1; 
      
      red_light_backup_shoot[i] = -1;
      blue_light_backup_shoot[i] = -1;
      green_light_backup_shoot[i] = -1; 

  }
  
  // Initialize the light
  RGB_color(255,255,255);
  
 
    
}

void loop() {
  // put your main code here, to run repeatedly:

  //Test_button
  buttonState_top = digitalRead(buttonPin_top);
  buttonState_bottom = digitalRead(buttonPin_bottom);
  buttonState_left = digitalRead(buttonPin_left);
  buttonState_right = digitalRead(buttonPin_right);
  buttonState_shoot = digitalRead(buttonPin_shoot);

  //Test
  /*leds[63] = CRGB(255,0,0);
  FastLED.show();
  delay(3000);
  if(leds[0] == CRGB(255,0,0)){
    leds[0] = CRGB(0,0,255);
    FastLED.show();
    delay(3000);
  }*/
  if (gun_idle){
    if (buttonState_shoot == LOW){
      gun_idle = false;
      gun_loading = true;
      Serial.write("A");
      // A
      delay(500);
    }
  } 
  else if(gun_loading){

    if(buttonState_shoot == HIGH){
      gun_idle = true;
      gun_loading = false;
      Serial.write("S");
      // S
      delay(500);
    }
  }
  
  
  if (buttonState_top == HIGH){
    Serial.write("T");
    //digitalWrite(ledPin,HIGH);
    delay(500);
  } else if (buttonState_bottom == HIGH){
    Serial.write("B");
    delay(500);
    
    //digitalWrite(ledPin,LOW);
  } else if (buttonState_left == HIGH){
    Serial.write("L");
    delay(500);
  } else if (buttonState_right == HIGH){
    Serial.write("R");
    delay(500);
  }
  
  
  String intchars = "";
  String chars = "";
  String temp_chars = "";
  if (restart){
    for(int i=0;i<15;i++){
      num_lit[i] = -1;
    }
    restart = false;
  }
 
 
  while (Serial.available()>0){
    char inchar = Serial.read();
      if(inchar != ','){
        temp_chars += inchar;
      } else {
        if (temp_chars != ""){
          num_lit[num_index] = temp_chars.toInt();
          temp_chars = "";
          //Serial.print(num_lit[num_index]);
          num_index += 1;
        }
      }
  //temp = intchars.toInt();
   // Serial.print(inchar);
   restart = true;
  }
  delay(10);
  
  if(num_lit[0] == 1){
    for(int i=1;i<15;i++){
      int index = num_lit[i];
      if(index != -1){ 
      leds[index] = CRGB(0,255,0);
      FastLED.show();   
      }
    }
  }

  if(num_lit[0] == 2){
    for(int i=1; i<15;i++){
      int index = num_lit[i];
      if(index != -1){
        leds[index] = CRGB(255,0,0);
        FastLED.show();
      }
    }
  }

  if(num_lit[0] == 3){
    for(int i=1; i<15;i++){
      int index = num_lit[i];
      if(index != -1){
        leds[index] = CRGB(0,0,255);
        FastLED.show();
      }
    }
  }
  // campiste invasion
  if(num_lit[0] == 4){
    if(remind_lights[1] == -1){
      for(int i=0;i<15;i++){
        remind_lights[i] = num_lit[i];
      }
    } else{
    for(int i=1;i<15;i++){
      int index = remind_lights[i];
      if(index != -1){
        leds[index] = CRGB(0,0,0);
        //FastLED.show();
      }
      //FastLED.show();
    }
    for(int i=0;i<5;i++){
      if(red_light_backup[i] != -1){
        leds[red_light_backup[i]] = CRGB(255,0,0);
      }
      if(green_light_backup[i] != -1){
        leds[green_light_backup[i]] = CRGB(0,255,0);
      }
      if(blue_light_backup[i] != -1){
        leds[blue_light_backup[i]] = CRGB(0,0,255);
      }
    }
    FastLED.show();
    
    for(int i=0;i<15;i++){
      remind_lights[i] = num_lit[i];
    }
    for(int i=0;i<5;i++){
      red_light_backup[i] = -1;
      green_light_backup[i] = -1;
      blue_light_backup[i] = -1;
    }
    }
  }
  
  if(num_lit[0] != 9){
    int r_index = 0;
    int g_index = 0;
    int b_index = 0;
    for(int i=1;i<15;i++){
      int index = remind_lights[i];
      
      if(index != -1){
        if(num_lit[0] == 4){
          if(leds[index] == CRGB(255,0,0)){ // campsite ..
            red_light_backup[r_index] = index;
            r_index += 1;
          }
          if(leds[index] == CRGB(0,255,0)){
            green_light_backup[g_index] = index;
            g_index += 1;
          }
          if(leds[index] == CRGB(0,0,255)){
            blue_light_backup[b_index] = index;
            b_index += 1;
          }
        }
        breathing(index);
      }
    }
    if(num_lit[0] == 2){
      for(int i=0;i<5;i++){
        if(num_lit[1] == blue_light_backup[i]){
          blue_light_backup[i] = -1;
          for(int j=0;j<5;j++){
            if(red_light_backup[j] == -1){
              red_light_backup[j] = num_lit[1];
              break;
            }
          }
        }
        if(num_lit[1] == green_light_backup[i]){
          green_light_backup[i] = -1;
          for(int j=0;j<5;j++){
            if(red_light_backup[j] == -1){
              red_light_backup[j] = num_lit[1];
              break;
            }
          }
        }
      }
    } 
    if(num_lit[0] == 3){
      for(int i=0;i<5;i++){
        if(num_lit[1] == red_light_backup[i]){
          red_light_backup[i] = -1;
          for(int j=0;j<5;j++){
            if(blue_light_backup[j] == -1){
              blue_light_backup[j] = num_lit[1];
              break;
            }
          }
        }
        if(num_lit[1] == green_light_backup[i]){
          green_light_backup[i] = -1;
          for(int j=0;j<5;j++){
            if(blue_light_backup[j] == -1){
              blue_light_backup[j] = num_lit[1];
              break;
            }
          }
        }
      }
    }
  } else {
    for(int i=1;i<15;i++){
      int index = remind_lights[i];
      if(index != -1){
        leds[index] = CRGB(0,0,0);
        //FastLED.show();
      }
      //FastLED.show();
    }
    for(int i=0;i<5;i++){
      if(red_light_backup[i] != -1){
        leds[red_light_backup[i]] = CRGB(255,0,0);
      }
      if(green_light_backup[i] != -1){
        leds[green_light_backup[i]] = CRGB(0,255,0);
      }
      if(blue_light_backup[i] != -1){
        leds[blue_light_backup[i]] = CRGB(0,0,255);
      }
    }
    FastLED.show();
    for(int i=0;i<15;i++){
      remind_lights[i] = -1;
    }
    for(int i=0;i<5;i++){
      red_light_backup[i] = -1;
      green_light_backup[i] = -1;
      blue_light_backup[i] = -1;
    }
  }

  if(num_lit[0] == 6){
    for(int i=0;i<15;i++){
      shooting_lights[i] = num_lit[i];
    }
  }
  if(num_lit[0] != 10){
    int r_index_s = 0;
    int g_index_s = 0;
    int b_index_s = 0;
    for(int i=1;i<15;i++){
      int index = shooting_lights[i];
      if(index != -1){
        if(num_lit[0] == 6){
          if(leds[index] == CRGB(255,0,0)){ // campsite ..
            red_light_backup[r_index_s] = index;
            r_index_s += 1;
          }
          if(leds[index] == CRGB(0,255,0)){
            green_light_backup[g_index_s] = index;
            g_index_s += 1;
          }
          if(leds[index] == CRGB(0,0,255)){
            blue_light_backup[g_index_s] = index;
            b_index_s += 1;
          }
        }
          breathing(index);
        //}
      }
    }
  }
  if (num_lit[0] == 11) { 
    for(int i=1;i<15;i++){
      int index = shooting_lights[i];
      if(index != -1){
        leds[index] = CRGB(0,0,0);
        //FastLED.show();
      }
    }
    for(int i=0;i<5;i++){
      if(red_light_backup[i] != -1){
        leds[red_light_backup_shoot[i]] = CRGB(255,0,0);
      }
      if(green_light_backup[i] != -1){
        leds[green_light_backup_shoot[i]] = CRGB(0,255,0);
      }
      if(blue_light_backup[i] != -1){
        leds[blue_light_backup_shoot[i]] = CRGB(0,0,255);
      }
    }
    FastLED.show();
    for(int i=0;i<15;i++){
      shooting_lights[i] = -1;
    }
    for(int i=0;i<5;i++){
      red_light_backup_shoot[i] = -1;
      blue_light_backup_shoot[i] = -1;
      green_light_backup_shoot[i] = -1; 
    }
  }

  if(num_lit[0] == 10){ // red turn
    RGB_color(0,255,255);
    
  }
  
  if(num_lit[0] == 11){ // blue turn
    RGB_color(255,255,0);
    
  }
  //Serial.print(num_lit[1]+num_lit[2]);
  if(num_lit[0] == 12){
    blue_win();
  }

 if(num_lit[0] == 13){
  red_win();
 }
  num_index = 0;
}

 

void breathing(int index){
  float breath = round((exp(sin(millis() / 2000.0 * PI)) - 0.36787944) * 108.0);
  //fill_solid(leds, NUM_LEDS, CHSV(40, 250, breath));
  leds[index] = CHSV(40,255,breath);
  FastLED.show();
}

void RGB_color(int red_light_value, int green_light_value, int blue_light_value){
  digitalWrite(red_light_pin,red_light_value);
  digitalWrite(green_light_pin,green_light_value);
  digitalWrite(blue_light_pin,blue_light_value);
}

void blue_win (){
   for(int i=0;i<NUM_LEDS;i++){
    leds[i] = CRGB(0,0,255);
    FastLED.show();
    delay(100);
  }
}

void red_win(){
  for(int i=0;i<NUM_LEDS;i++){
    leds[i] = CRGB(255,0,0);
    FastLED.show();
    delay(100);
  }
}
