enum NotificationType { HRVHigh, HRVLow, BPMHigh, BRPMHigh, PaceLow, PaceHigh, Decline, Incline }

class Notification {
   
  int timestamp;
  NotificationType type; 
  String note;
  String tag;
  int value;
  int priority;
  
  public Notification(JSONObject json) {
    this.timestamp = json.getInt("timestamp");
    //time in milliseconds for playback from sketch start
    
    String typeString = json.getString("type");
    
    try {
      this.type = NotificationType.valueOf(typeString);
    }
    catch (IllegalArgumentException e) {
      throw new RuntimeException(typeString + " is not a valid value for enum NotificationType.");
    }
    
    
    if (json.isNull("note")) {
      this.note = "";
    }
    else {
      this.note = json.getString("note");
    }
    
    if (json.isNull("tag")) {
      this.tag = "";
    }
    else {
      this.tag = json.getString("tag");      
    }
   
    this.value = json.getInt("value");      
    
    this.priority = json.getInt("priority");
    //1-4 levels (1 is highest, 4 is lowest)    
  }
  
  public int getTimestamp() { return timestamp; }
  public NotificationType getType() { return type; }
  public String getNote() { return note; }
  public String getTag() { return tag; }
  public int getValue() { return value; }
  public int getPriorityLevel() { return priority; }
  
  public String toString() {
      return getNote().toString();
    }
}
