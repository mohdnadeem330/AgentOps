public class com_appointmentReminderNotification {
    @InvocableMethod(label='Service Appointments Reminder Email Creator' description='Service Appointments Reminder Email Creator')
    public static List<String> classNotifications(List<List<String>> parentAppointmentList){
        
        List<String> appIds = parentAppointmentList[0];
        //List<String> appIds = new List<String>{'08pFV0000009eHZYAY','08pFV0000009eHaYAI','08pFV0000009eHbYAI'};
        
        String query = 'SELECT Id, AppointmentNumber, Status, Email, Phone, Com_Attended__c, SchedStartTime,  SchedEndTime, AttendeeCount, Asset__c, Subject, AccountEmailID__c, ' +
            'ParentRecordId, ' +
            'AccountId, Account.Name, Account.SapAccountID__c, ' +
            'OwnerId, Owner.Name, ' +
            'ServiceTerritoryId, ServiceTerritory.Name, ' +
            'Community__c, Community__r.Name, Zone__c, Zone__r.Name, ' +
            'Unit_Number__c, Unit_Number__r.Name, ' +
            'Precinct__c, Precinct__r.Name, ' +
            'Service_Appointment__c, Service_Appointment__r.Master_Service_Appointment__c, Service_Appointment__r.Master_Service_Appointment__r.AppointmentNumber , Master_Service_Appointment__c, Master_Service_Appointment__r.AppointmentNumber, '+
            'CreatedById, CreatedBy.Name, ParentRecord.Name, Asset__r.Name, Asset__r.Recordtype.DeveloperName , Recordtype.DeveloperName, FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Assigned_Service_Resource__r.Name, Asset__r.RecordTypeId, FSSK__FSK_Assigned_Service_Resource__r.AssetId, FSSK__FSK_Assigned_Service_Resource__r.Asset.Name , FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Name ' +
            'FROM ServiceAppointment WHERE ID IN : appIds ';
        
        List<ServiceAppointment> appointmentList = Database.Query(query);
        
        
        String htmlHeader = 'Hi '+appointmentList[0].ParentRecord.Name+','+'\r\n\r\n';
        htmlHeader += 'This is a reminder for your upcoming booking for '+appointmentList[0].FSSK__FSK_Assigned_Service_Resource__r.Name + '. Your booking details are as follows:'+'\r\n\r\n';
        htmlHeader += 'District: '+appointmentList[0].Zone__r.Name+'\r\n';
        htmlHeader += 'Community: '+appointmentList[0].Community__r.Name+'\r\n';
        htmlHeader += 'Building: '+appointmentList[0].Precinct__r.Name+'\r\n';
        htmlHeader += 'Unit: '+appointmentList[0].Asset__r.Name+'\r\n\r\n';
        
        String htmlTable = 'Schedule Details:'+'\r\n';
        for(ServiceAppointment appObj : appointmentList){
            htmlTable += 'Appointment Number: '+appObj.AppointmentNumber+'\r\n';
            htmlTable += 'Scheduled Time: '+ (appObj.SchedStartTime).format('MM/dd/yyyy hh:mm:ss a z')+'\r\n\r\n';
        }
        
        String htmlFooter = 'We look forward to seeing you and hope you enjoy your '+appointmentList[0].FSSK__FSK_Assigned_Service_Resource__r.Name+'\r\n\r\n';
        htmlFooter += 'Kind regards,'+'\r\n';
        htmlFooter += 'Community Management Team';
        
        String htmlContent = htmlHeader + htmlTable + htmlFooter;
        
        system.debug(htmlContent);
        return new List<String>{htmlContent};
            }
}