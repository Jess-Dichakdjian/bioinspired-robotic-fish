// // //********* PIN CONFIGURATION *********//
// // const int IN1 = 5;   // DRV8871 PWM pin
// // const int IN2 = 6;  // DRV8871 Dir pin
// // const int encA = 2;  // Encoder Phase A (D2 for Interrupt)
// // const int encB = 3;  // Encoder Phase B

// // //********* ENCODER VARIABLES *********//
// // volatile long encoderCount = 0; 
// // long previousCount = 0;

// // //********* TIMING VARIABLES *********//
// // unsigned long previousTime = 0;
// // const int sampleTime = 50; // Calculate speed every 50 milliseconds

// // //********* PID VARIABLES *********//
// // float targetMechanicalHz = 6.0;
// // float motorCPR = 330.0; // Double check
// // float targetSpeed = (targetMechanicalHz * motorCPR) * (sampleTime / 1000.0);
// // float actualSpeed = 0;

// // // The PID Tuning Constants
// // float Kp = 1.5;
// // float Ki = 0.2;
// // float Kd = 0.1;

// // float error = 0;
// // float integral = 0;
// // float previousError = 0;

// // ////////////////////////////////////////////////////////////////////////////
// // void setup() {
// //   // Serial.begin(9600);

// //   pinMode(IN1, OUTPUT);
// //   pinMode(IN2, OUTPUT);
// //   pinMode(encA, INPUT_PULLUP);
// //   pinMode(encB, INPUT_PULLUP);

// //   // Attach the interrupt
// //   attachInterrupt(digitalPinToInterrupt(encA), updateEncoder, RISING);

// //   // Motor initial condition
// //   digitalWrite(IN1, LOW);
// //   digitalWrite(IN2, LOW);
  
// // }

// // ///////////////////////////////////////////////////////////////////////

// // void loop() {
// //   unsigned long currentTime = millis();

// //   // Run the control loop exactly every 50ms
// //   if (currentTime - previousTime >= sampleTime) {
    
// //     //Speed Calculation
// //     long currentCount = encoderCount;
// //     actualSpeed = currentCount - previousCount;
// //     previousCount = currentCount;

// //     //Error Calculation
// //     error = targetSpeed - actualSpeed;

// //     //PID Logic
// //     integral = integral + error;
    
// //     //Integral limits in case of motor stall (LOL)
// //     if (integral > 200) integral = 200;
// //     if (integral < -200) integral = -200;

// //     float derivative = error - previousError;
// //     previousError = error;

// //     //New PWM
// //     float controlSignal = (Kp * error) + (Ki * integral) + (Kd * derivative);

// //     //Output
// //     int motorPWM = constrain(controlSignal, 0, 255);
    
// //     digitalWrite(IN2, LOW);
// //     analogWrite(IN1, motorPWM);

// //     //Print
// //     // Serial.print("Target:");
// //     // Serial.print(targetSpeed);
// //     // Serial.print(" Actual:");
// //     // Serial.print(actualSpeed);
// //     // Serial.print(" PWM:");
// //     // Serial.println(motorPWM);

// //     //Reset Timer
// //     previousTime = currentTime;
// //   }
// // }

// // // --- HARDWARE INTERRUPT ---
// // void updateEncoder() {
// //   if (digitalRead(encB) == HIGH) {
// //     encoderCount++;
// //   } else {
// //     encoderCount--;
// //   }
// // }
// /////////////////////////////////////////////////////////////////////////////////
// //********* PIN CONFIGURATION *********//
// const int IN1 = 5;       // DRV8871 PWM pin (Muscle)
// const int IN2 = 6;       // DRV8871 Dir pin (Direction)
// const int hallPin = 4;   // A3144 Hall Effect Sensor

// //********* STATE MACHINE VARIABLES *********//
// int swimMode = 0;         // 0 = OFF, 1 = 1Hz, 2 = 3Hz, 3 = 5Hz
// int lastHallState = HIGH; // Tracks the previous state of the sensor

