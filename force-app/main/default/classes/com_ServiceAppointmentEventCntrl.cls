public class com_ServiceAppointmentEventCntrl {
    
    @InvocableMethod(label='Class Service Appointments Platform Event Creator' description='Creates platform event for Class Service Appointments')
    public static void createPlatformEvent(List<List<String>> parentAppointmentList){
        
        /*Map<String, List<ServiceAppointment>> parentToChildAppointmentList = new Map<String, List<ServiceAppointment>>();
        
        List<ServiceAppointment> parentAppointments = [Select Id, AppointmentNumber, SchedStartTime, Booking_Amount__c, Comments, AccountId, Account.Name, Account.SapAccountID__c, Account.Com_Cost_Center_SAP_Code__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Assigned_Service_Resource__r.AssetId, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__c, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fee_including_VAT__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Include_VAT__c
                                                       from ServiceAppointment where Id IN : parentAppointmentList[0]];
        
        
        List<Com_Service_Appointments__e> eventsToPublish = new List<Com_Service_Appointments__e>();
        Com_Service_Appointments__e eventObj;
        Integer lineNo = 1;
        
        
        for(ServiceAppointment parentAppointment : parentAppointments){
            lineNo = 1;
            eventObj = new Com_Service_Appointments__e();
            eventObj.Bukrs__c = '1500';
            eventObj.Regno__c = parentAppointment.AppointmentNumber;
            eventObj.ApplicantId__c = String.valueof(parentAppointment.AccountId).substring(0, 15);
            eventObj.LineNo__c = lineNo;
            eventObj.SesDate__c = Date.valueOf(parentAppointment.SchedStartTime);
            eventObj.ApplicantName__c = parentAppointment.Account.Name;
            eventObj.TotAmt__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fee_including_VAT__c;
            eventObj.Waers__c = 'AED';
            eventObj.ClassId__c = String.valueof(parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c).substring(0, 15);
            eventObj.ClassPackId__c = String.valueof(parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__c).substring(0, 15);
            eventObj.Bpnum__c = parentAppointment.Account.SapAccountID__c;
            eventObj.TotBookingAmt__c = parentAppointment.Booking_Amount__c;
            eventObj.Remarks__c = parentAppointment.Comments;
            eventObj.ParentRegNo__c = parentAppointment.AppointmentNumber;
            eventObj.Parent_Appointment_Id__c = String.valueof(parentAppointment.Id).substring(0, 15);
            //eventObj.Child_Appointment_Id__c = String.valueof(parentAppointment.Id).substring(0, 15);
            
            eventsToPublish.add(eventObj);
        }*/
        
        List<Class_Booking__e> eventsToPublish = new List<Class_Booking__e>();
        Class_Booking__e bookingEvent = new Class_Booking__e();
        bookingEvent.Master_Appointment_Id__c = parentAppointmentList[0][0];
        
        eventsToPublish.add(bookingEvent);
        
        List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() );
                }
            }
        }
    }    
}