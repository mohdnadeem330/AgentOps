/**
* @File Name : AMC_ODBookAppointmentController.cls
* @Description :
* @Author : Smaartt
* @Last Modified By : 10 Sep 2024
* @Last Modified On : September 6, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 6, 2024 |   | Initial Version
**/

public class AMC_ODBookAppointmentController {
    @AuraEnabled/*(cacheable=true)*/
    Public static List<MainWrapper> FetchAvailableSlots(String recId){
        
        if(String.isBlank(recId))
            throw new AuraHandledException('Record Id is not valid');
        ServiceAppointment sa = getSADetail(recId); 
        Integer consecutiveHours = Integer.valueOf(sa.Duration);
        String durationOpHrs = FetchOperatingHour(consecutiveHours);

        validateAppointment(sa);
        
        //GET AVAILABLE TIME SLOTS
        Map<Date, List<DateTime>> mapDateTime = getAppointmentSlotBasedOnDuration(sa,durationOpHrs);

        List<MainWrapper> lstWrap = new List<MainWrapper>();
        for(Date dt:mapDateTime.keySet()){
            
            MainWrapper wrap = formatAndReturnDayWiseSlot(dt,mapDateTime,consecutiveHours);
           system.debug('***wrap'+wrap);
            lstWrap.add(wrap);
        }
        // Debug the result
         

        return lstWrap;
    }
    
    Public static MainWrapper formatAndReturnDayWiseSlot(Date dt,Map<Date, List<DateTime>> mapDateTime,Integer consecutiveHours){
        MainWrapper wrap = new MainWrapper();
        DateTime DateTm = DateTime.newInstance(dt.year(), dt.month(), dt.day());
            wrap.day = DateTm.format('MMMM dd,yyyy') + ' '+ DateTm.format('EEEE');
            List<TimingDetail> lsttm = new List<TimingDetail>();
            for(DateTime dttm:mapDateTime.get(dt)){
                DateTime endDtTm = dttm.addHours(consecutiveHours);
                TimingDetail tm =new TimingDetail(dttm.format('hh:mm a','GMT'),endDtTm.format('hh:mm a','GMT'),dttm,endDtTm);
               
                lsttm.add(tm);
            }
         wrap.avlTime = lsttm;
        return wrap;
    }

    public static String FetchOperatingHour(Decimal duration){
        if(test.isRunningTest())
            return System.Label.DefaultOperatingHours;
        List<OD_Duration_Mapping__mdt> lst = [SELECT Label,MasterLabel,Operating_Hour_Name__c FROM OD_Duration_Mapping__mdt WHERE Hour__c=:duration];
        if(lst.size() > 0){ return lst[0].Operating_Hour_Name__c;
        }else  {throw new AuraHandledException('No Operating hour found for the duration');}
    }

    public static void validateAppointment(ServiceAppointment sa){
        Set<String> setStatus = new Set<String>{'New','Scheduled','Re-scheduled'};
        if(!setStatus.contains(sa.Status))  
            throw new AuraHandledException('Book Appointment is not possible at this moment');
    }

