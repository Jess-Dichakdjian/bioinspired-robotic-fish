#include <util/atomic.h>
#include <Servo.h>
#include <Wire.h>
#include <MPU9250_asukiaaa.h>
#include <math.h>

//********* FEATURE TOGGLES *********//
// Change to toggle use of magnetic switch
bool useHallSensor = true;

// If actualSpeed becomes negative while the motor is spinning forward,
// change this from 1 to -1.
const int ENCODER_SIGN = 1;

//********* PIN CONFIGURATION *********//
const int IN1 = 5;       // DRV8871 PWM pin
const int IN2 = 6;       // DRV8871 Dir pin
const int encA = 2;      // Encoder Phase A
const int encB = 3;      // Encoder Phase B
const int hallPin = 4;   // A3144 Hall Effect Sensor
const int servoPin = 10; // Servo Signal Pin

//********* OBJECTS *********//
Servo headServo;
MPU9250_asukiaaa imu;

//********* SWIM SPEED VARIABLES *********//
float normalHz = 1.5; // Cruising Speed
float fastHz = 3.5;   // Sprint Speed
int currentMode = 0;  // 0 = OFF, 1 = NORMAL, 2 = FAST

//********* ENCODER VARIABLES *********//
volatile long encoderCount = 0;
long previousCount = 0;
float motorCPR = 374.0;  // 11 PPR x 34 Gear Ratio

//********* PID & RAMP VARIABLES *********//
unsigned long previousControlMillis = 0;
const long controlInterval = 50;  // ms

float currentTargetSpeed = 0.0;
float maxTargetSpeed = 0.0;
float rampRate = 1.0;  // encoder counts per control interval

float Kp = 1.5;
float Ki = 0.2;
float Kd = 0.1;

float integral = 0;
float previousError = 0;
float actualSpeed = 0;
int currentPWM = 0;

//********* HALL EFFECT VARIABLES *********//
unsigned long magnetStartTime = 0;
bool magnetPresent = false;
bool longPressTriggered = false;

//********* GYRO VARIABLES *********//
unsigned long previousGyroMillis = 0;
float angleX = 0.0f;
float gyroX_offset = 0.0f;

const float GYRO_MIN = -20.0f;   // Fish leans 20 degrees left
const float GYRO_MAX = 20.0f;    // Fish leans 20 degrees right
const float SERVO_MIN = 50.0f;   // Servo corrects right
const float SERVO_MAX = 90.0f;   // Servo corrects left
const int SERVO_CENTER = 70;

// ============================================================
//  HELPER FUNCTIONS
// ============================================================

long readEncoderCountSafe() {
  long countCopy = 0;

  ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
    countCopy = encoderCount;
  }

  return countCopy * ENCODER_SIGN;
}

void stopMotorImmediately() {
  currentPWM = 0;
  analogWrite(IN1, 0);
  digitalWrite(IN2, LOW);
}

void resetPID() {
  integral = 0;
  previousError = 0;
}

// ============================================================
//  SETUP
// ============================================================

void setup() {
  Serial.begin(115200);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(encA, INPUT_PULLUP);
  pinMode(encB, INPUT_PULLUP);
  pinMode(hallPin, INPUT_PULLUP);

  attachInterrupt(digitalPinToInterrupt(encA), updateEncoder, RISING);

  digitalWrite(IN2, LOW);
  stopMotorImmediately();

  // Init Servo
  headServo.attach(servoPin);
  headServo.write(SERVO_CENTER);

  // Init Gyro
  Wire.begin();
  imu.setWire(&Wire);
  imu.beginGyro();

  delay(100);
  calibrateGyro();

  previousGyroMillis = millis();
  previousControlMillis = millis();
  previousCount = readEncoderCountSafe();

  // Handle the "Bypass Sensor" Feature
  if (!useHallSensor) {
    Serial.println("Hall Sensor Bypassed. Auto-Starting NORMAL Mode.");
    setSwimMode(1);
  } else {
    Serial.println("Awaiting Magnetic Scan...");
  }
}

// ============================================================
//  MAIN LOOP
// ============================================================

void loop() {
  unsigned long currentMillis = millis();

  // 1. Read the UI using Hall Effect Sensor
  if (useHallSensor) {
    runHallSensor();
  }

  // 2. Head Stabilization every 10 ms
  if (currentMillis - previousGyroMillis >= 10) {
    runGyroServo(currentMillis);
  }

  // 3. Motor PID & Soft-Start every 50 ms
  if (currentMillis - previousControlMillis >= controlInterval) {
    runMotorControl(currentMillis);
  }
}

// ============================================================
//  HALL EFFECT LOGIC
// ============================================================

void runHallSensor() {
  int hallState = digitalRead(hallPin);

  if (hallState == LOW) {
    // Magnet is touching
    if (!magnetPresent) {
      magnetPresent = true;
      magnetStartTime = millis();
      longPressTriggered = false;
    } else {
      // Magnet is being held down. Wait for 3 seconds.
      if (!longPressTriggered && (millis() - magnetStartTime >= 3000)) {
        longPressTriggered = true;
        setSwimMode(2); // FAST MODE
        Serial.println("LONG PRESS: Fast Mode Engaged!");
      }
    }
  } else {
    // Magnet was removed
    if (magnetPresent) {
      magnetPresent = false;
      unsigned long holdTime = millis() - magnetStartTime;

      // Short tap: more than 50 ms but less than 3 seconds
      if (!longPressTriggered && holdTime > 50) {
        if (currentMode == 0) {
          setSwimMode(1); // Turn ON Normal Mode
          Serial.println("SHORT TAP: Normal Mode Engaged!");
        } else {
          setSwimMode(0); // Turn OFF
          Serial.println("SHORT TAP: Motor Stopped.");
        }
      }
    }
  }
}

