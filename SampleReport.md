**THE HAMBERDERGULARS**<br/><br/>
**Steven Sharp** - A13232191 <br/>
**Nick Balelo** - A14689954 
# __Lab 6.2__

## Introduction
For this lab, we will be furthering our prior lab 6.2 lessons in Machine Learning: optimizing our heart rate data, live plotting our heart rate data, and user classifications for our heart rate data.

## Objective 1A
__Modularization__<br/>
*For this Objective we begin by making our plot and file storage a streaming collection and processing of active data*
 * Here we implement a file *my_hr_calculator.py* as a library of our previous primary functionalitie:
   * **fit_GMM()**: fitting the GMM file to our training data - from a function call.
   * **predict()**: Make classification/ label predictions on new data - from a function call.
   * **calculate_hr()**: Calculates the heart rates, based on timestamps and labels from the predict function call - as a function call
 ```python
	samplingPeriod = 10             #number of samples per second/ each time tick: 1s/samplingPeriod - can be used as a coefficient
	tr_beats = []    
	Heart_Rate = [0,0,0]
	BPM_Range = 3    
          
	#   Input: data_tr (as 1D array of data),   optional: num_classes() (default:2 - people data trained on)
	#   Output: gmm_fit object
	def fit_GMM(data_tr, num_classes=2):
	    gmm = GM(n_components = num_classes)
	    #***This assumes that data_tr is not processed as needed: previously it was -reshaped- for 2D to process:
	    data_shaped = np.reshape(data_tr,(-1,1))
	    gmm_fit = gmm.fit(data_shaped)
	    return gmm_fit
	
	def predict(gmm_fit, data):    
	    data_shaped = np.reshape(data,(-1,1))    
	    pred_lbl = gmm_fit.predict(data_shaped)
	    # Return the class predictions / labels
	    return pred_lbl

	#   Input:   data: (what kind of data type is data?),   pred_lbl: gmm label data,   data_time: timestamp data for data
	#   Output:  an Array (again: no type/context / formatting) of heart rate data   
	def calculate_hr(data, pred_lbl, data_time):	   
	    global tr_beats, Heart_Rate
	    rising_Edge = False
	    last_Edge = False
	    spike_Counted = False
	    heart_spikes = 0
	    i = 0
	    while (i < len(pred_lbl)):
	        if (pred_lbl[i] == 1):
	            rising_Edge = True
	        else:
	            rising_Edge = False
	            spike_Counted = False
	        if ((data[i] >= 0.17) & (rising_Edge) & (not(last_Edge)) & (not(spike_Counted))):
	            heart_spikes +=1
	            tr_beats.append(data_time[i] - data_time[0])
	            spike_Counted = True
	        elif ((data[i] >= 0.17) & (rising_Edge) & (last_Edge) & (not(spike_Counted))):
	            heart_spikes +=1
	            tr_beats.append(data_time[i] - data_time[0])
	            spike_Counted = True            
	        last_Edge = rising_Edge
	        i+=1
	        
	    tr_bps = heart_spikes / (data_time[len(data_time)-1] - data_time[0]) * samplingPeriod
	    BPM = round(tr_bps*60)
	    bpm = format(BPM, '.0f')
	    Heart_Rate[:BPM_Range-1] = Heart_Rate[1-BPM_Range:]
	    Heart_Rate[BPM_Range-1] = bpm	    
	    return Heart_Rate[BPM_Range-1]
 ```