    public static Map<Date, List<DateTime>> getAppointmentSlotBasedOnDuration(ServiceAppointment sa,String operatingHrs){
        
        Map<Date, List<DateTime>> mapDateTime = new Map<Date, List<DateTime>>();
        //List<FSL.AppointmentBookingSlot> slots = ALD_LiveAldarUtilityCtrl.fetchAppointmentSlots(sa.Id);
        Id schedulingPolicyId = [SELECT Id,Name FROM FSL__Scheduling_Policy__c  WHERE Name='Aldar Scheduling Policy' LIMIT 1].Id;
        OperatingHours oh   = [SELECT id,name FROM OperatingHours WHERE name=:operatingHrs LIMIT 1];
        Timezone tz = UserInfo.getTimeZone();
        List<FSL.AppointmentBookingSlot> slots = FSL.AppointmentBookingService.GetSlots(sa.Id, schedulingPolicyId, oh.id, tz, false);
        // Define the number of consecutive hours dynamically
        Integer consecutiveHours = Integer.valueOf(sa.Duration);  // You can change this to any number of hours

        // Loop through the slots and check for consecutive time blocks
        for (Integer i = 0; i < slots.size(); i++) {
            Date currentSlotDate = Date.valueOf(slots[i].Interval.Start);
            if (!mapDateTime.containsKey(currentSlotDate)) {
                mapDateTime.put(currentSlotDate, new List<DateTime>());
            }
            mapDateTime.get(currentSlotDate).add(slots[i].Interval.Start);
            //mapDateTime.get(currentSlotDate).add(slots[i].Interval.Finish);
            // Get the starting DateTime of the first slot in the block
            /*DateTime firstSlotStart = slots[i].Interval.Start;
            Boolean isAvailableForConsecutiveHours = true;

            // Check the next (consecutiveHours - 1) slots for consecutive hours
            for (Integer j = 1; j < consecutiveHours; j++) {
                if ((i + j) >= slots.size()) {
                    isAvailableForConsecutiveHours = false; // No more slots available
                    break;
                }

                DateTime nextSlotStart = slots[i + j].Interval.Start;
                        
                // If the difference between consecutive slots is not exactly 1 hour, break
                if (firstSlotStart.addHours(j) != nextSlotStart) {
                    isAvailableForConsecutiveHours = false;
                    break;
                }
            }*/

            // If we found consecutive slots as per the defined hours, mark them as available
            /*if (isAvailableForConsecutiveHours) {
                Date currentSlotDate = Date.valueOf(firstSlotStart);

                // Initialize the map if it doesn't contain the date key
                if (!mapDateTime.containsKey(currentSlotDate)) {
                    mapDateTime.put(currentSlotDate, new List<DateTime>());
                }

                // Get the list of DateTimes for this date
                List<DateTime> lstDateTimes = mapDateTime.get(currentSlotDate);

                // If the list is empty, add the first slot
                if (lstDateTimes.isEmpty()) {
                    lstDateTimes.add(firstSlotStart);
                } else {
                    // Check if the new slot is after the last slot plus the consecutive hours
                    DateTime lastSlot = lstDateTimes[lstDateTimes.size() - 1];
                    if (firstSlotStart > lastSlot.addHours(consecutiveHours-1)) {
                        lstDateTimes.add(firstSlotStart);
                    }
                }
            }*/
        }
        return mapDateTime;
    }

    Public static ServiceAppointment getSADetail(String recId){
        return [SELECT Id,Case__c,Status,SchedStartTime,Duration,SchedEndTime,ArrivalWindowStartTime,ArrivalWindowEndTime,Case__r.Product.Name FROM ServiceAppointment WHERE Id=: recId];
    }

     
    @AuraEnabled
    public static void scheduleAppointment(String saId,DateTime startDateTime,DateTime endDateTime){
        try{ 
        ServiceAppointment sa = getSADetail(saId);
        validateAppointment(sa);
        // Convert the DateTime to GMT before saving (if needed)
        String startDateTimeGMT = startDateTime.formatGMT('yyyy-MM-dd\' \'HH:mm:ss'); 
        String endDateTimeGMT = endDateTime.formatGMT('yyyy-MM-dd\' \'HH:mm:ss');
        
        sa.ArrivalWindowStartTime = DateTime.valueOf(startDateTimeGMT);
        sa.ArrivalWindowEndTime = DateTime.valueOf(endDateTimeGMT); 
        UPDATE sa;
        FSL__Scheduling_Policy__c policy=[select id ,Name  from FSL__Scheduling_Policy__c where Name='Aldar Scheduling Policy' LIMIT 1];
        scheduleApp(policy.Id, sa.Id);
        }Catch(Exception ex){ throw new AuraHandledException('Error : '+ex.getMessage()); }
    }
    
    //@future
    public static void scheduleApp(Id policyId,Id appId){
        FSL.ScheduleResult result = FSL.ScheduleService.schedule(policyId,appId);
    }
    
    Public class MainWrapper{
        @AuraEnabled
        Public String day{get;set;}
        @AuraEnabled
        Public List<TimingDetail> avlTime{get;set;}
    }

    Public class TimingDetail{
        @AuraEnabled
        Public String startTime{get;set;}
        @AuraEnabled
        Public String endTime{get;set;}
        @AuraEnabled
        Public DateTime startDateTime{get;set;}
        @AuraEnabled
        Public DateTime endDateTime{get;set;}
        
        Public TimingDetail(String startTm,String endTm,DateTime dt,DateTime endDt){
            this.startTime = startTm;
            this.endTime = endTm;
            this.startDateTime = dt;
            this.endDateTime = endDt;
        }
    }

}