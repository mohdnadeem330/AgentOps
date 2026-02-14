/**********************************************************************************************************************
* Name              : BatchToSendEmailsToBrokerAgencies                                                        
* Description       : This Apex class will be sending emails to all classified brokers
* Method            : BatchToSendEmailsToBrokerAgencies - Constructor to reminder
                      Refer to the end comments section to run the batch 
* Created By        : tdontha@aldar.com - Tharun   
* Last Modified By  : tdontha@aldar.com - Tharun
******************************************************************************************************************/
public class BatchToSendEmailsToBrokerAgencies implements Database.Batchable<sObject>,Schedulable,Database.Stateful
{
    Set<Id> conIdsSet                                               = new Set<Id>();
    Integer remainderReceived                                       = 0;
    Boolean isTesting                                               = false;
    Map<Id, String> getPrevClassificationByAccId                    = new Map<Id, String>();
    Map<String, BrokerClassification__c> brokerClassificationMap    = new Map<String, BrokerClassification__c>();
    
    public void execute(SchedulableContext sc) {
        database.executebatch(this,5);
    }
    
    public BatchToSendEmailsToBrokerAgencies(Integer remainderReceived)
    {
        this.remainderReceived                              = remainderReceived;
    }
    
    // Constructor with 3 params isTesting = true then email will goto contactId passed
    public BatchToSendEmailsToBrokerAgencies(Boolean isTesting,Set<Id> conIdsSet,Integer remainderReceived)
    {
        this.conIdsSet                                      = conIdsSet;
        this.isTesting                                      = isTesting;
        this.remainderReceived                              = remainderReceived;
    }
    