// ============================================================
//  SET SPEED TARGETS
// ============================================================

void setSwimMode(int mode) {
  currentMode = mode;

  // OFF mode: stop immediately, do not wait for ramp-down
  if (mode == 0) {
    maxTargetSpeed = 0.0;
    currentTargetSpeed = 0.0;
    resetPID();
    stopMotorImmediately();
    previousCount = readEncoderCountSafe();
    return;
  }

  resetPID();
  currentTargetSpeed = 0.0; // Clear previous ramp memory to start smoothly from 0
  previousCount = readEncoderCountSafe();

  float targetHz = 0.0;

  if (mode == 1) {
    targetHz = normalHz;
  } else if (mode == 2) {
    targetHz = fastHz;
  }

  // Explicit float-safe conversion from milliseconds to seconds
  float controlIntervalSeconds = (float)controlInterval / 1000.0f;

  // Target speed = expected encoder counts per control interval
  maxTargetSpeed = targetHz * motorCPR * controlIntervalSeconds;
}

// ============================================================
//  MOTOR PID & SOFT START
// ============================================================

void runMotorControl(unsigned long currentMillis) {
  previousControlMillis = currentMillis;

  // Safety: if OFF, force motor to stay stopped
  if (currentMode == 0) {
    currentTargetSpeed = 0.0;
    maxTargetSpeed = 0.0;
    resetPID();
    stopMotorImmediately();
    previousCount = readEncoderCountSafe();
    return;
  }

  // A. RAMP UP or RAMP DOWN
  if (currentTargetSpeed < maxTargetSpeed) {
    currentTargetSpeed += rampRate;
    if (currentTargetSpeed > maxTargetSpeed) {
      currentTargetSpeed = maxTargetSpeed;
    }
  } else if (currentTargetSpeed > maxTargetSpeed) {
    currentTargetSpeed -= rampRate;
    if (currentTargetSpeed < maxTargetSpeed) {
      currentTargetSpeed = maxTargetSpeed;
    }
  }

  // B. READ ENCODER SAFELY
  long currentCount = readEncoderCountSafe();

  actualSpeed = currentCount - previousCount;
  previousCount = currentCount;

  // C. PID MATH
  float error = currentTargetSpeed - actualSpeed;

  integral += error;

  // Anti-windup limit
  if (integral > 200) {
    integral = 200;
  }

  if (integral < -200) {
    integral = -200;
  }

  float derivative = error - previousError;
  previousError = error;

  float controlSignal = (Kp * error) + (Ki * integral) + (Kd * derivative);

  // D. APPLY POWER
  currentPWM = (int)constrain(controlSignal, 0.0f, 255.0f);

  digitalWrite(IN2, LOW);
  analogWrite(IN1, currentPWM);
}

// ============================================================
//  GYROSCOPE HEAD STABILIZATION
// ============================================================

void runGyroServo(unsigned long currentMillis) {
  float dt = (currentMillis - previousGyroMillis) / 1000.0f;
  previousGyroMillis = currentMillis;

  imu.gyroUpdate();

  float gx = imu.gyroX() - gyroX_offset;

  // Deadzone: ignore micro-vibrations
  if (fabs(gx) < 0.5f) {
    gx = 0.0f;
  }

  // Integrate gyro velocity to estimate angle
  angleX += gx * dt;

  // Leaky integrator: pulls the integrated angle slowly back toward 0.
  // This prevents tracking drift and keeps the physical response responsive.
  angleX *= 0.95f; 

  // Clamp the calculated angle to stay within defined boundaries
  float clampedAngle = constrain(angleX, GYRO_MIN, GYRO_MAX);

  // Float-safe servo mapping processing
  // If correction is reversed, swap SERVO_MAX and SERVO_MIN in this formula.
  float servoFloat = SERVO_MAX + 
    ((clampedAngle - GYRO_MIN) * (SERVO_MIN - SERVO_MAX)) / 
    (GYRO_MAX - GYRO_MIN);

  int servoPos = (int)(servoFloat + 0.5f);
  servoPos = constrain(servoPos, (int)SERVO_MIN, (int)SERVO_MAX);

  headServo.write(servoPos);
}

// ============================================================
//  CALIBRATE GYROSCOPE
// ============================================================

void calibrateGyro() {
  Serial.println("Calibrating Gyro... KEEP SENSOR STILL.");

  float sum = 0.0f;

  for (int i = 0; i < 500; i++) {
    imu.gyroUpdate();
    sum += imu.gyroX();
    delay(4);
  }

  gyroX_offset = sum / 500.0f;
  angleX = 0.0f;

  Serial.println("Calibration Complete.");
}

// ============================================================
//  ENCODER INTERRUPT
// ============================================================

void updateEncoder() {
  if (digitalRead(encB) == HIGH) {
    encoderCount++;
  } else {
    encoderCount--;
  }
}