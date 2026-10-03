#include <Servo.h> 

//********* PIN & OBJECT CONFIGURATION *********//
const int headServoPin = 9; 
Servo headServo; 

//********* SWEEP VARIABLES *********//
int centerAngle = 95; // This is your physical "Zero" straight ahead
int sweepAngle = 15;  // Scans 15 degrees left and 15 degrees right
int currentAngle = 95; 

// Tuning: A higher number makes the head turn slower and more naturally.
// 25ms is a good, slow "looking around" speed.
int scanDelay = 50; 

void setup() {
  headServo.attach(headServoPin);

  // Instantly lock the servo to the middle (90 degrees).
  // DO THIS BEFORE ATTACHING THE HEAD!
  headServo.write(centerAngle);
  delay(2000); // Give you 2 seconds to see it lock in place
}

void loop() {
  // --- SCAN LEFT ---
  // Move from 75 to 105 degrees smoothly
  for (currentAngle = (centerAngle - sweepAngle); currentAngle <= (centerAngle + sweepAngle); currentAngle++) { 
    headServo.write(currentAngle);              
    delay(scanDelay);                      
  }
  
  // --- SCAN RIGHT ---
  // Move from 105 back down to 75 degrees smoothly
  for (currentAngle = (centerAngle + sweepAngle); currentAngle >= (centerAngle - sweepAngle); currentAngle--) { 
    headServo.write(currentAngle);              
    delay(scanDelay);                       
  }
}
