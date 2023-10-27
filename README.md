# ASM-Tetris
This project was created with 2 of my Computer Science classmates ([@tomimara52](https://github.com/tomimara52), [@tpeyronel](https://github.com/tpeyronel)) as an assignment for the subject Computer Organization.
Complete **[Tetris](https://tetris.com/play-tetris)** replica written in Assembly Language and emulated in a Raspberry Pi 3b using **[QEMU](https://www.qemu.org/)**.

Play with ```` make runSGPIOM ```` in one terminal and ```` make runQEMU ```` in a different one.

The game IS resizeable and you can play in anything from a 4x4 board to a 50x50 board or different rectangles. Re-size it by changing the BOARD_WIDTH and BOARD_HEIGHT constants in the app.s file.

``W`` : Rotate     \
``D`` : Move Right \
``A`` : Move Left  \
``S`` : Hard Drop  \
``SPACE`` : Restart

<ins>Note:</ins> key bindings can be customized by modifying bin/config.json

https://github.com/achaval-tomas/ASM-Tetris/assets/134091945/cd0755b6-975a-4ee5-ac81-0244e5e74e99

<ins>**Fun Fact:**</ins> Did you notice our names are **Tomas, Tomas and Tomas?** We handed in this assignment as **TTeTris** for that reason!
