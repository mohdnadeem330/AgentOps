global with sharing class DLPMilestoneTimeCalculator implements Support.MilestoneTriggerTimeCalculator {

    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId){

        Integer hours;
        Constant__mdt constantMdt = new Constant__mdt();

        constantMdt = Constant__mdt.getInstance(Constants.HOURS); 
        hours = constantMdt!= NULL ? Integer.valueOf(constantMdt.ConstantValue__c) : Constants.CASEHOURS;
        
        Case c = [SELECT Priority, CaseCategory__c, SubCategory__c, SubVertical__c, Appointment_Date__c, Appointment_Booking_Date__c, ResolutionType__c FROM Case WHERE Id=:caseId];
        		
        if(c.SubVertical__c == 'DLP' && c.Appointment_Date__c != Null)
        {           
            if(c.Appointment_Booking_Date__c == null)
                c.Appointment_Booking_Date__c = DateTime.Now();
            
            //system.debug('Appointment Date::'+c.Appointment_Date__c + ':: Appointment Booking Date ::'+c.Appointment_Booking_Date__c);
            Long milliseconds = c.Appointment_Date__c.getTime() - c.Appointment_Booking_Date__c.getTime() + 360*1000;
           // system.debug('milliseconds ::'+milliseconds);
            return Integer.valueOf(milliseconds/(1000*60));
        }
        else
                return 60;
     }
}