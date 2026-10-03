# PHOENIX — Bioinspired Robotic Fish

**Programmable Hybrid Oceanic Entity: Networked Inertial Explorer**

A bioinspired robotic fish based on **Atlantic mackerel carangiform locomotion**, combining a mechanically actuated segmented tail, waterproof 3D-printed body, silicone sealing, embedded electronics, closed-loop propulsion control, and experimental underwater validation.

> **Status:** Completed academic team project  
> **Team:** Abdelrhman Amgad, Ahmed Mounir, Giulia Di Sipio, Tony Al Helou, Jessica Dichakdjian  
> **Course:** Bioinspired Robotics Lab, Politecnico di Milano  
> **Academic Year:** 2025–2026

---

## At a Glance

| | |
|---|---|
| **Robot type** | Bioinspired robotic fish |
| **Biological inspiration** | Atlantic mackerel |
| **Locomotion** | Body-Caudal Fin (BCF), carangiform |
| **Main propulsion** | Single DC motor driving segmented tail |
| **Steering** | Servo-actuated head |
| **Control** | Arduino-based closed-loop propulsion + head stabilization |
| **Sensors** | Motor encoder + MPU-9250 IMU |
| **Manufacturing** | 3D printing, bent steel shaft, silicone molding |
| **Waterproofing** | Silicone sleeve, sealing, enclosed electronics |
| **Validation** | Dry motion, sealing, buoyancy, thrust and in-water swimming |
| **Final demonstrated speed** | 0.33 m/s at 1.5 Hz |

---

# Project Overview

The goal of PHOENIX was to design and fabricate a **waterproof, buoyant robotic fish capable of sustained straight-line swimming**, inspired by the high-speed and efficient propulsion of the Atlantic mackerel.

The robot uses **carangiform locomotion**, where most of the body remains relatively rigid while oscillation is concentrated in the posterior section and caudal fin.

The overall development process included:

```text
Biological Study
      ↓
Kinematic & Dynamic Modelling
      ↓
Mechanical Design
      ↓
CAD & Component Selection
      ↓
Manufacturing
      ↓
Electronics & Control
      ↓
Waterproofing & Buoyancy
      ↓
Experimental Validation
```

The final prototype successfully achieved forward swimming in water and demonstrated the integration of the mechanical, electronic and control subsystems.

---

# My Contributions

This was a **five-person team project**.

My work focused primarily on mechanical design, fabrication, integration and testing.

## Mechanical Design

I contributed to the CAD and mechanical design of the **tail mechanism**, including the segmented structure responsible for reproducing the required oscillatory motion.

I also worked directly on the main propulsion mechanism and its physical implementation.

## Manufacturing & Prototyping

My hands-on contributions included:

- 3D printing robot components
- mechanical assembly
- silicone molding
- manual shaft bending
- integration of the tail mechanism
- sealing and waterproofing work
- iterative prototype assembly

## Electronics & Component Integration

I contributed to component selection and integration, particularly identifying electronic components that were:

- compact enough to fit inside the robot body
- sufficiently powerful for underwater operation
- compatible with the available internal volume
- suitable for the required propulsion performance

I also assisted with general electronics and hardware integration.

## Testing

I participated in the experimental validation of the complete system, including:

- dry tail-motion tests
- waterproofing checks
- buoyancy tests
- in-water propulsion tests
- thrust testing
- final swimming validation

The control software and electronics were developed collaboratively by the team. Repository code is therefore presented as **team project code**, not as a claim of sole individual authorship.

---

# Biological Inspiration

PHOENIX was inspired by the **Atlantic mackerel**, selected for its efficient high-speed swimming.

The robot reproduces a simplified form of **Body-Caudal Fin carangiform locomotion**.

In this mode:

- most body deformation occurs in the rear section
- the tail generates a travelling lateral wave
- the caudal fin produces the dominant propulsive force
- passive fins improve stability
- the head can be actively adjusted for steering

---

# Mechanical Architecture

The robot structure consists of:

```text
Head
  ↓
Rigid Main Body
  ↓
Segmented Tail
  ↓
Active Tail Link
  ↓
Rigid Caudal Fin
```

The morphology was simplified from the biological fish to preserve the essential locomotion behaviour while keeping the mechanism manufacturable.

The robot contains:

- rigid central electronics compartment
- segmented tail links
- active tail drive
- rigid caudal fin
- passive stabilizing fins
- independently actuated head

---

# Tail Actuation Mechanism

The propulsion system uses a modified **Scotch-yoke / bent-shaft mechanism**.

```text
DC Motor Rotation
      ↓
Bent Shaft
      ↓
Oscillatory Link Motion
      ↓
Segmented Tail Motion
      ↓
Caudal-Fin Propulsion
```

A single actuator converts continuous motor rotation into lateral tail oscillation.

Mechanical stops and shaft geometry were used to control the angular range of the tail links.

The architecture provides:

- high tail-beat frequency
- harmonic oscillation
- single-actuator propulsion
- adjustable oscillation amplitude

---

# Head Steering

The head is driven independently using a servo motor.

The purpose of the head mechanism is to:

