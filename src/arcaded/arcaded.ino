// Using PORT C and PORT D for inputs.

#define PIN_IN_UP  A0
#define PIN_IN_DOWN  A1
#define PIN_IN_LEFT  A2
#define PIN_IN_RIGHT  A3
#define PIN_IN_BTN_A  A4
#define PIN_IN_BTN_B  A5
#define PIN_IN_BTN_C  3
#define PIN_IN_BTN_X  A7
#define PIN_IN_BTN_Y  4
#define PIN_IN_BTN_Z  5
#define PIN_IN_BTN_START  6
#define PIN_IN_BTN_MODE  7


#define IDX_UP    0
#define IDX_DOWN  1
#define IDX_LEFT  2
#define IDX_RIGHT 3
#define IDX_A     4
#define IDX_B     5
#define IDX_C     6
#define IDX_X     7
#define IDX_Y     8
#define IDX_Z     9
#define IDX_START 10
#define IDX_MODE  11


#define IN_MASK_UP    (1u<<0)
#define IN_MASK_DOWN  (1u<<1)
#define IN_MASK_LEFT  (1u<<2)
#define IN_MASK_RIGHT (1u<<3)
#define IN_MASK_A     (1u<<4)
#define IN_MASK_B     (1u<<5)
#define IN_MASK_C     (1u<<6)
#define IN_MASK_X     (1u<<7)
#define IN_MASK_Y     (1u<<8)
#define IN_MASK_Z     (1u<<9)
#define IN_MASK_START (1u<<10)
#define IN_MASK_MODE  (1u<<11)



#define INPUT_COUNT 12


// Mega drive conector GPIO pins
#define MD_PIN_UP         8
#define MD_PIN_DOWN       9
#define MD_PIN_0_LEFT     10
#define MD_PIN_0_RIGHT    11
#define MD_PIN_START_C    12
#define MD_PIN_A_B        13

// Pin 2 can trigger interrupt, so lets use that for TH pin
#define MD_PIN_TH         2



enum hardwaremode_t
{
  EMegaDrive,
  EMasterSystem,
  EAtari16,
  ENES,
  ESNES,
  EAMIGA
};

// Generic functions for all hardware.
static void readInputs(void);
static void setupInput(void);
static hardwaremode_t checkMode(void);

// Mega drive specifics.
static void setupMegaDriveMode(void);
static void runMegaDrive(void);
static void ISR_megaDriveTH(void);

static hardwaremode_t mode = EMegaDrive;


static bool inputs[INPUT_COUNT];

static uint16_t inputBits;


static const int pin_mapping[INPUT_COUNT] = {
                                    PIN_IN_UP,
                                    PIN_IN_DOWN,
                                    PIN_IN_LEFT,
                                    PIN_IN_RIGHT,
                                    PIN_IN_BTN_A,
                                    PIN_IN_BTN_B,
                                    PIN_IN_BTN_C,
                                    PIN_IN_BTN_X,
                                    PIN_IN_BTN_Y,
                                    PIN_IN_BTN_Z,
                                    PIN_IN_BTN_START,
                                    PIN_IN_BTN_MODE
                                };


static void readInputs(void)
{
  bool *inputPtr = inputs;
  const int *pin = pin_mapping;
  for( int i = 0; i < INPUT_COUNT; ++i )
  {
    *inputPtr++ = digitalRead(*pin++);
  }
}

static void setupInput(void)
{
  pinMode(PIN_IN_UP,INPUT_PULLUP);
  pinMode(PIN_IN_DOWN,INPUT_PULLUP);
  pinMode(PIN_IN_LEFT,INPUT_PULLUP);
  pinMode(PIN_IN_RIGHT,INPUT_PULLUP);

  pinMode(PIN_IN_BTN_A,INPUT_PULLUP);
  pinMode(PIN_IN_BTN_B,INPUT_PULLUP);
  pinMode(PIN_IN_BTN_C,INPUT_PULLUP);

  pinMode(PIN_IN_BTN_X,INPUT_PULLUP);
  pinMode(PIN_IN_BTN_Y,INPUT_PULLUP);
  pinMode(PIN_IN_BTN_Z,INPUT_PULLUP);

  pinMode(PIN_IN_BTN_START,INPUT_PULLUP);
  pinMode(PIN_IN_BTN_MODE,INPUT_PULLUP);

  for( int i = 0; i < INPUT_COUNT; ++i )
    inputs[i] = true;
}


static hardwaremode_t checkMode(void)
{
  // Read mode from somewhere. Since we are out of IO-pins, 
  // we might have to use 2 arduinos (or similar), one that handles input
  // and sends state over I2C to the other that handles output.
  return mode;
}

void setup(void)
{
  setupInput();

  // Only use Mega Drive for now.
  setupMegaDriveMode();

}

void loop(void)
{
  // put your main code here, to run repeatedly:
  readInputs();

  switch( mode )
  {
  case EMegaDrive:
    runMegaDrive();
    break;
  default:
    break;
  }


  hardwaremode_t newMode = checkMode();

  if( newMode != mode )
  {
    switch( mode )
    {
    case EMegaDrive:
      break;
    default:
      break;
    }
  }
}



// Mega Drive specific code...
static volatile byte portB_out_TH0 = 0xff;
static volatile byte portB_out_TH1 = 0xff;

static void setupMegaDriveMode(void)
{
  // Input pin
  pinMode(MD_PIN_TH,INPUT);

  // Output pins
  // bit 0-5 of PORT B as outputs.
  DDRB = 0x3F;
}

static inline void md_outputTH0()
{
  PORTB = portB_out_TH0;
}

static inline void md_outputTH1()
{
  PORTB = portB_out_TH1;
}

ISR(PCINT0_vect)
{
  if( PINC & (1u<<PINC2) )
  {
    md_outputTH1();
  }
  else
  {
    md_outputTH0();
  }
}

/*
We must prepare data to be written to ports
in interrupt for timing.

I'm worried that some Mega Drive games read
back the values faster that we have time 
to update the output pins. To minimize the time,
the it takes to change the outputs, the 
values to be written to the pins are prepared in advance.

Pin mapping:

Arduino pin     Atmega port bit
    0           PIND0 rx
    1           PIND1 tx
    2           PIND2
    3           PIND3
    4           PIND4
    5           PIND5
    6           PIND6
    7           PIND7
    8           PINB0
    9           PINB1
    10          PINB2
    11          PINB3
    12          PINB4
    13          PINB5

*/


static void runMegaDrive(void)
{
  byte pb_th0 = 0;
  byte pb_th1 = 0;

  if(inputBits&IN_MASK_UP)      pb_th0 |= 1u;
  if(inputBits&IN_MASK_DOWN)    pb_th0 |= 2u;
  pb_th1 = pb_th0;
  if(inputBits&IN_MASK_A)       pb_th0 |= 16u;
  if(inputBits&IN_MASK_START)   pb_th0 |= 32u;

  if(inputBits&IN_MASK_LEFT)    pb_th1 |= 4u;
  if(inputBits&IN_MASK_RIGHT)   pb_th1 |= 8u;

  if(inputBits&IN_MASK_B)       pb_th1 |= 16u;
  if(inputBits&IN_MASK_C)       pb_th1 |= 32u;

  portB_out_TH0 = pb_th0;
  portB_out_TH1 = pb_th1;

  // This is only for testing.
  md_outputTH0();
}