    public List<Contact> start(Database.BatchableContext bc)
    {
        System.debug('Batch started -> ');
        // Added By Moh Sarfaraj for BPM-650
        String currentyear = String.valueOf(System.Today().year()); 
        
        List<BrokerClassification__c> brokerClassificationList = [SELECT Id,Name,Quarter1MarketingBudget__c,Quarter2MarketingBudget__c,Quarter3MarketingBudget__c,Quarter4MarketingBudget__c FROM BrokerClassification__c WHERE Year__c = :currentyear];
        if(!brokerClassificationList.isEmpty()){
            for(BrokerClassification__c brokeCls:brokerClassificationList){
                // map of Consul => BrokerClassification__c
                brokerClassificationMap.put(brokeCls.Name, brokeCls);
            }
        }
        
        if(!this.isTesting)
        {
            Set<Id> accountIds                  = new Set<Id>();
            Set<Id> finalAccIdsToSent           = new Set<Id>();
            Map<Id, Contact> premBrokMap        = new Map<Id, Contact>();
            /* Commented as per ASF-642
            List<BrokerRequest__c> markReqList  = [Select Id, AgencyName__r.Id 
            From BrokerRequest__c 
            WHERE RecordType.Name = 'Marketing Reimbursement' 
            AND InvoiceDate__c = THIS_MONTH];
            for(BrokerRequest__c singleBR : markReqList){
            accountIds.add(singleBR.AgencyName__r.Id);
            }
            */
            Date todaysDate                 = Date.today();
            Integer currentQuarter          = ( (todaysDate.month() -1) / 3) ;
            if(currentQuarter == 0){
                List<String> premClassif                                = new List<String>{'Envoy','Attache','Consul','Ambassador'};
                List<AccountHistory> accHisList                         = [SELECT Id,CreatedDate,OldValue,NewValue, AccountId,Account.Name FROM AccountHistory WHERE Field = 'BrokerClassification__c' AND CreatedDate = THIS_QUARTER ORDER BY Account.Name ASC];
                
                for(AccountHistory accHisSingle: accHisList){
                    if(accHisSingle.OldValue <> null && accHisSingle.OldValue <> '' && String.valueOf(accHisSingle.OldValue).isAlpha() &&
                       premClassif.contains(String.valueOf(accHisSingle.OldValue))){
                           getPrevClassificationByAccId.put(accHisSingle.AccountId, String.valueOf(accHisSingle.OldValue));
                       }
                }
                premBrokMap = new Map<Id, Contact>([SELECT Id, BrokerType__c, Email, Account.Name, AccountId, Account.Broker_Classification_Formula__c
                                                    FROM Contact 
                                                    WHERE Account.RecordType.Name = 'Broker Agency'
                                                    AND BrokerType__c IN ('Agency Admin','Partner/Owner')
                                                    AND Account.ParentId = null
                                                    AND AccountId IN: getPrevClassificationByAccId.keySet()]);
                
            }else{
                // Below List is queried to remove premium accounts which were changed to classifications current quarter
                List<AccountHistory> accsHisList = [SELECT Id, Field, OldValue, NewValue,  AccountId, Account.Name FROM AccountHistory 
                                                    WHERE Field = 'BrokerClassification__c' AND CreatedDate = THIS_QUARTER AND Account.BrokerPremiumClassification__c = true
                                                    AND DAY_IN_MONTH(CreatedDate) > 1 ORDER BY CreatedDate DESC ];
                if(!accsHisList.isEmpty()){
                    for(AccountHistory singleAccHisRecord : accsHisList){
                        if(singleAccHisRecord.OldValue == 'Standard'){
                            accountIds.add(singleAccHisRecord.AccountId);
                        } else if(singleAccHisRecord.OldValue <> NULL && singleAccHisRecord.OldValue <> '' && String.valueOf(singleAccHisRecord.OldValue).isAlpha()){
                            getPrevClassificationByAccId.put(singleAccHisRecord.AccountId, String.valueOf(singleAccHisRecord.OldValue));
                        }
                    }
                }
                System.debug('accountIdsTobeRemoved---'+accountIds);
                premBrokMap = new Map<Id, Contact>([SELECT Id, BrokerType__c, Email, Account.Name, AccountId, Account.Broker_Classification_Formula__c
                                                    FROM Contact 
                                                    WHERE Account.RecordType.Name = 'Broker Agency'
                                                    AND BrokerType__c IN ('Agency Admin','Partner/Owner') 
                                                    AND Account.BrokerPremiumClassification__c = true
                                                    AND Account.ParentId = null
                                                    AND AccountId NOT IN: accountIds ]);
            }
            
            System.debug('premBrokMap-->'+premBrokMap.Values());
            System.debug('premBrokContactsSize-->'+premBrokMap.size());
            //This below Set is for testing purpose to validate the count of Broker Accounts to be sent Email
            if(premBrokMap.size() > 0){
                for(Contact contFinal: premBrokMap.Values()){
                    finalAccIdsToSent.add(contFinal.AccountId);
                }
                System.debug('finalAccIdsToSent-->'+finalAccIdsToSent.size());
            }
            return premBrokMap.Values();
        }
        else
        {
            System.debug('In Testing Block');
            List<Contact> testContact = [SELECT Id, BrokerType__c,AccountId,Account.Broker_Classification_Formula__c,Account.BrokerClassification__r.Quarter1MarketingBudget__c,Account.BrokerClassification__r.Quarter2MarketingBudget__c,Account.BrokerClassification__r.Quarter3MarketingBudget__c,Account.BrokerClassification__r.Quarter4MarketingBudget__c 
                                         FROM Contact 
                                         WHERE Account.RecordType.Name = 'Broker Agency' 
                                         AND BrokerType__c IN ('Agency Admin','Partner/Owner')
                                         AND Id IN: this.conIdsSet ];
            System.debug('testContact----'+testContact);
            return testContact;
        }
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> contactList)
    {
        try{
            List<Messaging.SingleEmailMessage>  lstEmail    = new List<Messaging.SingleEmailMessage>();
            String emailTemplateDeveloperName               = 'MarketingReimbursementRemainder'+remainderReceived;
            
            EmailTemplate emailTemp                         = [SELECT Id, Name, DeveloperName, Subject, HtmlValue 
                                                               FROM EmailTemplate 
                                                               WHERE DeveloperName  = :emailTemplateDeveloperName];
            
            Id orgWideEmailAddressId                        = [SELECT Id, Address 
                                                               FROM OrgWideEmailAddress 
                                                               WHERE DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_BROKER 
                                                               LIMIT 1].Id;
            
            Date todaysDate                                 = Date.today();
            
            Integer quarterReceived                         = ( (todaysDate.month() -1) / 3) ;
            quarterReceived                                 = quarterReceived == 0 ? 4 :quarterReceived;
            
            Integer calculatedYear                          = todaysDate.year();
            calculatedYear                                  = quarterReceived == 4 ? calculatedYear - 1 : calculatedYear;
            
            for(Contact singleContact : contactList)
            {
                Messaging.SingleEmailMessage sEmail                 = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, null);
                Messaging.SingleEmailMessage sendingEmailMessage    = new Messaging.SingleEmailMessage();
                
                String subject                                      = sEmail.getSubject();
                String htmlBody                                     = sEmail.getHtmlBody();
                String textBody                                     = sEmail.getPlainTextBody();
                String endDateValue                                 = '';
                String quarterAmountFromBC                          = '';
                String strBrokerClassification                      = '';
                
                Integer numberOfDays                                = Date.daysInMonth(todaysDate.year(), todaysDate.month());
                Date lastDayOfMonth                                 = Date.newInstance(todaysDate.year(), todaysDate.month(), numberOfDays);
                
                if(getPrevClassificationByAccId.keySet().Contains(singleContact.AccountId)){
                    strBrokerClassification = getPrevClassificationByAccId.get(singleContact.AccountId);
                }else{
                    strBrokerClassification = singleContact.Account.Broker_Classification_Formula__c;
                }
                
                if(quarterReceived == 1){
                    quarterAmountFromBC = brokerClassificationMap.get(strBrokerClassification).Quarter1MarketingBudget__c.toPlainString();
                    //quarterAmountFromBC = String.isNotBlank(singleContact.Account.BrokerClassification__r.Quarter1MarketingBudget__c.toPlainString() ) ? singleContact.Account.BrokerClassification__r.Quarter1MarketingBudget__c.toPlainString() : '';
                }else if(quarterReceived == 2){
                    quarterAmountFromBC = brokerClassificationMap.get(strBrokerClassification).Quarter2MarketingBudget__c.toPlainString();
                }else if(quarterReceived == 3){
                    quarterAmountFromBC = brokerClassificationMap.get(strBrokerClassification).Quarter3MarketingBudget__c.toPlainString();
                }else if(quarterReceived == 4){
                    quarterAmountFromBC = brokerClassificationMap.get(strBrokerClassification).Quarter4MarketingBudget__c.toPlainString();
                }
                
                if(remainderReceived == 1){
                    subject  = subject.replace('{quarterCal}', String.valueOf(quarterReceived));
                    subject  = subject.replace('{yearCal}', String.valueOf(calculatedYear));
                    htmlBody = htmlBody.replace('{quarter}', String.valueOf(quarterReceived));
                    htmlBody = htmlBody.replace('{yearCal}', String.valueOf(calculatedYear));
                    htmlBody = htmlBody.replace('{brokerClassification}', String.valueOf(strBrokerClassification));
                    htmlBody = htmlBody.replace('{quarterAmount}', String.valueOf(quarterAmountFromBC));
                }else if(remainderReceived == 2){
                    subject  = subject.replace('{quarterCal}', String.valueOf(quarterReceived));
                    subject  = subject.replace('{yearCal}', String.valueOf(calculatedYear));
                    htmlBody = htmlBody.replace('{endDateQuarterValue}', lastDayOfMonth.year()+'-'+lastDayOfMonth.month()+'-'+lastDayOfMonth.day());
                }else if(remainderReceived == 3){
                    subject  = subject.replace('{quarterCal}', String.valueOf(quarterReceived));
                    subject  = subject.replace('{yearCal}', String.valueOf(calculatedYear));
                }
                
                sendingEmailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
                //sendingEmailMessage.setSenderDisplayName('Aldar Broker Management Team');
                //sendingEmailMessage.setCcAddresses(new List<String> {'tdontha@aldar.com'});
                sendingEmailMessage.setSubject(subject);
                sendingEmailMessage.setHtmlBody(htmlBody);
                sendingEmailMessage.setTargetObjectId(singleContact.Id);
                sendingEmailMessage.setSaveAsActivity(true);
                lstEmail.add(sendingEmailMessage);
            }
            
            
            if (lstEmail.size() > 0 && lstEmail != null )
            {
                // true  - By default, this is true, which means that if a record fails, the remainder of DML operations will not be processed  
                // false - If a record fails, the remainder of DML operations can still succeed
                List<Messaging.SendEmailResult> resultsEmails = Messaging.sendEmail(lstEmail, false);
                for(Messaging.SendEmailResult ser: resultsEmails){
                    if (!ser.isSuccess()){
                        for(Messaging.SendEmailError objErr: ser.getErrors()){
                            String errorStackTrace = objErr.getTargetObjectId() +' - '+ objErr.getMessage();
                            System.debug('errorStackTrace---'+errorStackTrace);
                            LoggerService.save(BatchToSendEmailsToBrokerAgencies.createApexInfoLog('BatchToSendEmailsToBrokerAgencies',
                                                                                                   'execute',
                                                                                                   errorStackTrace));
                        }
                    }else{
                        System.debug('Emails Sent Successfully---'+ser.isSuccess());
                    }
                }
            }
            
        }
        catch(Exception ex){
            System.debug('Exception---BatchToSendEmailsToBrokerAgencies---' + ex);
            LoggerService.save(LoggerService.createApexLog(ex,'execute','BatchToSendEmailsToBrokerAgencies','execute'));
        }
    }
    
    public void finish(Database.BatchableContext bc)
    {
        System.debug('Batch finish -> ');
    }
    
    //------Initialise Information Logger
    public static Logger__c createApexInfoLog(String className, String methodName,String stackTrace){       
        Logger__c newLog                = new Logger__c();
        newLog.LogType__c               = 'Information';
        newLog.ClassName__c             = className;
        newLog.MethodName__c            = methodName;
        newLog.StackTrace__c            = stackTrace;
        return newLog;
    }
    
}