// //********* ESTIMATED PWM SPEEDS *********//
// // Since the encoder is gone, these are raw power values (0-255). 
// // You must tune these numbers to match the physical speeds you want!
// int pwm1Hz = 50;  // Tune this to the slowest speed before it stalls
// int pwm3Hz = 100; // Tune this to your medium cruising speed
// int pwm5Hz = 200; // Tune this to your fast sprint speed

// void setup() {
//   pinMode(IN1, OUTPUT);
//   pinMode(IN2, OUTPUT);
  
//   // The A3144 MUST have an internal pull-up resistor active to work properly
//   pinMode(hallPin, INPUT_PULLUP);

//   // Set the motor direction to FORWARD
//   digitalWrite(IN2, LOW); 
  
//   // Start the fish in the OFF state
//   analogWrite(IN1, 0);    
// }

// void loop() {
//   // 1. READ THE SENSOR
//   int currentHallState = digitalRead(hallPin);

//   // 2. DETECT THE "TAP" (Edge Detection)
//   // We only trigger when the signal drops from HIGH (no magnet) to LOW (magnet present)
//   if (currentHallState == LOW && lastHallState == HIGH) {
    
//     swimMode++; // Move to the next swimming mode
    
//     // If we go past the 4th state, loop back to OFF
//     if (swimMode > 3) {
//       swimMode = 0; 
//     }
    
//     // "Debounce" delay. This forces the Arduino to ignore the sensor 
//     // for 300ms so a single tap doesn't register as a double-click.
//     delay(300); 
//   }
  
//   // Save the state for the next loop
//   lastHallState = currentHallState; 

//   // 3. EXECUTE THE SWIM MODE
//   switch (swimMode) {
//     case 0: // OFF
//       analogWrite(IN1, 0);
//       break;
      
//     case 1: // State 1: Slow (~1 Hz)
//       analogWrite(IN1, pwm1Hz);
//       break;
      
//     case 2: // State 2: Medium (~3 Hz)
//       analogWrite(IN1, pwm3Hz);
//       break;
      
//     case 3: // State 3: Fast (~5 Hz)
//       analogWrite(IN1, pwm5Hz);
//       break;
//   }
// }

//********* PIN CONFIGURATION *********//
const int IN1 = 5;       // DRV8871 PWM pin (Muscle)
const int IN2 = 6;       // DRV8871 Dir pin (Direction)
const int encA = 2;      // Encoder Phase A (Must be D2)
const int encB = 3;      // Encoder Phase B

//********* POSITION VARIABLES *********//
volatile long encoderCount = 0; 
float motorCPR = 330.0;  // WARNING: Change this to your motor's actual CPR!

//********* TIMING VARIABLES *********//
unsigned long previousMillis = 0; 
const long printInterval = 500; // Print data every 500ms

void setup() {
  Serial.begin(9600);
  
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(encA, INPUT_PULLUP);
  pinMode(encB, INPUT_PULLUP);

  // Wake up the hardware interrupt for the encoder
  attachInterrupt(digitalPinToInterrupt(encA), updateEncoder, RISING);

  // Set motor to move FORWARD
  digitalWrite(IN2, LOW); 
  
  // Set the continuous running speed (0 to 255)
  // If it stalls and hums, raise this number!
  analogWrite(IN1, 50);   
  delay(2000);
  analogWrite(IN1, 60); 
  delay(2000); 
  analogWrite(IN1, 80); 


  
  Serial.println("Continuous Run Mode Online.");
}

void loop() {
  // Grab the current time
  unsigned long currentMillis = millis();

  // Check if 500ms have passed since our last print
  if (currentMillis - previousMillis >= printInterval) {
    // Save the last time we printed
    previousMillis = currentMillis;
    
    // THE MATH
    float currentAngle = (encoderCount / motorCPR) * 360.0;
    
    // THE PRINT
    Serial.print("Clicks: ");
    Serial.print(encoderCount);
    Serial.print("  |  Angle: ");
    Serial.print(currentAngle);
    Serial.println(" Degrees");
  }
}

// --- HARDWARE INTERRUPT ---
void updateEncoder() {
  if (digitalRead(encB) == HIGH) {
    encoderCount++;
  } else {
    encoderCount--;
  }
}