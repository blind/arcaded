# Arcaded
Building myself an arcade stick to support different types of consoles/computers. The plan is to find a fitting micro controller (with enough GPIO pin) to handle the interface with the different machines.

## Machines
These are the machines I want to support.

* * *

### Mega Drive
This will be the base machine I will use for testing, I want to support it fully.

The 6 button mode will be 
#### Buttons

 * 4 direction
 * 3+3 action buttons (A,B,C and X,Y,Z for 6 button controller support)
 * Start button
 * Mode button on 6 button controller

Total number of buttons: 10

#### Port

 * 6 data out
 * 1 data in
 * +5V
 * Ground

#### Protocol
See:
 * http://applause.elfmimi.jp/md6bpad-e.html
 * http://www.cs.cmu.edu/~chuck/infopg/segasix.txt

* * *

### Master System

#### Buttons
 * 4 directions
 * 2 action buttons

Total number of buttons: 6

* * *

### Super Nintendo
Support for this is far of in the future.

#### Buttons
 * 4 directions
 * 4 action buttons (A,B,X,Y)
 * 2 shoulder buttons (L,R)
 * Start button
 * Select button
 
Total number of buttons: 10

* * *


### Atari ST

#### Buttons
 * 4 directions
 * 1 action button

Total number of buttons: 5
