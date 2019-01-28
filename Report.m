Nick Balelo

A14689954

# Lab 1

## Introduction
*In this lab we combine our pushbutton BLE communications our OLED Display function and communicate to a receiver wirelessly. *

## Objective 1
*1. AT commands *

*2. A voltage divider is used to establish a steady voltage of 3.3 V and is then applied to the Bluetooth via breadboard.



*Sample code is provided and tested as well as atcommands through the serial monitor



*Role and IMME are set to 1 Baud rate set to 0 with at commands 



*I experienced a hardware issue with the Bluetooth I was given and had to change serials. 

*CODE BLOCK

```c

#include <AltSoftSerial.h>
AltSoftSerial BTserial; 
 
char c=' ';
boolean NL = true;
 
void setup()
{
  Serial.begin(9600);
  while(!Serial){};
  BTserial.begin(9600);  
  Serial.println("BTserial started");
}

void loop()
{
  // Read from the Bluetooth module and send to the Arduino Serial Monitor
  if (BTserial.available())
  {
        c = BTserial.read();
        Serial.write(c);
  }
  
  // Read from the Serial Monitor and send to the Bluetooth module
  if (Serial.available())
  {
        c = Serial.read();
 
        // do not send line end characters to the HM-10
        if (c!=10 & c!=13 )
        {  
            BTserial.write(c);
        }
 
        // Copy the user input to the main window, as well as the Bluetooth module
        // If there is a new line print the ">" character.
        if (NL) {
          Serial.print("\r\n>");
          NL = false;
        }
        Serial.write(c);
        if (c==10) {
          NL = true;
        }
  }
}
```


Add relevant [links](https://guides.github.com/features/mastering-markdown/)

Add any required images.

![GitHub Logo](Images/python.png)

![GitHub Logo](https://github.com/UCSD-Product-Engineering/ece16-winter19- NickBalelo\lab3\obj1\Objective1)



## Objective 2A
*BLE*

*Being given the test code we are to connect to another persons Bluetooth.

*We were to switch roles as master and slave.

*First role as master

![GitHub Logo](https://github.com/UCSD-Product-Engineering/ece16-winter19- NickBalelo\lab3\obj2\Objective2a)

## Objective 2B
*Follow instructions given to solder The Protoboard as indicated

*Switch to role as slave

![GitHub Logo](https://github.com/UCSD-Product-Engineering/ece16-winter19- NickBalelo\lab3\obj2\Objective2b)

## Objective 3
*Computer to BLE*

*Test the connection between the serial cable and insured drivers are installed for the ic 



*Hook up the cable pans to the Bluetooth pins.



*Use the sample code to ensure everything is working.



*Modify the code slightly and try to understand what the sample code is doing and how it is communicating. 

*CODE BLOCK 
```python
import serial, sys
from time import sleep

def read_BLE( ser ):
    msg = ""
    if( ser.in_waiting > 0 ):
            msg = ser.readline( ser.in_waiting ).decode('utf-8')
    return msg

def write_BLE( command, ser ):
    ser.write( command.encode("utf-8") )
    return


with serial.Serial(port='COM5', baudrate=9600, timeout=1) as ser:
    while(True) :
        
            command = input("Either (1) hit ENTER to read BLE, (2) send an AT command, or (3) press q to exit: ")

            if( command == "") :
                print( "> " + read_BLE(ser) )

            elif (command == 'q' or command == 'Q'):
                print("Goodbye")
                sys.exit(0)

            else:
                   write_BLE( command, ser )
                   sleep(0.5) # wait for a response
                   print( "> " + read_BLE(ser) )
```



## Objective 4
*Integration*

*In this objective we integrate our old button code with the display code and now introduce the Bluetooth into the loop.



*Some new functions are introduced in the code that are called upon that integrate the screen and button functions and the Bluetooth is set in the loop.



*Python code from objective three and four are identical

```c

//Button Stopwatch
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include <AltSoftSerial.h>

#define Button 4
AltSoftSerial BTserial;
Adafruit_SSD1306 display(128, 32, &Wire, -1); 

char a = '\0';
bool NL = true;
bool Sleep = 0;
bool button = 0;
String m1, m2, m3 = "";



void setup() {
  // put your setup code here, to run once:

  Serial.begin(9600);
  pinMode(Button, INPUT_PULLUP);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  BTserial.begin(9600);
  swrite("BTserial started.");
  delay(50);

}

void loop() {
  // put your main code here, to run repeatedly:

  if (!Sleep)
  {
    if (BTserial.available()) 
    swrite(BLE());
    
   if (Serial.available()) readMon();
    
  }

    onOff();  

}


void swrite(String out)
{

 display.clearDisplay();
 display.setCursor(0,0);

 if (m1 != "") display.println(m1);
  if (m2 != "") display.println(m2);
 if (m3 != "") display.println(m3);

display.println(out);
 display.display();

 m1 = m2;
 m2 = m3;
 m3 = out;
  
  Serial.println(out);  
  
  }

String BLE()
{
  
  String out;
  delay(50);
  while (BTserial.available())
  {
    a= BTserial.read();
    out += a;
    
    }

    return out; 
  
  }

void readMon()
{
  String out = "";

  while (Serial.available()){
    
    a = Serial.read();
    if (a!=10 & a!=13)
    out += a;

    if(NL){
      
      Serial.print("\r\n>");
      NL= false;      
      }

      Serial.write(a);
      if (a==10)
      NL=true;
    
    }
  
  BTserial.print(out);  
  }



  void onOff(){
    
    if (digitalRead(button) == HIGH)
    button = 0;

    else if ((digitalRead(button) == LOW) && (button == 0)){
      
      button = 1;
      Sleep = !Sleep;
      if (Sleep == 0)
      wake();

      else if (Sleep == 1)
      sleep();
      
      }    
    
    }


    void wake(){
      
      swrite("Exiting Sleep Mode.");

      BTserial.write("Quotes");

      swrite(BLE());

      BTserial.write("AT+ADVI9");
      BTserial.write("AT+ADTY0");
      BTserial.write("AT+POWE2");
      BTserial.write("AT+RESET");      
      }

      void sleep(){
        
       swrite("Entering Sleep Mode.");

       swrite(BLE());

             
      BTserial.write("AT+ADVIF");
      BTserial.write("AT+ADTY1");
      BTserial.write("AT+POWE0");
      BTserial.write("AT+RESET");
      BTserial.write("AT+SLEEP");
        
        
        }

    ```

[GitHub Logo](https://github.com/UCSD-Product-Engineering/ece16-winter19- NickBalelo\lab3\Video\Obj4vid.MOV)


## Conclusion
*In this lab we were able to bring everything together from the last lab as well as a new addition in the Bluetooth. We were introduced to yet another form of communication and the roles they might play. We also move forward in our understanding of both the Arduino code and python code as well as gaining new knowledge of AT commands.*
