public class ALD_LiveAldarUtilityCtrl {

    public static Id getServiceAppointmentByType(String caseId,String recTypeDevName){
        List<String> recTypeName = recTypeDevName.contains(',') ? recTypeDevName.split(','): new List<String> { recTypeDevName };
            
        return [SELECT Id FROM ServiceAppointment WHERE Case__c =: caseId AND RecordType.DeveloperName IN:recTypeName ORDER BY CreatedDate DESC LIMIT 1]?.Id;
    }

    public static ServiceAppointment  getAppointmentDetail(String saId){
        ServiceAppointment sa = new ServiceAppointment();
        List<ServiceAppointment> lst = [SELECT Id,ArrivalWindowEndTime,ArrivalWindowStartTime,AppointmentNumber,Status,ServiceNote,Technician_Comments__c,SchedStartTime,SchedEndTime,FSSK__FSK_Assigned_Service_Resource__c,FSSK__FSK_Assigned_Service_Resource__r.Name,FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MobilePhone,(SELECT Id,ApptAssistantInfoUrl,ServiceResourceId,EstimatedTravelTime FROM ServiceResources LIMIT 1) FROM ServiceAppointment WHERE Id=:saId];
        if(!lst.isEmpty())
            sa = lst[0];
        return sa;
    }

    public static List<FSL.AppointmentBookingSlot> fetchAppointmentSlots(String saId,String ophrs){
       ServiceAppointment sa = [SELECT Id,Status, EarliestStartTime, DueDate FROM ServiceAppointment WHERE Id=: saId];
       
       if(sa.Status == 'Closed'){
           return null;
       }
        Id schedulingPolicyId = [SELECT Id,Name FROM FSL__Scheduling_Policy__c  WHERE Name='Aldar Scheduling Policy' LIMIT 1].Id;
        OperatingHours oh   = [SELECT id,name FROM OperatingHours WHERE name=:ophrs LIMIT 1];
        Timezone tz = UserInfo.getTimeZone();
        return FSL.AppointmentBookingService.GetSlots(saId, schedulingPolicyId, oh.id, tz, false);
    }

    public static List<FSL.AppointmentBookingSlot> fetchAppointmentSlots(String saId){
        return fetchAppointmentSlots(saId,'Gold Appointments Calendar');
       /*ServiceAppointment sa = [SELECT Id,Status, EarliestStartTime, DueDate FROM ServiceAppointment WHERE Id=: saId];
       
       if(sa.Status == 'Closed'){
           return null;
       }
        Id schedulingPolicyId = [SELECT Id,Name FROM FSL__Scheduling_Policy__c  WHERE Name='Aldar Scheduling Policy' LIMIT 1].Id;
        OperatingHours oh   = [SELECT id,name FROM OperatingHours WHERE name='Gold Appointments Calendar' LIMIT 1];
        Timezone tz = UserInfo.getTimeZone();
        return FSL.AppointmentBookingService.GetSlots(saId, schedulingPolicyId, oh.id, tz, false);*/
    }
	/*
    public static List<FSL.AppointmentBookingSlot> fetchAppointmentSlots(String saId){
       ServiceAppointment sa = [SELECT Id,Status, EarliestStartTime, DueDate,Case__r.RecordType.Name FROM ServiceAppointment WHERE Id=: saId];
       
       if(sa.Status == 'Closed'){
           return null;
       }
        Id schedulingPolicyId = [SELECT Id,Name FROM FSL__Scheduling_Policy__c  WHERE Name='Aldar Scheduling Policy' LIMIT 1].Id;
        OperatingHours oh   = [SELECT id,name FROM OperatingHours WHERE name='Gold Appointments Calendar' LIMIT 1];
        Timezone tz = UserInfo.getTimeZone();
        //return FSL.AppointmentBookingService.GetAbSlots(saId, schedulingPolicyId, oh.id, tz, false);
        if(sa.Case__r.RecordType.Name == 'DLP'){
            FSL.ABSlotsResponse slots1 = FSL.AppointmentBookingService.getABSlots(sa.Id, schedulingPolicyId, oh, UserInfo.getTimeZone(), 'SORT_BY_DATE', false);
            return slots1.slots;
        }
        else{
            return FSL.AppointmentBookingService.GetSlots(saId, schedulingPolicyId, oh.id, tz, false);
        }
        
    }*/
    
}