public class SchedulerAppointments {
    public datetime startTime;
    public datetime endTime;
    public integer remainingAppointments;
    public integer attendeeLimit;
    public List<String> resources;
    public String territoryId;
  
    
    public static list<SchedulerAppointments> parse(String json) {
      return (list<SchedulerAppointments>) System.JSON.deserialize(json, list<SchedulerAppointments>.class);
    }

}