
#define PIN_IN_UP  A0
#define PIN_IN_DOWN  A1
#define PIN_IN_LEFT  A2
#define PIN_IN_RIGHT  A3
#define PIN_IN_BTN_A  A4
#define PIN_IN_BTN_B  A5
#define PIN_IN_BTN_C  A6
#define PIN_IN_BTN_X  A7
#define PIN_IN_BTN_Y  13
#define PIN_IN_BTN_Z  12
#define PIN_IN_BTN_START  11
#define PIN_IN_BTN_MODE  10


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

#define INPUT_COUNT 12


// Mega drive conector GPIO pins
#define MD_PIN_UP         8
#define MD_PIN_DOWN       7
#define MD_PIN_0_LEFT     6
#define MD_PIN_0_RIGHT    5
#define MD_PIN_START_C    4
#define MD_PIN_A_B        3

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

static void setupMegaDriveMode(void)
{
  // Input pin
  pinMode(MD_PIN_TH,INPUT);

  // Output pins
  pinMode(MD_PIN_UP,OUTPUT);
  pinMode(MD_PIN_DOWN,OUTPUT);
  pinMode(MD_PIN_0_LEFT,OUTPUT);
  pinMode(MD_PIN_0_RIGHT,OUTPUT);
  pinMode(MD_PIN_A_B,OUTPUT);
  pinMode(MD_PIN_START_C,OUTPUT);

}

static void md_outputTH0()
{
  // TODO: output 1CBRLDU
  digitalWrite(MD_PIN_A_B,inputs[5]);
  digitalWrite(MD_PIN_START_C,inputs[6]);
  digitalWrite(MD_PIN_0_RIGHT, inputs[3]);
  digitalWrite(MD_PIN_0_LEFT, inputs[2]);
  digitalWrite(MD_PIN_UP, inputs[0]);
  digitalWrite(MD_PIN_DOWN, inputs[1]);
 // digitalWrite(MD_PIN_A_B, inputs[PIN_IN_BTN_B]);

}

static void md_outputTH1()
{
  // TODO:output StartA00DU
  digitalWrite( MD_PIN_A_B, inputs[PIN_IN_BTN_A]);
  digitalWrite( MD_PIN_START_C, inputs[PIN_IN_BTN_START]);
  digitalWrite( MD_PIN_0_RIGHT, 0);
  digitalWrite( MD_PIN_0_LEFT, 0);
  digitalWrite( MD_PIN_UP, inputs[PIN_IN_UP]);
  digitalWrite( MD_PIN_DOWN, inputs[PIN_IN_DOWN]);
}

static void ISR_megaDriveTH(void)
{
  if(digitalRead(MD_PIN_TH))
  {
    md_outputTH1();
  }
  else
  {
    md_outputTH0();
  }
}


static void runMegaDrive(void)
{
  // Everything Mega drive specific
  // should be handled by interrupts.

  // This is only for testing.
  md_outputTH0();
}



