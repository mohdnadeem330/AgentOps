/***************************************************
* Date: 26 Sept 2024 
* Author: Smaartt 
* Description: Callout Class - Tasareeh_MepsIntegrations
* Updated by Smaartt - Job Abort logic removed
* 26/09/2024 Updated by Harsh to run on yesterday's date
***************************************************/
public class Tasareeh_Schedulable implements Schedulable {
    
    public void execute(SchedulableContext context){
        Date d = date.today().addDays(-1);
        String dt = DateTime.newInstance(d.Year(),d.Month(),d.Day()).format('yyyy-MM-dd');
        
        System.enqueueJob(new Tasareeh_MepsIntegrations('Parcels', dt,true));
    }  
}