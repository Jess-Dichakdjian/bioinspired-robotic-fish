//********* PIN CONFIGURATION *********//
const int IN1 = 5;       // DRV8871 PWM pin (Muscle)
const int IN2 = 6;       // DRV8871 Dir pin (Direction)
const int encA = 2;      // Encoder Phase A (Must be D2)
const int encB = 3;      // Encoder Phase B
const int hallPin = 4;   // A3144 Hall Effect Sensor

//********* POSITION VARIABLES *********//
volatile long encoderCount = 0; 
float motorCPR = 330.0;  // WARNING: Change this to your motor's actual CPR!

int lastHallState = HIGH;

void setup() {
  Serial.begin(9600);
  
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(hallPin, INPUT_PULLUP);
  pinMode(encA, INPUT_PULLUP);
  pinMode(encB, INPUT_PULLUP);

  // Wake up the hardware interrupt for the encoder
  attachInterrupt(digitalPinToInterrupt(encA), updateEncoder, RISING);

  // Set motor to move FORWARD, but keep speed at 0
  digitalWrite(IN2, LOW); 
  analogWrite(IN1, 0);    
  
  Serial.println("Calibration Mode Online.");
  Serial.println("Tap the A3144 with a magnet to jog the motor forward.");
}

void loop() {
  int currentHallState = digitalRead(hallPin);

  // Edge Detection: Only trigger when magnet first arrives
  if (1) {
    
    // 1. THE JOG (Move a tiny bit)
    analogWrite(IN1, 50); // Slow power (Adjust if it stalls)
    delay(50);            // Run for just 50 milliseconds
    analogWrite(IN1, 0);  // Slam the brakes
    
    // 2. THE MATH
    float currentAngle = (encoderCount / motorCPR) * 360.0;
    
    // 3. THE PRINT
    Serial.print("Clicks: ");
    Serial.print(encoderCount);
    Serial.print("  |  Angle: ");
    Serial.print(currentAngle);
    Serial.println(" Degrees");
    
    // Debounce to prevent accidental double-clicks
    delay(300); 
  }
  
  lastHallState = currentHallState; 
}

// --- HARDWARE INTERRUPT ---
void updateEncoder() {
  if (digitalRead(encB) == HIGH) {
    encoderCount++;
  } else {
    encoderCount--;
  }
}
// //********* PIN CONFIGURATION *********//
// const int IN1 = 5;       // DRV8871 PWM pin (Muscle)
// const int IN2 = 6;       // DRV8871 Dir pin (Direction)
// const int encA = 2;      // Encoder Phase A (Must be D2)
// const int encB = 3;      // Encoder Phase B

// //********* POSITION VARIABLES *********//
// volatile long encoderCount = 0; 
// float motorCPR = 330.0;  // WARNING: Change this to your motor's actual CPR!

// void setup() {
//   Serial.begin(9600);
  
//   pinMode(IN1, OUTPUT);
//   pinMode(IN2, OUTPUT);
//   pinMode(encA, INPUT_PULLUP);
//   pinMode(encB, INPUT_PULLUP);

//   // Wake up the hardware interrupt for the encoder
//   attachInterrupt(digitalPinToInterrupt(encA), updateEncoder, RISING);

//   // Set motor to move FORWARD, but keep speed at 0 initially
//   digitalWrite(IN2, LOW); 
//   analogWrite(IN1, 0);    
  
//   Serial.println("Auto-Stepper Calibration Online.");
//   Serial.println("Motor will step automatically every 2 seconds...");
  
//   delay(3000); // Give you 3 seconds to clear your hands before it starts moving
// }

// void loop() {
//   // 1. THE JOG (Move a tiny bit)
//   analogWrite(IN1, 80); // Slow power (Adjust if it stalls)
//   delay(50);            // Run for just 50 milliseconds
  
//   // 2. THE BRAKES
//   analogWrite(IN1, 0);  // Slam the brakes
  
//   // Wait a tiny fraction of a second for the physical motor 
//   // to completely stop vibrating before we do the math
//   delay(100); 
  
//   // 3. THE MATH
//   float currentAngle = (encoderCount / motorCPR) * 360.0;
  
//   // 4. THE PRINT
//   Serial.print("Clicks: ");
//   Serial.print(encoderCount);
//   Serial.print("  |  Angle: ");
//   Serial.print(currentAngle);
//   Serial.println(" Degrees");
  
//   // 5. THE WAIT
//   // Wait 2 full seconds before the next step so you can look at the tail
//   delay(2000); 
// }

// // --- HARDWARE INTERRUPT ---
// void updateEncoder() {
//   if (digitalRead(encB) == HIGH) {
//     encoderCount++;
//   } else {
//     encoderCount--;
//   }
// }