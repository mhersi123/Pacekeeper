import beads.*;

import controlP5.*;
import java.util.*;

ControlP5 p5;
Gain masterGain;

Glide gainGlide;
Glide tempoGlide;
Glide brGlide;
Button startEventStream;
Button pauseEventStream;
Button stopEventStream;

Slider bpmSlider;
Slider brpmSlider;
Slider hrvSlider;
Slider paceSlider;

Button toggleIncline;
Button toggleDefault;
Button toggleDecline;

String exampleSpeech = "Begin the Run";
String slowDown = "Slow Down Pace";
String speedUp = "Speed Up Pace";
String controlBR = "Control Breathing or Slow Pace";
String controlHR = "Heart Rate is too high";
String incline  = "incline";
String decline  = "decline";
  
color back = color(0,0,0);

float breath = 30;

TextToSpeechMaker ttsMaker;
SamplePlayer breathing;
//<import statements here>

//to use this, copy notification.pde, notification_listener.pde and notification_server.pde from this sketch to yours.
//Example usage below.

//name of a file to load from the data directory
String eventDataJSON1 = "jog_info.json";

NotificationServer notificationServer;
ArrayList<Notification> notifications;
PriorityQueue<Notification> queue;
MyNotificationListener myNotificationListener;

void setup() {
  size(600,500);
  background(back);
  p5 = new ControlP5(this);
  
  NotificationComparator pq = new NotificationComparator();
  queue = new PriorityQueue<Notification>(10, pq);
  ac = new AudioContext(); //ac is defined in helper_functions.pde
  
  gainGlide = new Glide(ac, 0.05, 200);
  masterGain = new Gain(ac, 1, gainGlide);
  
  WavePlayer beep = new WavePlayer(ac, 250, Buffer.SINE);
  
  float bpm = 100;
  float freq = bpm / 60.0; // Convert to Hz
  tempoGlide = new Glide(ac, freq, 100);
  
  Buffer inverseSaw = new Buffer(Buffer.SAW.buf.length);
  // This buffer is needed to get the notes to fade out
  // Using the normal Buffer.SAW makes the notes fade in
  // Also remaps the range from [-1, 1] to [0, 1]
  for (int i = 0; i < inverseSaw.buf.length; i++) {
    inverseSaw.buf[i] = 0.5 - 0.5 * Buffer.SAW.buf[i];
  }
  WavePlayer tempo = new WavePlayer(ac, tempoGlide, inverseSaw);
  
  Gain beepGain = new Gain(ac, 1, tempo); // the tempo wave adjusts the Gain like an automatic periodic Glide
  beepGain.addInput(beep);
  masterGain.addInput(beepGain);
  ac.out.addInput(masterGain);
  
  breathing = getSamplePlayer("Breathing1.wav");
  breathing.pause(true);
  ac.out.addInput(breathing);
  //this will create WAV files in your data directory from input speech 
  //which you will then need to hook up to SamplePlayer Beads
  ttsMaker = new TextToSpeechMaker();
  
  ttsExamplePlayback(exampleSpeech); //see ttsExamplePlayback below for usage
  
  //START NotificationServer setup
  notificationServer = new NotificationServer();
  
  //instantiating a custom class (seen below) and registering it as a listener to the server
  myNotificationListener = new MyNotificationListener();
  notificationServer.addListener(myNotificationListener);
    
  //END NotificationServer setup
  
  startEventStream = p5.addButton("startEventStream")
    .setPosition(40,20)
    .setSize(150,20)
    .setLabel("Start Event Stream");
    
  startEventStream = p5.addButton("pauseEventStream")
    .setPosition(40,60)
    .setSize(150,20)
    .setLabel("Pause Event Stream");
 
  startEventStream = p5.addButton("stopEventStream")
    .setPosition(40,100)
    .setSize(150,20)
    .setLabel("Stop Event Stream");
    
  bpmSlider = p5.addSlider("bpmSlider")
    .setPosition(200, 200)
    .setSize(300,20)
    .setRange(90, 180)
    .setValue(110)
    .setLabel("BEATS PER MINUTE");
    
  hrvSlider = p5.addSlider("hrvSlider")
    .setPosition(200, 250)
    .setSize(300,20)
    .setRange(20, 200)
    .setValue(100)
    .setLabel("HEART RATE VARIABILITY");
  
  brpmSlider = p5.addSlider("brpmSlider")
    .setPosition(200, 300)
    .setSize(300,20)
    .setRange(15, 45)
    .setValue(30)
    .setLabel("BREATHS PER MINUTE");
    
  paceSlider = p5.addSlider("paceSlider")
    .setPosition(200, 350)
    .setSize(300,20)
    .setRange(7, 10)
    .setValue(8)
    .setLabel("PACE");
  
  toggleIncline  = p5.addButton("toggleIncline")
    .setPosition(200, 400)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("ACTIVATE INCLINE");
    
  toggleDecline  = p5.addButton("toggleDecline")
    .setPosition(300, 400)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("ACTIVATE DeCLINE");
    
  toggleDefault  = p5.addButton("toggleDefault")
    .setPosition(400, 400)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("NORMAL LEVEL");
    
  ac.start();
}
public void bpmSlider(float bpm) {
  tempoGlide.setValue(bpm / 60.0);
}
public void brpmSlider(float brpm) throws InterruptedException {
  if (brpm > 35) {
    breathing.setToLoopStart();
    breathing.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
    breathing.start();
    Thread.sleep(3000);
  } else {
    breathing.pause(true);
  }
}
public void paceSlider(float pace) throws InterruptedException {
  if (pace < 8) {
    ttsExamplePlayback(slowDown);
    Thread.sleep(3000);
  }
  if (pace > 9) {
    ttsExamplePlayback(speedUp);
    Thread.sleep(3000);
  }
}

public void toggleIncline() {
  ttsExamplePlayback(incline);
}
public void toggleDecline() {
  ttsExamplePlayback(decline);
}
public void toggleDefault() {
  ttsExamplePlayback("Normal Elevation");
}
public void hrvSlider(float hrv) {
  masterGain.setGain(hrv / 150);
}
void startEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.loadEventStream(eventDataJSON1);
}

void pauseEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.pauseEventStream();
}

void stopEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.stopEventStream();
}

void draw() {
  //this method must be present (even if empty) to process events such as keyPressed()  
}

/**void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == RETURN || key == ENTER) {
    notificationServer.stopEventStream(); //always call this before loading a new stream
    notificationServer.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: " + eventDataJSON2 + " ****");
  }
    
} */

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class MyNotificationListener implements NotificationListener {
  
  public MyNotificationListener() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    println("<Example> " + notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    String debugOutput = ">>> ";
    switch (notification.getType()) {
      case HRVHigh:
        //debugOutput += "HRV is too high: ";
        queue.add(notification);
        break;
      case BPMHigh:
        //debugOutput += "BPM is too high: ";
        queue.add(notification);
        break;
      case BRPMHigh:
        //debugOutput += "Breathing is too intense: ";
        queue.add(notification);
        break;
      case PaceLow:
        //debugOutput += "Pace is decreasing: ";
        queue.add(notification);
        break;
      case PaceHigh:
        //debugOutput += "Pace is too high: ";
        queue.add(notification);
        break;
      case Decline:
        //debugOutput += "Jogging at a decline: ";
        queue.add(notification);
        break;
      case Incline:
        //debugOutput += "Jogging at an incline: ";
        queue.add(notification);
        break;
    }
    debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    ttsExamplePlayback(debugOutput);
    println(debugOutput);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
