//********* PIN CONFIGURATION *********//
const int IN1 = 5;       // DRV8871 PWM pin (Muscle)
const int IN2 = 6;       // DRV8871 Dir pin (Direction)
const int encA = 2;      // Encoder Phase A (Must be D2)
const int encB = 3;      // Encoder Phase B

//********* ENCODER VARIABLES *********//
volatile long encoderCount = 0; 
long previousCount = 0;
float motorCPR = 374.0;  // WARNING: Double check your motor's CPR!

//********* TIMING VARIABLES *********//
unsigned long previousControlMillis = 0; 
const long controlInterval = 50;  // Run the PID math every 50ms

unsigned long previousPrintMillis = 0; 
const long printInterval = 500;   // Update the screen every 500ms

//********* RAMP-UP VARIABLES *********//
float targetHz = 1.5; // Your final cruising speed (Revolutions per Second)
float maxTargetSpeed = (targetHz * motorCPR) * (controlInterval / 1000.0); 

float currentTargetSpeed = 0.0; // The motor starts at a target of 0
float rampRate = 1.0;           // Add 1 click of target speed every 50ms

//********* PID VARIABLES *********//
// Tune these if the motor stutters or overshoots!
float Kp = 1.5;
float Ki = 0.2;
float Kd = 0.1;

float integral = 0;
float previousError = 0;
float actualSpeed = 0;
int currentPWM = 0;

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
  analogWrite(IN1, 0);    
  
  Serial.println("Closed-Loop Soft-Start Online.");
}

void loop() {
  unsigned long currentMillis = millis();

  // --- 1. THE CONTROL LOOP (Runs exactly every 50ms) ---
  if (currentMillis - previousControlMillis >= controlInterval) {
    previousControlMillis = currentMillis;

    // A. RAMP UP THE SPEED LIMIT
    // Smoothly increase the target speed until we hit our cruising speed
    if (currentTargetSpeed < maxTargetSpeed) {
      currentTargetSpeed = currentTargetSpeed + rampRate;
      
      // Cap it so it doesn't accidentally go over the target
      if (currentTargetSpeed > maxTargetSpeed) {
        currentTargetSpeed = maxTargetSpeed;
      }
    }

    // B. READ ACTUAL SPEED
    long currentCount = encoderCount;
    actualSpeed = currentCount - previousCount;
    previousCount = currentCount; // Reset for the next loop

    // C. PID MATH (The Feedback)
    float error = currentTargetSpeed - actualSpeed;
    integral = integral + error;
    
    // Anti-Windup: Prevents math explosion if you grab the motor and stall it
    if (integral > 200) integral = 200;
    if (integral < -200) integral = -200;

    float derivative = error - previousError;
    previousError = error;

    // D. CALCULATE POWER
    float controlSignal = (Kp * error) + (Ki * integral) + (Kd * derivative);

    // E. APPLY POWER
    currentPWM = constrain(controlSignal, 0, 255);
    analogWrite(IN1, currentPWM);
  }

  // --- 2. THE PRINT LOOP (Runs every 500ms) ---
  if (currentMillis - previousPrintMillis >= printInterval) {
    previousPrintMillis = currentMillis;
    
    Serial.print("Target Limit: ");
    Serial.print(currentTargetSpeed);
    Serial.print("  |  Actual Speed: ");
    Serial.print(actualSpeed);
    Serial.print("  |  Raw PWM: ");
    Serial.println(currentPWM);
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