- correct heading drift
- improve straight-line swimming
- provide active steering capability

The servo receives orientation feedback from the IMU through the stabilization control loop.

---

# Fin Design

The fins were designed using streamlined airfoil-inspired profiles.

The main fin set includes:

- caudal fin
- dorsal fin
- anal fin
- two lateral fins

The **caudal fin** is responsible for primary thrust generation.

The remaining fins mainly improve passive stability and reduce roll/yaw during swimming.

---

# Materials

| Material | Application |
|---|---|
| PLA | Outer body and fins |
| ABS | Motor supports |
| Low-carbon steel | Bent drive shaft |
| Carbon fiber | Internal spar |
| Brass | Motor coupling |
| Ecoflex 00-10 | Tail and neck silicone sleeves |
| Elastic latex membrane | Additional waterproofing |

Material selection balanced:

- stiffness
- manufacturability
- waterproofing
- mass
- structural strength
- compliance

---

# Manufacturing

The prototype was manufactured using a combination of additive manufacturing and manual fabrication.

The process included:

```text
CAD Design
    ↓
3D Printing
    ↓
Silicone Mold Printing
    ↓
Ecoflex Casting
    ↓
Steel Shaft Bending
    ↓
Mechanical Assembly
    ↓
Electronics Integration
    ↓
Waterproofing
```

Key manufactured components included:

- rigid body sections
- tail links
- fins
- silicone tail sleeve
- silicone neck sleeve
- motor supports
- bent drive shaft

---

# Waterproofing Strategy

Waterproofing was critical because the electronics and propulsion system operate fully submerged.

The design used:

- sealed rigid body sections
- silicone sleeves
- silicone adhesive
- protected cable/motor interfaces
- enclosed electronics compartment
- iterative leak testing

Validation was carried out in stages before propulsion testing.

---

# Buoyancy

The robot was designed to approach neutral buoyancy.

Buoyancy tuning considered:

- internal air volume
- component mass
- robot body volume
- ballast placement

Small steel ballast masses were used during physical tuning.

---

# Electronics

The robot uses an embedded Arduino-based control architecture.

Main components include:

- Arduino Nano
- brushed DC geared motor with encoder
- DRV8871 motor driver
- MPU-9250 IMU
- steering servo
- battery
- Hall-effect / magnetic user input

The propulsion motor selected for the final system was:

```text
ChiHai CHR-GM25-370ABHL
12 V brushed DC geared motor
Integrated incremental encoder
350 RPM rated speed
```

---

# Software Architecture

The embedded software is divided into several functional modules:

```text
Mode Manager
     ↓
Propulsion Controller
     ↓
Motor Driver
     ↓
DC Motor

Encoder Feedback
     ↑
PID Speed Control


IMU Feedback
     ↓
Drift Estimation
     ↓
Servo Head Correction
```

The control system includes:

- normal swimming mode
- fast swimming mode
- soft-start motor ramp
- motor-speed PID control
- encoder feedback
- IMU gyro feedback
- head stabilization
- magnetic user interface

---

# Operating Modes

A finite-state machine manages robot operation.

```text
OFF
 ↓
LOAD NORMAL
 ↓
NORMAL SWIM

or

OFF
 ↓
LOAD FAST
 ↓
FAST SWIM
```

A magnetic sensor provides a waterproof external user interface.

Short and long magnetic interactions are used to change robot states without mechanical buttons penetrating the hull.

---

# Closed-Loop Propulsion Control

Motor speed is controlled using encoder feedback.

```text
Target Frequency
      ↓
Soft-Start Ramp
      ↓
PID Controller
      ↓
PWM Command
      ↓
Motor Driver
      ↓
DC Motor
      ↑
Encoder Feedback
```

The system supports two primary operating points:

- normal swimming: approximately **1.5 Hz**
- fast swimming: approximately **3.0 Hz**

---

# Head Stabilization

Body rotation is measured using the MPU-9250 IMU.

```text
IMU Gyroscope
      ↓
Drift Estimate
      ↓
Servo Mapping
      ↓
Head Correction
```

The propulsion and stabilization loops operate independently.

---

# Kinematics & Hydrodynamic Modelling

The robot was modelled as a rigid body with a segmented multi-link tail.

The analysis included:

- prescribed joint motion
- tail centerline reconstruction
- tail geometry approximation
- hydrodynamic thrust estimation
- power estimation
- propulsive efficiency
- motor sizing

A Lighthill-type elongated-body / added-mass model was used to estimate tail-generated hydrodynamic forces.

These results were used as inputs for actuator sizing and design decisions.

---

# Motor Sizing

Motor requirements were derived from:

- hydrodynamic power
- hydrodynamic torque
- mechanical losses
- silicone deformation losses
- safety margin

The model estimated the required propulsion actuator capacity before final motor selection.

---

# Testing & Validation

Validation was performed progressively.

---

## Dry Motion Test

The first test verified:

- motor-driven tail motion
- linkage operation inside the silicone sleeve
- normal mode
- fast mode
- servo/head response

The expected oscillatory tail motion was successfully produced in air.

---

