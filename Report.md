# _Nick Balelo_
# _A14689954_
# __Lab 4__



## Introduction:
 In this lab we build an IR circuit designed to read a pulse read the signal, filter the signal, send to port both to Python then display it.
 

## Objective 1
__IR HeartBeat Circuit:__
*In this section, we build a physical prototype circuit on a breadboard to and integrate it into our Arduino*
 * __1A: Building the Circuit__
   * Following the circuit layout given we build breadboards 
  
  ![Breadboarded Circuit](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Circuit1A)
   * Be aware of the polarities of the Capacitor, IR transmitter, IR Reciever. 
 * __1A: Reading the Circuit__ 
   
   
   ```c
   #define IRpin (A1)
   void setup() {
     Serial.begin(9600);
   }
   void loop() {
     Serial.println(analogRead(IRpin));
   }
   ```
   ![Pulse Signal](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/SerialPlotter1A)
   
   * Data was extremely choppy and unrefined. Alot of noise was picked up by the reciever.
  
 * __1B: IR Signal Amplification__ 
   * By adding a secondary circuit component based around an OpAmp, we amplify the signal.
   
   ![Breadboarded Amplified IR Circuit](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/OpAmp)
   
*Amplified Signal

![Amplified Signal](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/SerialPlotter1B)
   
   * The reading itself is still choppy and distorted from noise.



## Objective 2
__Digital Filtering & Signal Transformation:__
*In this section, we try to transform and filter to be more easily analyzed.
 * 2A: __Digital Filtering__ with a _Low Pass Filter_
   * The signal we are trying to collect is around 1Hz rate.
   * We use the Arduino Playground's Filters library: and compared a OnePole LPF to a TwoPole LPF. 
   
![Signal before LPF](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Signal1.2B)  
   
 ![Signal after LPF](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Signal2.2B)  
   
   *The transformations I used didnt seem to have any obvious applications other then the LPF
   ```c
   
#include <Filters.h>


// filters out changes faster that 2 Hz.
float filterFrequency = 2.0 ;
float sensorValue; 

// create a one pole (RC) lowpass filter
FilterTwoPole lowpassFilter( LOWPASS, filterFrequency ); 


void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
}






// the loop routine runs over and over again forever:
void loop() {

  sensorValue = lowpassFilter.input( analogRead(A1) );
  // read the input on analog pin 0:

  
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
//  float voltage = sensorValue * (5.0 / 1023.0);
  // print out the value you read:
  Serial.println(sensorValue);
}
   }
   ```
 * 2B: __Digital Transformations__ 
   * Derivative
   
 ![Derivative](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Derivative)  
   
  ```c
  
#include <Filters.h>





// filters out changes faster that 2 Hz.
float filterFrequency = 2.0 ;
float sensorValue; 
float x;

// create a one pole (RC) lowpass filter
FilterTwoPole lowpassFilter( LOWPASS, filterFrequency ); 
FilterDerivative der;

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
}






// the loop routine runs over and over again forever:
void loop() {

 sensorValue = lowpassFilter.input( analogRead(A1) );
 x= der.input(sensorValue);
  // read the input on analog pin 0:

  
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
//  float voltage = sensorValue * (5.0 / 1023.0);
  // print out the value you read:
  Serial.print(sensorValue);
  Serial.print(" ");
  Serial.println(x);
}

```
   * The derivative transformation didnt seem very clear or useful.
   
   * The two other signals I choose were the log function and absolute value. I believe log could have some practical applications in real life however I dont feel the same would be true for the absolute value in this circumstance.*
   
   ![LOG](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Log)  
   
   ![Absolute Value ](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/AbsValue)  

   
   
 

## Objective 3
__IR Placement:__


 * Signal 1: Finger
   *This seems to give the best signal by far.
   
    ![Finger](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/FingerTip)  

   
   
 * Signal 2: Wrist
   *Gives good pulse but not picked up well by the reciever.
   
    ![Wrist](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Wrist)  

   
   
   
 * Signal 3: Lips
   *I picked this because I thought that this area would be well ciculated. It turns out this is also a bad signal.

   ![Lips](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Images/Lips)  



## Objective 4
__Heartbeat Display:__

 * I choose a circle that gets bigger with the amplitude to be displayed on the OLED
 *There are 3 sizes the circle can be. 
 *I was successful in being able to measure the pulse as well as the magnitude of the pulse acurately 
 * I was unable to get 4B to work but attempted for hours.
 
 [Obj 4A video](https://github.com/UCSD-Product-Engineering/ece16-winter19-NickBalelo/tree/master/lab4/Lab4Vid)  

 
 ## Conclusion
This lab was very unstable and hard to get precise data. It was intereting to be introduced to new Arduino Libraires and see different modules and functions. The image processing was also a very interesting part of this lab and I could see it being extremely useful in real world application. Also some more familiarity with the BLE communications as well as some more python experience were used in this lab.