## Objective 1B
__Live Heart Rate__<br/>
*For this lab, we basically do the rest of the lab workload. We use our **my_hr_calculator.py** as a library to import, collect a series of initial data, process it, filter it, fit it to a gmm object, apply prediction labels and calculate a heart rate- then we loop a continuous loop to do all of those things again with smaller data segments and apply the gmm and prediction data to. Then we create an Arduino file to collect, read, and send all of the data back and forth.*
 * **live_hr_monitor.py**:
   * For this objective we simply couple all of the things we've already done before but with new conditions for operation. Nothing new conceptually, just reworking code from throughout the past 5 labs to fit together.
   * After a few days of rewriting procedures to work with the new contextual Input/Outputs, here are our functions:
   ```python
	def read_Signal(ser):
	    msg = ""
	    while (not msg):
	        msg = read_BLE(ser)
	    print(msg)
	    #Negate possible unproccessable buffer strings from BLE read command: if needed, do other things later on
	    if ((msg.find("OK") >= 0) or (msg.find("AT") >= 0) or (msg.find("CONN") >= 0) or (msg == "")):
	        print("Bad Data(2)! ")
	        ser.flushInput()
	        msg = ""
	        return -1, -1
	    #else: parse expected Data
	    else:
	        time_Data, ir_Data = msg.split('|')
	        if ((time_Data.rstrip('\n') != "") & (ir_Data.rstrip('\n') != "")):
	            time_Data = int(time_Data.rstrip('\n'))
	            ir_Data = int(ir_Data.rstrip('\n'))
	            msg = ""
	            return time_Data ,ir_Data
	        else:            
	            ser.flushInput()
	            msg = ""
	            return -1, -1
	               
	#plot function call for time vs IR data
	#Input: List of Data (x), List of Data (y), string of Title of Y-axis
	#Output: none / a figure plot popup
	def plotStep(TimeData, IR_Data, Label_Data, stringTitle ):
	    plt.figure()
	    #plt.plot(TimeData[0:50],FilteredData[0:50], color="blue", linewidth=1.0, linestyle="-", label='IR Data')
	    plt.plot(TimeData, IR_Data, color="blue", linewidth=1.0, linestyle="-", label=stringTitle)
	    plt.plot(TimeData, Label_Data, color="red", linewidth=0.5, linestyle="-")
	    #plt.ylim(0,1024)                                  
	    #plt.xlim(data_time[0],(data_time[100]))
	    plt.xlim(data_time[0],(data_time[0]+len(data_time)))
	    plt.xlabel('50ms samples')
	    plt.ylabel('Pulse Intensity')
	    plt.title('Pulse Intensity per sample')
	    plt.show()    
	
	#Initialize key variables
	#Input: none
	#Output: none
	def initializeVars():
	    global Data,sampleTotal
	    sampleTotal = (samplingRate * numSeconds)
	    #we can solve a lot of issues and improve readability just by adding one extra cell in our Data generation vector: this allows us to have the vector data we need, and easily reference end of cell.
	    Data = np.zeros((2,sampleTotal+1),dtype=int)
	    
	def initialize_filters(data_ir):
	    fl.setupFilters()    
	      #establish LP_Data as throwaway Data to perform the process as requested/defined in previous lab requests
	    LPF_Data,LPF_Data1,LPF_Data2 = [],[],[]
	    LPF_Data = [fl.adc2voltage(data_ir[0])]
	    LPF_Data1, fl.LP_Zi = fl.applyLPF(fl.LP_b, fl.LP_a, LPF_Data, fl.LP_Zi)
	    LPF_Data2, fl.HP_Zi = fl.applyHPF(fl.HP_b, fl.HP_a, LPF_Data1, fl.HP_Zi)
	    #Processing Data Initialized: process the rest of the Data:    
	
	def process_IRData(data_ir):
	    #initialize empty vector for ADC voltage levels first
	    data_voltage = list(map(float,np.zeros([len(data_ir),1])))
	    #fill ADC voltage array
	    data_voltage = list(map(fl.adc2voltage, data_ir))
	    #process ADC voltage levels into filtered data
	    processed_ir = list(fl.processData(data_voltage))           
	    return processed_ir
	
	# shift samples left
	def shift_Data():
	    global Data, sampleTotal
	    Data[0][:sampleTotal] = Data[0][-sampleTotal:]
	    Data[0][sampleTotal] = 0
	    Data[1][:sampleTotal] = Data[1][-sampleTotal:]
	    Data[1][sampleTotal] = 0
	
	#Read Data for X seconds:    #measure start time, subtract to assess
	#   Input:  ser, xSeconds: (int for seconds of data collection)
	#   Output: Data global updated
	def Data_Link( ser, xSeconds=10 ):    
	    global Data
	    time.sleep(1)
	    timer = time.time()
	    while ((time.time() - timer) < xSeconds):
	        if ( ser.in_waiting > 4 ):                    
	            #print('reading signal...')
	            Data[0][sampleTotal],Data[1][sampleTotal] = read_Signal(ser)
	            if (Data[0][sampleTotal] == -1):
	                #print('it was bad data')
	                Data[0][sampleTotal] = 0
	                Data[1][sampleTotal] = 0
	            else:                
	                #print('data was read')
	                shift_Data()
	
	#Version of Data_Link for appending data onto 1D vector sets
	#   Input:  ser, (int) seconds to run
	#   Output:  (int) counter for how many new indeces in vectors - appends globals:data_ir, data_time, processed_ir
	def Data_ADD( ser, xSeconds=1 ):    
	    global data_ir, data_time, processed_ir
	    IR = []
	    TIME = []
	    counter = 0
	    time.sleep(1)
	    timer = time.time()
	    while ((time.time() - timer) < xSeconds):
	        if ( ser.in_waiting > 4 ):                    
	            #print('reading signal...')
	            IR, TIME = read_Signal(ser)
	            if (TIME == -1):
	                #print('it was bad data')
	                TIME = 0
	                IR = 0
	            else:                
	                #print('data was read')
	                length = len(data_ir) -1
	                data_ir[:length] = data_ir[-length:]
	                data_time[:length] = data_time[-length:]
	                processed_ir[:length] = processed_ir[-length:]
	                data_ir[length] = IR
	                data_time[length] = TIME
	                #process and append processed_ir data
	                ADC = fl.adc2voltage(IR)                
	                # After wasting 5 hours trying to get these library procedures to work, 
	                # instead I'm just going to try to get results by importing the lines individually.
	                fl.LPF_Data, fl.LP_Zi = fl.sig.lfilter(b=fl.LP_b, a=fl.LP_a, x=[ADC], zi = fl.LP_Zi)
	                f_ADC, fl.HP_Zi = fl.sig.lfilter(b=fl.HP_b, a=fl.HP_a, x=fl.LPF_Data, zi = fl.HP_Zi)
	                processed_ir[length] = float(f_ADC)
	                counter = counter + 1
	    #print(counter)
	    #print('new indices within loop.')
	    return counter                
                
	# Sanitize the Data, sift through bad, null and unwanted data that would distort calculations
	# Useful Data ported into associated individual vectors
	#   Input:  DataIN as Data array: [[time data], [ir data]]
	#   Output: data_time, data_ir, processed_ir data vectors
	def sanitize_Data(DataIN):
	    #initialize vectors
	    d_t = list(map(int,np.zeros([len(DataIN[0]),1])))
	    d_ir = list(map(int,np.zeros([len(DataIN[0]),1])))
	    p_ir = list(map(float,np.zeros([len(DataIN[0]),1])))
	    d_ir = list(DataIN[0])
	    d_t = list(DataIN[1])
	    while 0 in d_t:
	        trash = d_t.index(0)
	        del d_t[trash]
	        del d_ir[trash]
	        del p_ir[trash]
	    return d_t, d_ir, p_ir
   ```
   * After the functions which were originally supposed to make this objective easier were working appropriately, (or in realistically: during the process) we create our main function block as such:
   ```python
	with serial.Serial( port='COM6', baudrate=9600, timeout=1 ) as ser:
	        #establish bluetooth connection. give it a second to connect.
	    print("Bluetooth Started: " + BLE_Connect(ser))
	    time.sleep(1)    
	    initializeVars()
	    print("Vars Initialized")
	    ser.flushInput()   	 	#This flushes incoming data prior to initiating our File, read and store protocols.	 
	    print("Serial Input flushed")
	    #collect initial data: 10s
	    Data_Link( ser, 10)
	    #cleans up Data vectors
	    data_time, data_ir, processed_ir = sanitize_Data(Data)
	    print("Data Sanitized")
	    #initializes filter data and processes current vectors
	    initialize_filters(data_ir)
	    print("Filters Initialized")
	    processed_ir = process_IRData(data_ir)
	    print("Data Processed")
	    gmm_fit = hrcalc.fit_GMM(processed_ir)
	    pred_lbl = hrcalc.predict(gmm_fit,processed_ir)
	    #plot data up to this point:
	    plotStep(data_time, processed_ir, pred_lbl, "Filtered IR Data")
	    print("Ready for Loop.")
	    while True:
	        #collects and appends x seconds of data onto existing vectors
	        newIndex = Data_ADD( ser, 1)
	        pred_lbl = hrcalc.predict(gmm_fit,processed_ir)
	        HeartRate = hrcalc.calculate_hr(processed_ir,pred_lbl,data_time)
	        print(HeartRate)
	        write_BLE(HeartRate,ser)
	        #plotStep(data_time, processed_ir, pred_lbl, "Filtered IR Data")
   ```
   * This could have been polished with a liveplot - which we started to do, but ended up requiring more cumbersome overhauls to main function calls, so we stopped since it wasnt required for this objective.
 * **HRDisplay.ino**: for this portion, we polish up the arduino code to accept a BLE read signal (our Heart Rate) from python and display it on the OLED display
   * We start by piggy-backing on our former codebase that we've been building over: the sampling code from lab 6.1 Obj 1: For this lab to comply for better data, we will try to push our samples to **20Hz**
   * We have to change a lot of functionality to go back to single character reads for the sake of reliability at high sampling rates - Which introduces its own subset of vulnerabilities in the BLE interface reliability.
   * By reading single chars at a time, we dont have to worry about getting stuck on long reads and miss a sampling period. We can then parse types of formatted data with precursor bytes to indicate what kind of data is being read. These operate like 'start bits' and we read our data accordingly.
   * Since the device sensor reading is still extremely finnicky, we still depend on good sensor reads, so more procedures have to be swapped around so to retain our signal mapping on our OLED, so we can know if we have a good read or not before we initiate our script.
   ```c
	void loop() 
	{
	  //Block 0: Condition loop to cycle at a specific rate (for data sampling consistency) -- note: 4 us is the closest i can get with simple offsets for the one clock cycle step between variable storage
	  while (!((micros() - timeCheck + (4)) >= SamplingRate))            
	  {
	    //do nothing -> wait for the appropriate time to do the read.
	  }
	  timeCheck = micros();
	  
	  //Block 1: Run every loop Iteration: 
	  processSignal();                                                //Original Function block:              process the signal 
	  update_Display();                                               //L6.2: Update Display with value data over Signal Mapping
	  //Block 2: Run if in normal state:  
	  if (!SleepMode)  
	  {  
	     displaySignal();                                            //Split from Original Function block:   Display the signal (default: Serial (presumably Plotter))
	     pushSignal();  
	     if (BTserial.available())
	     {
	       //Parse_Read returns true if new data available
	       if (Parse_Read(BTserial.read()))      update_Vals();      
	                              
	     }
	     if (Serial.available())  TerminalRead();         
	  }
	  
	  //Block 3: Run when in sleep mode:
	  else {  }                                                       //Added Sleep Mode block for future lab framework. -> Still do something while sleeping
	  //This condition allows us to normalize cycle delays to be approximate to 1s.
	  
	  checkState();                                                   //Sleep Mode button w/ button validation
	}	
   ```
   ```c
	void update_Vals()
	{
	  if (newHR != 0)
	  {
	    HRVal = newHR;
	    newHR = 0;
	  }
	  if (newStep != 0)
	  {
	    stepVal = newStep;
	    newStep = 0;
	  }
	}
	
	void update_Display()
	{
	  display.clearDisplay();
	  display.setCursor(0,0);  
	  display.print("BPM: ");
	  display.println(HRVal);
	  display.print("Steps: ");
	  display.println(stepVal);
	  DrawSignaltoDisplay();
	  display.display();
	}

	bool Parse_Read(char newChar)
	{
	  bool newData = false;
	  if ((!newChar) || (newChar == '\0')) {}                       // Do nothing / dont distort data patterns for misreads
	  else if ((lastChar == 'A') && (newChar == 'T'))               // if AT: connection reset - purge buffers, no lingering data to drop/block connections
	  {
	    BTserial.flushOutput();
	    BTserial.write("PC");
	    delay(50); 
	    BTserial.flushInput(); 
	  }
	  else if (newChar == 'A')  lastChar = newChar;
	  else if (newChar == '&')                                      // Preset active reading to Heart Rate value for '&'
	  {
	    strcpy(HRBuffer, "");
	    lastChar = newChar;
	  }
	  else if (newChar == '$')                                      // Preset active reading to Step value for '$'
	  {
	    strcpy(stepBuffer, "");
	    lastChar = newChar;
	  }
	  else if (newChar == '~')                                      // if end of line: convert active buffer to appropriate values and pass as new data
	  {
	    if (lastChar =='&')
	    {
	      newHR = atoi(HRBuffer);
	      lastChar = '\0';
	      newData = true;
	    }
	    else if (lastChar == '$')
	    {
	      newStep = atoi(stepBuffer);
	      lastChar = '\0';
	      newData = true;
	    }
	  }
	  else                                    // default: if actively reading from a step or heartrate precursor: fill in data buffers
	  {
	    if (lastChar =='&')           sprintf(HRBuffer, "%s%c", HRBuffer, newChar);    
	    else if (lastChar == '$')     sprintf(stepBuffer, "%s%c", stepBuffer, newChar);
	  }	  
	  return newData;
	}
   ```
   * Finally, we have video proof of our device communicating 2-ways and incorporating an updating function for the Heart Rate as BPM (Beats Per Minute). We added the Step Counting component too while we were at it, to save time when we get to a later step, but the step value will be null for now.<br/>
   ![Video of 2-Way BLE Communication & Heart Rate Data on OLED](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Video/Obj1B.mp4) 

