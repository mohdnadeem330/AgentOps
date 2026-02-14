public with sharing class AppointmentService { 
    
    public static List<Appointment__c> queryAllFieldsWithExtraFields(List<Id> appointmentsIds) {
        Set<String> appointmentFieldList = Schema.getGlobalDescribe().get('Appointment__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(appointmentFieldList);
        String fields = string.join(strList,',');


        String appointmentIdsStr = String.join(appointmentsIds, '\',\'');
        String query = 'SELECT ' + fields + ', Case__r.casenumber, Case__r.status, Case__r.priority, Case__r.ownerid, Case__r.createddate, Case__r.createdbyid, Case__r.category__c, Case__r.salesorder__c, Case__r.unit__c, Case__r.Unit__r.Name, Case__r.Unit__r.Project__r.AsiteProjectName__c, Case__r.casecategory__c, Case__r.subcategory__c, Case__r.problemcode__c, Case__r.incidentdescription__c, Case__r.resolutiontype__c, Case__r.recommendedsolution__c, Case__r.escalationpriority__c, Case__r.problemcodelocation__c, Case__r.asitedescription__c, Case__r.customertype__c, Case__r.asiteinstancegroupid__c, Case__r.asiteprojectid__c, Owner.Email, Owner.Name FROM Appointment__c WHERE Id IN (\'' + appointmentIdsStr + '\')';

        System.debug('***Appointment query***'+query);
        List<Appointment__c> appointments = Database.Query(query);
        System.debug('***Appointment Queried***'+appointments);
        return appointments;
    }
  
}