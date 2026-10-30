# 📋 About

This repository contains Lua scripts for Stormworks. Most microcontrollers are built around a vector library — a set of functions for 3D math: vectors, rotation matrices, Euler angles, and conversion between local and global coordinate systems.

Main areas:

* Mission scripts — game logic, triggers, object behavior.

* Microcontrollers — navigation, target tracking, radar, stabilization, etc.

* Vector math — utilities for 3D computations.




# ⚠️ About code origin

Part of the code was written with the help of AI and then adapted/verified manually. This is not hidden — the repository is intended as a working playground and a way to share work with the Stormworks community.



# 🚀 Usage
1. Copy the .lua file into the game:
* Microcontroller — via the controller editor (Lua script).
* Mission — via the Stormworks mission editor.

2. Make sure helper functions are included (in some scripts they are embedded at the top of the file).

3. Configure inputs/outputs for your task (input.getNumber / output.setNumber).