## Objective 2
__User Classification:__<br/>
*Here we will be using **KNN**: _K-Nearest Neighbors_ - Supervised Learning to classification our data*
 * **knn_user_class.py**: Here we will model very similarly what we did with our Unsupervised Data Objective in the last lab, however this time we will take both of our user data, stick them together and give a manual assigned label, then using a predictive model, we can determine the accuracy of the classification method.
   * First we load our previously used training data for each user. Since these loading datasets and other libraries are getting rather cumbersome - we have established a *library folder* at the base of our Lab Directory folder. This also allows us to use a relative path to load the appropriate files.
   ```python
	sys.path.append('../../Libraries/')
	import my_hr_calculator as hrcalc

	#...within the main loop
	hr1_tr, _ = np.load("../../Libraries/user1_train_hr.npy")
	hr2_tr, _ = np.load("../../Libraries/user2_train_hr.npy")
   ```
   * Originally, we used a formatting iteration to turn our __*seconds-per-beat*__ data format into a __*beats-per-minute*__ as that is more readable and relative to our end goals - however for the sake of the labels, this was not easy to utilize so we ended up commenting them out for a normalized readability to the labeled plot.
   ```python
	#hr1_tr = [ 60/x for x in hr1_tr]
	#hr2_tr = [ 60/x for x in hr2_tr]
   ```
   * Here we plot to show what forms of our original data we had and then process them accordingly. Here we show the Training Data but the Validation Data was done in the exact same way.
   ```python
	# ---------- Plot Both User's HR ---------- #
	    plt.figure(1)
	    usr1Samples = np.linspace(1,len(hr1_tr), num=len(hr1_tr))
	    usr2Samples = np.linspace(1,len(hr2_tr), num=len(hr2_tr))
	    plt.plot(usr1Samples, hr1_tr, color="blue", linewidth=1.0, linestyle="-", label= "Steve's Heart Rate")
	    plt.plot(usr2Samples, hr2_tr, color="red", linewidth=0.5, linestyle="-", label= "Nick's Heart Rate")
	    plt.xlabel('# of pulse average samples')
	    plt.ylabel('seconds per beat')
	    plt.title('seconds/beat per avg')
	    plt.legend()
	    plt.show()
	    
	    
	    # ---------- Cropping Data ---------- #
	    # It is VERY important that both classes / users have the same number of datapoints
	    #   For example, if hr1_tr has length of 32 and hr2_tr has length of 40, randomly toss 8 datapoints from hr2_tr
	    # Cropping is removing excess --> random data is also bad data for the point of classifying: so we will crop to equalize by removal.
	    if (len(hr1_tr) == len(hr2_tr)):
	        print('same')
	    elif (len(hr1_tr) > len(hr2_tr)):
	        i = len(hr2_tr)-1
	        while (i < len(hr1_tr)-1 ):
	            del hr1_tr[i]            
	    elif (len(hr2_tr) > len(hr1_tr)):
	        i = len(hr1_tr)-1
	        while (i < len(hr2_tr)-1 ):
	            del hr2_tr[i]      
   ```
   ![Plotted sec/beat data averages, vs # of average samples](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Images/Obj2a.jpeg)
 * Classifying both users: Now we begin implementing our KNN model by structuring the data appropriately. This took some time to find followable examples to understand how to implement.
   * First, we have to shape our data into object appropriate forms, then we create the KNN object and fit our data to it.
   ```python
	data_tr = np.concatenate((hr1_tr, hr2_tr))
	data_tr = np.reshape((data_tr), [len(data_tr), 1])	
	labels_tr = np.concatenate((np.zeros(len(hr1_tr)), np.ones(len(hr2_tr))))

	K = 3
	neigh = KNN(n_neighbors = K)
	neigh.fit( data_tr,labels_tr)
   ```
   * Now that we have our object and fits, we do a predict, plot what it comes up with, then mark the accuracy when compared to our known data labels.
   ```python
    labels_va_pred = neigh.predict( data_va )
    
    plt.figure(2)
    plt.plot(data_va, label='seconds per beat')
    plt.plot(labels_va_pred, label='predicted labels')
    plt.plot(labels_va, label='marked labels')
    plt.xlabel('#samples of averages')
    plt.ylabel('seconds per beat')
    plt.title('seconds per beat averages per prediction labels')
    plt.legend()
    plt.show()
    
    acc = metrics.accuracy_score(labels_va_pred, labels_va)
    print("Accuracy is: " + str(acc))
   ```
   ![Plotted total sec/beat average data w/ Predicted Labels & Marked Labels](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Images/Obj2b.jpeg)
  * The accuracy we yeilded with this graph was pretty bad. Despite a high disparity between the two datasets, it completely missed a large portion of the first section of data. Otherwise it was fairly consistent.<br/> Our reported Accuracy was printed as: _**Accuracy is: 0.678571428571**_.

## Objective 3
__IMU Basics__<br/>
*Visualizing IMU Data: For this portion of the lab, we will be able to read and visualize IMU data given from our IMU model MPU-6050*
 * First we install the I2CDev library: It was not inherently obvious the nature of the library root folder not being for Arduino, so extracting only the specific libraries had to be discovered by external sources.
   * observing both sets of data came to show that one of the values was sticking on a near maximum, and odd that one value was normalized at a -1000 as opposed to the rest hovering near 0. All in all aside from that, it was pretty straightforward. 
   * The data was then isolated by gyrometer and accellerometer. Motion to simulate a walking wrist motion was observed, however not to the level of intent as requested - since serial plotter was necessary, the device could not be moved much farther than a few inches in a direction.
   * The Gyroscope data was showing fairly clear and consistent with the pattern of motion - oscillating back and forth with identifiable patterns. The other signals displayed patterns as well, but not as clearly and crisply as the green axis data.
   ![Gyroscopic axes demonstrating 'walking simulation' (with a 4-inch range)](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Images/gyro.jpeg)
   * The Accellerometer data was not as clearly defined as the Gyroscope for this movement. Movement was obviously detected and some general larger context could be surmised but with the limited movement range we could only suspect it wasn't enough data points to follow - though it should be important to note that all 3 axes were revolving around a -1000 setting, begging for a recalibration of the sensor.
   ![Accellerometer axes demonstrating 'walking simulation' (with a 4-inch range)](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Images/accell.jpeg)
 * Considering some of the wonky data variance we are observing, a calibration is in order. This was undergone for a dozen sets of time between 10 and 45 minutes with no clear indication of completion, issue, or progress - since there is no direct meaningful feedback. Presumably due to serial communications within the default program set to 115200.

## Objective 4
__Implementing the IMU__<br/>
* Implementing the IMU Data: For this portion of the lab, we will use the IMU data from Objective 3, add it into our Device's normal Arduino code to sample the new sets of data - and on Python collect and process the accellerometer data with Power Spectral Density, and show it plotting in a live plot one at a time to give an idea why PSD is useful.
 * For the first part we read the IMU data into our device using the *interruptPinISR()* and *ReadIMU()* functions - adding into our sampling procedure and pushing via our 2-way BLE code.
   * Piggybacking on our previous labs, we add the prime functionalities from Obj 3's RawIMU functions into our sampled code, and use it to transmit through BLE the IMU visualization.
   * Implementing the Functionalities seemed to work well on the first compile, however never worked again afterwards - Upon investigation, the interruptISR handler and Pin were overloading the rest of the Arduino and disallowing it to do anything outside of the interupt. So since this was only going to add issue where we were intending to sample anyways - we disabled all of the interrupt/ISR features.
   * One inherent limitation we face at this point is that each of our 7 data points is a 6 byte equivalent character array if we were to transmit each of them through the BLE. That would be a good reason why the lab objective only requires us to perform 1 transfer at a time - allowing us to use our buffer space for 8 bytes, ontop of the pre-existing 17 bytes in our sample cycle.
   ```c
	//within the main loop sampled reading loop
	if (grabIMU()) pushIMU();
   ```
   ```c
	void InitializeIMU()
	{
	  IMU.initialize();
	  IMU.dmpInitialize();
	  IMU.setDMPEnabled(true);
	  // Initialize I2C communications
	  Wire.begin();
	  Wire.beginTransmission(MPU_addr);
	  Wire.write(MPU_addr);   // PWR_MGMT_1 register
	  Wire.write(0);          // set to zero (wakes up the MPU-6050)
	  Wire.endTransmission(true);
	}
	
	//IMU sampling reads
	void readIMU() {
	  Wire.beginTransmission(MPU_addr);
	  Wire.write(0x3B);                    // starting with register 0x3B (ACCEL_XOUT_H)
	  Wire.endTransmission(false);
	  
	  Wire.requestFrom(MPU_addr,14,true);  // request a total of 14 registers
	  
	  //Accelerometer (3 Axis)
	  ax=Wire.read()<<8|Wire.read();  // 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)    
	  ay=Wire.read()<<8|Wire.read();  // 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
	  az=Wire.read()<<8|Wire.read();  // 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
	  
	  //Temperature
	  tp=Wire.read()<<8|Wire.read();  // 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
	  
	  //Gyroscope (3 Axis)
	  gx=Wire.read()<<8|Wire.read();  // 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
	  gy=Wire.read()<<8|Wire.read();  // 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)	
	  gz=Wire.read()<<8|Wire.read();  // 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
	}

	//IMU: Read IMU when triggered by ISR pin     (May have to scrap and salvage since its using its own sampling)
	bool grabIMU()
	{
	  readIMU();                    // read data from the IMU
	  return true;
	}

	void pushIMU()
	{
	  //Convert int16_t -> char array for string transfer on BTSerial
	  char val[6];
	  BTserial.print('&');
	  itoa(ax, val, 10);
	  BTserial.print(val);
	  /*
	  BTserial.print('|');
	  itoa(ay, val, 10);
	  BTserial.print(val);
	  BTserial.print('|');
	  itoa(az, val, 10);
	  BTserial.print(val);
	  */
	  BTserial.print('~');
	  Serial.print('&');
	  Serial.print(ax);
	  Serial.print('|');
	  Serial.print(ay);
	  Serial.print('|');
	  Serial.print(az);
	  Serial.println('~');  
	  /*
	  Serial.print(gx);
	  Serial.print('|');
	  Serial.print(gy);
	  Serial.print('|');
	  Serial.print(gz); 
	  Serial.println('~'); 
	  */
	}
   ```
 * Implementing the IMU Data: **_lab6imu.py_**
   * For the Python file implementation for the imu data, we are partially playing on similar logic steps we've used in the past as how we are reading and sending data. We could have just used the exact same formatting for the IR Data but for the Accelleration data, but given we will be submitting different sets of data by the next lab, we should prepare a logical parsing thread since we'll need to make one for later anyways.<br/> In the end though, there was a lot of bad reads in the bluetooth now that we are pumping the sampling rate back up to 20Hz and trying to push larger sets of numbers - Ultimately, we kept the parsing logic but scaled back the sent ble data to just a single acceleration data frame and timing for the remainder of this assignment. This however, required us to yet again, change key supporting functions. At this point, we are no longer even using any functions from the custom libraries so the rest of those dependancies are now commented out as they only created issues in the first place. 
   ```python
	def grab_samples(count=20) :    
	    t, x = np.zeros((2, count))
	    i = 0
	    d1 = 0
	    d2 = 0
	    while (i < count):
	        #read_Signal returns -1, -1 on error condition: do not load on error condition
	        d2, d1 = read_Signal(ser)
	        print('d1: ' + str(d1) + ' & d2: ' + str(d2))
	        if ((d1 != -1) & (d2 != -1)):
	            t[i] = int(d1)    #/1e6
	            x[i] = int(d2)                  
	            print('i@' + str(i) + ' t[i]: ' + str(t[i]) + 'x[i]: ' + str(x[i]))
	            i += 1  
	    print('t is: ', t)
	    print('x is: ', x)
	    return t, x
	
	def read_Signal(ser):
	    global tdata, ac_data, gy_data, ir_data
	    msg = ""
	    #State variable to validate msg formatting: default:'none' |IR Data: 'IRD'|IMU accel Data: 'IMUAcD' |IMU gyro Data: 'IMUGyD'
	    # |Time Data: 'Timer'|
	    state = "none"
	    #consistantly build up val as numerical data point from char array. When finished, set to acceleration signal value, gyro signal value, or IR signal value
	    val = ""
	    #timer = ""
	    ac_Val = 0
	    gy_Val = 0
	    ir_Val = 0
	    time_Val = 0
	    while (not msg):
	        msg = read_BLE(ser)
	    print(msg)
	    #Negate possible unproccessable buffer strings from BLE read command: if needed, do other things later on
	    if ((msg.find("OK") >= 0) or (msg.find("AT") >= 0) or (msg.find("CONN") >= 0) or (msg == "")):
	        print("Bad Data(2)! ")
	        ser.flushInput()
	        msg = ""
	        return -1, -1
	    #else: parse expected Data
	    else:        
	        for c in msg:
	            if c == '&':    
	                state = "IMUAcD"    
	                val = ""
	            elif c == '%':
	                state = "IMUGyD"
	                val = ""
	            elif c == '$':
	                state = "IRD"
	                val = ""                
	            elif ((state != 'none') & ((c.isdigit()) | (c=='-'))):
	                val = val + c
	            elif ((state  == "IMUAcD") & ((c == '|') | (c == '*'))):                
	                #ac_Val.append(int(val.rstrip('\n')))
	                #shift_Data( ac_data, int(val.rstrip('\n')))
	                #shift_Data( ac_Val, int(val.rstrip('\n')))
	                ac_Val = int(val.rstrip('\n'))
	                #print('ac_Val state: ' + str(ac_Val))
	                val = ""
	            elif ((state  == "IMUGyD") & ((c == '|') | (c == '*'))):
	                #gy_Val.append(int(val.rstrip('\n')))
	                #shift_Data( gy_data, int(val.rstrip('\n')))
	                #shift_Data( gy_Val, int(val.rstrip('\n')))
	                gy_Val = int(val.rstrip('\n'))
	                #print('gy_Val state: ' + str(gy_Val))
	                val = ""
	            elif ((state  == "IRD") & ((c == '|') | (c == '*'))):
	                #ir_Val.append(int(val.rstrip('\n')))
	                #shift_Data( ir_data, int(val.rstrip('\n')))
	                ir_Val = int(val.rstrip('\n'))
	                #print('ir_Val state: ' + str(ir_Val))
	                val = ""
	            elif ((state  == "Timer") & (c == '~')):
	                time_Val = int(val.rstrip('\n'))
	                #shift_Data( tdata, int(val.rstrip('\n')))
	                #print('time_Val state: ' + str(time_Val))
	                state = "none"
	                val = ""                
	            elif (c == '~'):                
	                print("warning: bypassed fill timer: bad data frame")
	                state = "none"
	                val = ""
	                return -1, -1
	            else:
	                print("warning: outside of expected char range: bad data frame")
	                print(str(c) + ' within ' + msg)
	                return -1,-1
	            if (c == '*'):
	                state = "Timer"
	                val = ""
	            #print(state)    
	        if ((ac_Val != 0) & (time_Val != 0)):
	            #This should yeild 3 data points to add: ax,ay,az:
	            #shift_Data( ac_data, ac_Val)                    
	            #print('returning ac_val set: ' + str(ac_Val))
	            return ac_Val, time_Val
	        elif ((gy_Val != 0) & (time_Val != 0)):
	            #This should yeild 3 data points to add: gx,gy,gz:
	            #shift_Data( gy_data, gy_Val)
	            #print('returning gy_val set: ' + str(gy_Val))
	            return gy_Val, time_Val
	        else:
	            return -1,-1         

   ```
   * Once the logic was reading and parsing properly, after eliminating and changing dependancy procedures to independently utilize the logic, the rest was much easier: implementing the animation plot function itself. While getting the program to work is always finnicky, we realized that Spyder and Terminal each have their unique error cases. While Spyder doesn't support the animation functionalities, Terminal doesnt seem to support system links to utilize library files, and tends to hang up on loops (or possibly the ble connection itself) occassionally. Either way, executing it properly was more a case of making sure all of the data types and misc. random function args were present for the required environment.<br/> Thankfully, the welch function for the PSD calculation worked right out of the bag, pretty much for the first time for our new functionalities/techniques from the class, thanks to some intuitive template naming and easy to read documentation references.
   ```python
	def update_plots(i) :
	  # shift samples left by 'NS'
	    tdata[:N-NS] = tdata[NS:]
	    xdata[:N-NS] = xdata[NS:]
	  # grab new samples
	    tdata[N-NS:], xdata[N-NS:] = grab_samples(NS)    
	    freqs, ydata = sig.welch(xdata,fs)
	  # update plot axes
	    axes[0].set_xlim(tdata[0],tdata[N-1])
	  # plot
	    lines[0].set_data(tdata, xdata)
	    lines[1].set_data(freqs, ydata)
	    return lines
   ```
   ![Subplot for Raw Data (Ax) vs PSD of Ax Data](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Images/Obj4_data.jpg)
   * Lastly, the base objective is to show proof that the live function works for IMU data from each accellerometer sensor, so we go through each of Ax, Ay and Az scales and show video of each: noting specific trends in what we are observing.<br/>
   ![Video of IMU Accelleration (Ax) live plot](https://github.com/UCSD-Product-Engineering/ece16-winter19-Kazektulu/blob/master/Lab6.2/Video/Obj4_IMU_liveplots.MOV)
 * __*Questions & Observations*__:
   * _Useful differences in the data per accelleration data (while walking), and why_: <br/> 
    1. **Ax**: Notable difference in rythm between hand-swing - notable sine-wave-like pattern where Ax data spikes high, then goes low, then spikes high, low again - somewhat resembling the IR wave, albeit in a more uniform sinusoidal pattern.
    1. **Ay**: Overall the same behaviour as Ax input: Ay values appear identical to Ax values in size and shape. There was no apparent difference at general glance. It should be noted that the acceleration values themselves are nearly identical to Ax, and for both so far, the orientation of the IMU would yeild a different average/DC-offset that may be a +20000 or a -20000 depending on orientation.
    1. **Az**: Overall again, the same notable behavior as Ax and Ay. If any of these vectors were observed side to side, it would not be easy to tell them apart.
   * _What is the PSD doing while walking in rythm and why is it useful?_: <br/> 
    1. **Ax-PSD**: Not inherently useful looking. Common trends in the pattern where when held/idle, a *high spike towards 0 Hz drops relatively sharply into the 2.5Hz range*, while the larger ranges continue a decline into the same trends they hold at all idle ranges/noise. When held, any slight movements or inherent vibrations from the user/environment cause the *Ax-PSD to vary wildly from frame to frame*. <br/> When in *rythmatic walking motion*, the only two notable differences is that instead of a direct sharp spike declining from 0 into 2.5 Hz range, there is a *hill/bubble of peak value throughout the 0-2.5 Hz range* before the same style of sharp decline. The other trend of note is that on a frame-to-frame difference, rythmatic walking Ax-PSD stays rather *consistent in it's overall pattern*, with peaks/valleys varying in general despite being held by a user and undergoing changes in environment.
    1. **Ay-PSD**: When idle, Ay shows a *more consistently high overall pattern of the same general shape* was present. When in motion, the *gaussian-shape peak/hill was more pronounced along the 0-2.5Hz region, peaking somewhere around 1-1.25 Hz*.
    1. **Az-PSD**: When idle, Az shows a *more consistent average between the same general pattern*, however the difference shows where *the spike at the 0Hz in prior Ax & Ay PSD vectors does not take place in the Az PSD vector*. When in motion, the Az PSD vector shows similar behavior as the prior Ax and Ay but again *does not exhibit the same impact on the lower Hz scale*: while it could be observed that relative high peaks are usually found at the same 2-1.25 Hz Region, *it is still consistent with the other average regions* and not obvious that this region or pattern is unique under the Az-PSD vector. 

## Conclusion
We could conclude that the Accelleration values from the IMU are useful in general contextual data, but not precise/accurate/sampled often enough for the values themselves to be of use to us. General trends can be observed but are not entirely clear. We can assume that perhaps with a filter and aggregate calculations, we can isolate the small trends in walking motion - but it may be better off to simply use a form of FFT to find resonant frequences instead. Either way, there is just barely enough trends in the variance to be useful in a Machine Learning application to classify. Above all, the last task of watching the individual vectors seems to be acting to convince us that the individual vectors themselves are of no real importance and by taking an aggregate absolute cubing between the 3, we will not only get similar overall data and spare us space when transfering over BLE - but may also likely help to emphasize trending peak values that are otherwise only minor.


