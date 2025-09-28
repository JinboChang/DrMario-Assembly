# Dr. Mario Assembly Game

A complete implementation of the classic Dr. Mario puzzle game written in MIPS Assembly language for the CSC258H1 Computer Organization course.

## 📖 Project Overview

This project is a faithful recreation of the classic Nintendo Dr. Mario game, implemented entirely in MIPS Assembly language. The game features falling capsules that players must arrange to eliminate viruses, complete with gravity mechanics, collision detection, and background music.

**Author:** Jinbo Chang 
**Institution:** University of Toronto

## 🎮 Game Features

### Core Gameplay
- **Falling Capsules**: Two-colored pills that fall from the top of the bottle
- **Rotation Mechanics**: Capsules can be rotated between horizontal and vertical orientations
- **Movement Controls**: Left, right, and fast-drop movement
- **Collision Detection**: Sophisticated collision system for bottle walls and existing capsules
- **Gravity System**: Progressive gravity that increases speed as more pills are placed

### Visual Features
- **32x32 Grid Display**: Optimized for 64x64 pixel bitmap display
- **Color System**: Three-color capsule system (Red, Blue, Yellow)
- **Ghost Outline**: Preview showing where the current capsule will land
- **Next Capsule Preview**: Shows the next capsule to be played
- **Bottle Visualization**: Accurate Dr. Mario bottle shape with neck and main chamber

### Audio Features
- **Background Music**: 4-note theme that loops continuously
- **MIDI Sound System**: Uses MIPS MIDI syscalls for audio output

### Game Mechanics
- **Progressive Difficulty**: Gravity speed increases with each placed capsule
- **Pause Functionality**: Game can be paused and resumed
- **Random Generation**: Pseudo-random capsule colors and orientations

## 🕹️ Controls

| Key | Action |
|-----|--------|
| `A` | Move capsule left |
| `D` | Move capsule right |
| `S` | Fast drop (accelerated downward movement) |
| `W` | Rotate capsule (horizontal ↔ vertical) |
| `P` | Pause/Resume game |
| `Q` | Quit game |

## 🖥️ Technical Specifications

### Display Configuration
- **Unit Width/Height**: 2 pixels each
- **Display Resolution**: 64x64 pixels
- **Base Address**: `0x10008000` ($gp register)
- **Color Depth**: 32-bit RGB values

### Memory Layout
- **Keyboard Address**: `0xffff0000`
- **Display Address**: `0x10008000`
- **Color Palette**: 
  - Red: `0xFF0000`
  - Blue: `0x0000FF`
  - Yellow: `0xFFFF00`

### Game Grid
- **Bottle Dimensions**: 20 units wide × 20 units tall (main chamber)
- **Neck Dimensions**: 10 units wide × 6 units tall
- **Total Play Area**: Accommodates standard Dr. Mario bottle shape

## 🏗️ Code Architecture

### Main Components

#### Core Game Loop (`main` & `game_loop`)
- Handles keyboard input polling
- Updates game state
- Manages frame timing (16ms per frame)
- Controls music playback

#### Graphics System
- **`clear_screen`**: Efficient full-screen clearing
- **`draw_bottle`**: Renders the game bottle outline
- **`draw_pill`**: Renders the current falling capsule
- **`draw_outline`**: Shows ghost/preview of capsule landing position
- **`draw_next_capsule`**: Displays next capsule preview
- **Line Drawing Functions**: Optimized horizontal and vertical line rendering

#### Physics Engine
- **`move_down`**: Gravity and collision detection
- **`move_left`/`move_right`**: Horizontal movement with boundary checking
- **`rotate`**: Capsule rotation with collision validation
- **Collision Detection**: Sophisticated system handling bottle boundaries and placed capsules

#### Game State Management
- **`pill_lock`**: Handles capsule placement and game state updates
- **`generate_random_colors`**: Pseudo-random capsule generation
- **`generate_random_next`**: Next capsule preparation

#### Audio System
- **`play_next_note`**: MIDI-based background music system
- **Music Timer**: Synchronizes music with game loop

#### User Interface
- **`handle_pause`**: Pause/resume functionality with visual feedback
- **`draw_pause_message`**: Pause state visualization

## 🔧 Assembly Programming Techniques

### Advanced MIPS Features Used
- **Memory-mapped I/O**: Direct manipulation of display buffer
- **Interrupt Polling**: Keyboard input handling
- **Stack Management**: Proper function call conventions
- **Register Optimization**: Efficient use of temporary and saved registers
- **System Calls**: MIDI audio and timing syscalls

### Performance Optimizations
- **Efficient Pixel Addressing**: Optimized coordinate-to-address calculations
- **Minimal Memory Allocation**: Strategic use of static data
- **Loop Optimization**: Reduced instruction count in critical paths
- **Frame Rate Control**: Consistent 60 FPS targeting

## 🚀 Running the Game

### Prerequisites
- MIPS simulator (MARS, SPIM, or similar)
- Bitmap Display tool configured to:
  - Base address: `0x10008000`
  - Unit width/height: 2 pixels
  - Display dimensions: 64×64 pixels
- Keyboard and Display MMIO tool

### Setup Instructions
1. Load `DrMario.asm` in your MIPS simulator
2. Configure the Bitmap Display with the specifications above
3. Connect the Keyboard and Display MMIO tool
4. Assemble and run the program
5. Focus on the display window to ensure keyboard input is captured

## 📁 Project Structure

```
CSC258H1 Project/
├── DrMario.asm           # Main game implementation
├── project-report.pdf    # Detailed project documentation
├── project-report.tex    # LaTeX source for report
└── README.md            # This file
```

## 🎯 Educational Objectives Achieved

### Assembly Language Mastery
- **Low-level Programming**: Direct hardware manipulation
- **Memory Management**: Efficient data structure usage
- **Algorithm Implementation**: Game logic in assembly
- **Optimization Techniques**: Performance-critical code optimization

### Computer Organization Concepts
- **Memory Hierarchy**: Understanding of display buffer management
- **I/O Systems**: Keyboard and display interfacing
- **Instruction Set Architecture**: Comprehensive MIPS instruction usage
- **System Integration**: Combining multiple hardware components

## 🐛 Known Limitations

- **Virus System**: Current implementation focuses on capsule mechanics (virus elimination system not fully implemented)
- **Line Clearing**: Horizontal/vertical line detection and clearing system pending
- **Score System**: Scoring mechanism not implemented
- **Game Over**: Win/lose conditions not fully implemented

## 🔮 Future Enhancements

- Complete virus elimination logic
- Implement line-clearing algorithm
- Add scoring system with high score tracking
- Enhanced visual effects and animations
- Multiple difficulty levels
- Sound effects for game events

## 📜 Academic Integrity Statement

This code represents entirely original work created for the CSC258H1 course. All implementation details, algorithms, and optimizations are the result of independent research and development. External resources consulted are limited to official MIPS documentation and course materials.

## 📞 Contact

**Jinbo Chang**  
Student ID: 1004821419  
University of Toronto  

---

*This project demonstrates advanced assembly language programming skills and deep understanding of computer organization principles through the implementation of a complete interactive game system.*
