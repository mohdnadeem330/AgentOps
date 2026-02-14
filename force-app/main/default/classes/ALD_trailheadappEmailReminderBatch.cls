/******************************************************************************************************************
* Name              : ALD_trailheadappEmailReminderBatch                                                        
* Description       : batch class to send email reminders to all the users assigned to a trailmix
* CreatedBy & Date	: tdontha@aldar.com - 25/05/2023   
* LastModifiedBy	: tdontha@aldar.com - Tharun
* REFER TO THE END COMMENTS SECTION TO RUN THE BATCH 
******************************************************************************************************************/
public class ALD_trailheadappEmailReminderBatch implements Database.Batchable<sObject>,Schedulable
{
    public String queryStr;
    public static final String TRAILHEAD_STATUS = 'Completed';
    
    public void execute(SchedulableContext sc) {
        database.executebatch(this,5);
    }
    
    //This below constructor is only for testing purpose. Please ignore 
    Set<Id> testIds = new Set<Id>();
    public ALD_trailheadappEmailReminderBatch(Set<Id> testIds){
        this.testIds    = testIds;
        this.queryStr 	= 'SELECT Id, Name, trailheadapp__Trailmix__r.Name, trailheadapp__User__r.Name, trailheadapp__User__r.Email,trailheadapp__Assigned_At__c, trailheadapp__Due_At__c, trailheadapp__Status__c, trailheadapp__Trailmix__r.trailheadapp__URL__c FROM trailheadapp__User_Trailmix__c where trailheadapp__Due_At__c > TODAY and trailheadapp__Status__c != :TRAILHEAD_STATUS and trailheadapp__User__c != null  and Id IN :testIds';  
    }
    
    public ALD_trailheadappEmailReminderBatch(){
        this.queryStr 	= 'SELECT Id, Name, trailheadapp__Trailmix__r.Name, trailheadapp__User__r.Name, trailheadapp__User__r.Email,trailheadapp__Assigned_At__c, trailheadapp__Due_At__c, trailheadapp__Status__c, trailheadapp__Trailmix__r.trailheadapp__URL__c FROM trailheadapp__User_Trailmix__c where trailheadapp__Due_At__c > TODAY and trailheadapp__Status__c != :TRAILHEAD_STATUS and trailheadapp__User__c != null';  
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('FinalQuery'+this.queryStr);
        return Database.getQueryLocator(this.queryStr);
    }
    public void execute(Database.BatchableContext bc, List<trailheadapp__User_Trailmix__c> userTrailmixList)
    {
        try{
            Date todaysDate 										= System.today();
            List<Messaging.SingleEmailMessage> lstEmail 			= new List<Messaging.SingleEmailMessage>();
            if(userTrailmixList.size() > 0){
                Set<String> emailReminderMetadataConfigDays 		= new Set<String>([SELECT Id, DaysBefore__c FROM trailheadapp_Reminder__mdt WHERE CommunicationType__c = 'Email' AND DaysBefore__c != null LIMIT 1].DaysBefore__c.Split('\\|'));
                for(trailheadapp__User_Trailmix__c userTM : userTrailmixList){
                    Date dueDate 									= userTM.trailheadapp__Due_At__c.date();
                    Integer remainingDays 							= todaysDate.daysBetween(dueDate);
                    
                    if(emailReminderMetadataConfigDays.contains(String.valueOf(remainingDays)))
                    {
                        String emailTemplateDeveloperName 						= Label.trailheadapp_ReminderEmailTemplate;
                        Id orgWideEmailAddressId 								= [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_BROKER LIMIT 1].Id;
                        EmailTemplate emailTemp 								= [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :emailTemplateDeveloperName];
                        
                        Messaging.SingleEmailMessage sendingEmailMessage		= new Messaging.SingleEmailMessage();
                        Messaging.SingleEmailMessage sEmail 					= Messaging.renderStoredEmailTemplate(emailTemp.Id, null, null);
                        
                        String subject 	= sEmail.getSubject();
                        String htmlBody = sEmail.getHtmlBody();
                        
                        subject	 		= subject.replace('{trailmixName}', 	String.isBlank(userTM.trailheadapp__Trailmix__r.Name) ? '' : String.valueOf(userTM.trailheadapp__Trailmix__r.Name));
                        htmlBody		= htmlBody.replace('{learnerName}', 	String.isBlank(userTM.trailheadapp__User__r.Name) ? '' : String.valueOf(userTM.trailheadapp__User__r.Name));
                        htmlBody	 	= htmlBody.replace('{trailmixName}', 	String.isBlank(userTM.trailheadapp__Trailmix__r.Name) ? '' : String.valueOf(userTM.trailheadapp__Trailmix__r.Name));
                        htmlBody		= htmlBody.replace('{trailmixDueDate}', userTM.trailheadapp__Due_At__c == NULL ? '' : String.valueOf(userTM.trailheadapp__Due_At__c.date()));
                        htmlBody		= htmlBody.replace('{trailmixURL}', 	'<a href="'+userTM.trailheadapp__Trailmix__r.trailheadapp__URL__c+'">LINK.</a>');
                        
                        sendingEmailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
                        sendingEmailMessage.setSubject(subject);
                        sendingEmailMessage.setHtmlBody(htmlBody);
                        sendingEmailMessage.setWhatId(userTM.Id);
                        //saveAsActivity must be false when sending mail to users, else Run Time Error
                        sendingEmailMessage.setSaveAsActivity(false);
                        sendingEmailMessage.setTargetObjectId(userTM.trailheadapp__User__c);
                        lstEmail.add(sendingEmailMessage);
                    }
                }
            }
            
            if (lstEmail.size() > 0 && lstEmail != null )
            {
                List<Messaging.SendEmailResult> resultsEmails = Messaging.sendEmail(lstEmail, false);
                for(Messaging.SendEmailResult ser: resultsEmails){
                    if (!ser.isSuccess()){
                        for(Messaging.SendEmailError objErr: ser.getErrors()){
                        	System.debug('ALD_trailheadappEmailReminderBatch: '+ objErr.getMessage());
                        }
                    }
                }
            }
            
        }
        catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'executeBatch','ALD_trailheadappEmailReminderBatch','execute'));
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch finish -> ');
    }
}