/*
 * 
 
Final Cron Expression dates: Below expressions will schedule at 9:00 AM
___________________________________________________________________________________________________________________________

System.schedule('BatchToSendEmailsToBrokerAgencies-Reminder1',  '0 0 9 3 1/3 ? *', new BatchToSendEmailsToBrokerAgencies(1));
System.schedule('BatchToSendEmailsToBrokerAgencies-Reminder2',  '0 0 9 15 1/3 ? *', new BatchToSendEmailsToBrokerAgencies(2));
System.schedule('BatchToSendEmailsToBrokerAgencies-Reminder3',  '0 0 9 L JAN,APR,JUL,OCT ? *', new BatchToSendEmailsToBrokerAgencies(3));

___________________________________________________________________________________________________________________________

Reminder-1

0 0 6 2 1/3 ? *   ==== For Reminder-1 which runs on APR, JUL, OCT, JAN months and 2nd Day

Description: At 06:00:00am, on the 2nd day, every 3 months starting in January

1.  2023-04-02 Sun 06:00:00
2.  2023-07-02 Sun 06:00:00
3.  2023-10-02 Mon 06:00:00
4.  2024-01-02 Tue 06:00:00
5.  2024-04-02 Tue 06:00:00

__________________________________________________________________

Reminder-2

0 0 6 15 1/3 ? *   ==== For Reminder-2 which runs on APR, JUL, OCT, JAN months and 15th Day

Description: At 06:00:00am, on the 15th day, every 3 months starting in January

1.  2023-04-15 Sat 06:00:00
2.  2023-07-15 Sat 06:00:00
3.  2023-10-15 Sun 06:00:00
4.  2024-01-15 Mon 06:00:00
5.  2024-04-15 Mon 06:00:00

_____________________________________________________________________

Reminder-3

0 0 6 L JAN,APR,JUL,OCT ? *

Description: At 06:00:00am, on the last day of the month, in January, April, July and October


1.  2023-04-30 Sun 06:00:00
2.  2023-07-31 Mon 06:00:00
3.  2023-10-31 Tue 06:00:00
4.  2024-01-31 Wed 06:00:00
5.  2024-04-30 Tue 06:00:00

// Add the conIdsSet of this org in 2nd parameter - Use this in exceptional case of running batch manually with contactIds Set
Set<Id> conIdsSet = new Set<Id>{'0038d00000LyVInAAN','0038d00000EuduOAAR'};
BatchToSendEmailsToBrokerAgencies batchEmail = new BatchToSendEmailsToBrokerAgencies(true,conIdsSet,3);
Database.executeBatch(batchEmail,5);

BatchToSendEmailsToBrokerAgencies batchEmail = new BatchToSendEmailsToBrokerAgencies(3);
Database.executeBatch(batchEmail,5);

*/