## Waterproofing & Buoyancy Test

Before powered swimming, the robot was immersed to verify:

- sealed electronics
- sleeve integrity
- stable flotation
- absence of visible leaks

The prototype passed the initial immersion check.

---

## Initial In-Water Trial

The first swimming trial was performed without the final stabilizing fins.

The robot produced forward motion, but directional stability was limited.

This test motivated the addition of passive fins to reduce roll and yaw.

---

# Experimental Thrust Test

Experimental thrust was measured using a load-cell setup and compared with theoretical predictions.

At 1.5 Hz:

```text
Theoretical peak hydrodynamic thrust ≈ 1.20 N
Experimental peak dynamic load      ≈ 1.38 N
Difference                          ≈ 15%
```

The difference reflects effects not fully captured by the ideal model, including:

- tail inertia
- linkage losses
- turbulence
- flexibility
- non-ideal tail motion

---

# Final Swimming Test

The final prototype was tested in water with the completed mechanical and stabilization configuration.

At:

```text
Tail frequency: 1.5 Hz
```

the robot achieved:

```text
Swimming speed: 0.33 m/s
Body-length-normalized speed: 0.73 BL/s
```

The final test demonstrated successful integration of:

- propulsion
- mechanical transmission
- waterproofing
- electronics
- control
- passive stability
- head steering

---

# Repository Structure

```text
PHOENIX/
│
├── README.md
│
├── PHOENIX_Code.ino
│
├── PHOENIX cad/
│   └── Final robot CAD
│
├── 2026 cad/
│   └── Archived design iterations
│
├── Software_Used_During_Testing/
│   ├── motor tests
│   ├── encoder tests
│   ├── IMU calibration
│   ├── servo tests
│   └── diagnostic scripts
│
├── dynamics/
│   └── MATLAB modelling and simulation
│
└── media/
    └── testing and swimming demonstrations
```

---

# CAD Navigation

## `PHOENIX cad/`

Contains the **final design** used for the working prototype.

This includes the final:

- waterproof body
- tail mechanism
- motor supports
- fins
- steering head
- assembly geometry

## `2026 cad/`

Contains earlier design iterations and failed prototypes.

These files are intentionally retained because they document the engineering iteration process, including changes related to:

- friction
- waterproofing
- manufacturability
- mechanism geometry
- assembly access

---

# Code Navigation

## `PHOENIX_Code.ino`

Final integrated Arduino control software.

It includes:

- propulsion logic
- PID speed control
- encoder feedback
- IMU input
- head stabilization
- operating-mode state machine
- soft-start behaviour

Required Arduino libraries include:

```text
MPU9250_asukiaaa
util/atomic.h
```

## `Software_Used_During_Testing/`

Development and diagnostic code used during integration.

Examples include:

- DC motor tests
- encoder tests
- IMU calibration
- servo tests
- subsystem diagnostics

These files are retained to show the testing process rather than only the final working code.

---

# Engineering Iteration

One important part of this project was the iterative development process.

Earlier versions encountered problems involving:

- friction
- sealing
- assembly access
- directional stability
- mechanical integration

The archived CAD and testing software are retained to document how the design evolved toward the final working system.

---

# Limitations

The prototype successfully achieved its primary objective, but several limitations remain:

- straight-line control is still relatively simple
- swimming tests were conducted in a controlled environment
- hydrodynamic modelling uses simplifying assumptions
- tail flexibility and turbulence are difficult to model precisely
- active steering capability could be extended
- long-duration waterproofing was not fully characterized
- full autonomous navigation was outside the project scope

---

# Future Work

Potential improvements include:

- vision-based navigation
- closed-loop trajectory control
- depth control
- improved hydrodynamic modelling
- optimized tail geometry
- improved energy efficiency
- autonomous underwater navigation
- longer-duration endurance testing

---

# Skills Demonstrated

This project provides evidence of experience in:

- bioinspired robotics
- underwater robotics
- robotic locomotion
- mechatronics
- mechanical design
- CAD
- 3D printing
- compliant mechanisms
- silicone molding
- waterproofing
- electromechanical integration
- actuator selection
- embedded electronics
- Arduino
- PID control
- encoder feedback
- IMU sensing
- servo control
- MATLAB
- dynamics modelling
- hydrodynamic modelling
- motor sizing
- experimental validation
- thrust measurement
- iterative prototyping

---

# Team Work & Attribution

PHOENIX was developed as a **five-person academic team project**.

The complete robot, software, CAD and experimental system were developed collaboratively.

My main contributions were concentrated in:

- tail mechanical CAD and design
- propulsion mechanism development
- 3D printing
- mechanical assembly
- silicone molding
- shaft bending
- waterproofing and sealing
- electronics/component selection and packaging
- system integration
- experimental testing

Repository software and system-level design are presented as team work unless explicitly identified otherwise.

---

# Project Status

✅ **Completed functional underwater robotic prototype**

The final system successfully demonstrated:

- waterproof operation
- buoyant deployment
- oscillatory tail propulsion
- closed-loop motor-speed control
- active head stabilization
- measurable thrust
- straight-line swimming in water
