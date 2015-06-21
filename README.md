# Arcaded
Building myself an arcade stick to support different types of consoles/computers. Right now it's using a Arduino nano to interface with the consoles.

## Machines
These are the machines I want to support.

Information on their interfaces can be found at http://gamesx.com/wiki/doku.php?do=index&id=controls


### Mega Drive
This will be the base machine I will use for testing, I want to support it fully.

#### Buttons

 * 4 direction
 * 3+3 action buttons (A,B,C and X,Y,Z for 6 button controller support)
 * Start button
 * Mode button on 6 button controller

Total number of buttons: 12

#### Port

 * 6 data out
 * 1 data in
 * +5V
 * Ground

#### Protocol
See:
 * http://applause.elfmimi.jp/md6bpad-e.html
 * http://www.cs.cmu.edu/~chuck/infopg/segasix.txt

#### Cable
I'm using the cable from a broken Mega Drive controller. Here are the wire color to pin mapping on this specific cable I'm using.

 * Brown  - UP
 * Red    - DOWN
 * Green  - +5V
 * Gray   - TH
 * Orange - Left
 * Yellow - Right
 * Black  - Ground
 * White  - Start/C
 * Blue   - A/B

### Master System

#### Buttons
 * 4 directions
 * 2 action buttons

Total number of buttons: 6



### Super Nintendo
Support for this is far of in the future.
The NES and SNES controller uses a serial protocol to read controllers. I hope the arduino is fast enough for that as well, or this will be a rather boring project.
#### Buttons
 * 4 directions
 * 4 action buttons (A,B,X,Y)
 * 2 shoulder buttons (L,R)
 * Start button
 * Select button
 
Total number of buttons: 12



### Atari ST/Amiga

It seems the Atari ST and Sega Master System controllers are compatible, except the Master System having +5V at pin 5 instead of pin 7.

#### Buttons
 * 4 directions
 * 1 action button

Total number of buttons: 5



## Controller hardware

The plan is to use an Arduino nano for reading input and communicating with the different consoles. There will be atleast 12 pins required for the inputs (4 directions, 6 action buttons and Start + mode/select), 


The number of required pins for output differentiate between platforms. The Mega Drive requires 6 data pins, the Super Nintendo only have 3 data pins. 

Two of the IO-pins on the Arduino nano can trigger interrupts, so preferably these should be used for input from the hardware, especially for SNES/NES and Mega Drive.

## References
 * http://deskthority.net/wiki/Atari_interface
 * http://applause.elfmimi.jp/md6bpad-e.html
 * http://www.cs.cmu.edu/~chuck/infopg/segasix.txt
 * http://gamesx.com/wiki/doku.php?do=index&id=controls


