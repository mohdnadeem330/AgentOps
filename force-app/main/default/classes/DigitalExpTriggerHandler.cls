public class DigitalExpTriggerHandler extends TriggerHandler {
    public static Boolean resendFlag = false;
    public static Set<Id> AccrecordIds = new Set<Id>();
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Set<Id> recordIds = new Set<Id>();
            List<Account> accToUpdate = new List<Account>();
            
            for(Communication_Preference__c pref : (List<Communication_Preference__c>)newList){
                Communication_Preference__c oldRecord = (Communication_Preference__c)oldmap.get(pref.Id);
                if(pref.Category__c == 'FastTrack' && pref.Active__c && pref.Resend__c && oldRecord.Resend__c != pref.Resend__c) {
                    recordIds.add(pref.Account__c);
                }
            }
        if(recordIds.size() >0){
            AccrecordIds.addAll(recordIds);
        }
        if(AccrecordIds.size() >0){
            /*for(Communication_Preference__c pref : (List<Communication_Preference__c>)newList){
               pref.Resend__c = false;
            }*/
        }
    }
    public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
        Set<Id> AccountId = new Set<Id>();
         for(Communication_Preference__c cp : (List<Communication_Preference__c>)newList){
             AccountId.add(cp.Account__c);
         }
         Map<Id,String> AccountMap = new  Map<Id,String>();
         Map<Id,String> AccountContactMap = new  Map<Id,String>();
         for(Account acc :[SELECT Id,Name,personEmail,personContactId FROM Account WHERE Id=:AccountId]){
             AccountMap.put(acc.Id, acc.personEmail);
             AccountContactMap.put(acc.Id,acc.personContactId);
         }
         for(Communication_Preference__c cp : (List<Communication_Preference__c>)newList){
             cp.Account_Email__c = AccountMap.get(cp.Account__c);
             cp.Contact__c = AccountContactMap.get(cp.Account__c);
         }
     }
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        try{
            Set<Id> recordIds = new Set<Id>();
            Set<Id> digitalSPAIds = new Set<Id>();
            Set<Id> digitalSalesIds = new Set<Id>();
            List<Account> accToUpdate = new List<Account>();
            
            for(Communication_Preference__c pref : (List<Communication_Preference__c>)newList){
                // ||pref.Category__c == 'Digital SPA'
                if((pref.Category__c == 'FastTrack') && pref.Active__c) {
                    recordIds.add(pref.Account__c);
                }
                if(pref.Category__c =='Digital SPA' && pref.Status__c =='Link Sent' &&  pref.Active__c && pref.Account__c != null){
                    digitalSPAIds.add(pref.Account__c);
                }
                if(pref.Category__c =='Booking' && pref.Status__c =='Link Sent' &&  pref.Active__c){
                    digitalSalesIds.add(pref.Account__c);
                }
            }
            if(recordIds != null && !recordIds.isEmpty() && !Test.isRunningTest()) {
                Database.executeBatch(new SendWhatsAppLinkWithBitly(recordIds,'FastTrack'),1);
              /*  Map<Id, Account> accountList = new Map<Id, Account>([SELECT Id, FastTrackedAccount__c FROM Account WHERE Id IN:recordIds]);
                for(Account acc : accountList.values()) {
                    acc.FastTrackedAccount__c = true;
                    accToUpdate.add(acc);
                }*/
            }
            if(digitalSPAIds != null && !digitalSPAIds.isEmpty()){
                System.enqueueJob(new DigitalSPAQueueable(digitalSPAIds,'DigitalSPA'));
            }
            if(digitalSalesIds != null && !digitalSalesIds.isEmpty()){
                System.enqueueJob(new DigitalSPAQueueable(digitalSalesIds,'DigitalSales'));
            }


            /*
            if(!accToUpdate.isEmpty()) {
                update accToUpdate;
            }*/
        } catch(Exception e) {
           /* String htmlEmailBody = 'Hello,</br></br> DigitalExpTriggerHandler afterInsertMethod has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b>  ';
            Utilities.sendExceptionEmail('DigitalExpTriggerHandler','afterInsertMethod',htmlEmailBody,'DigitalExpTriggerHandler afterInsertMethod',e); */
            LoggerService.save(LoggerService.addApexLog(e,'Communication Preference Record Creation Failed','DigitalExpTriggerHandler','afterInsertMethod')); // Added by Tajinkumar
        }
    }
    
    public override void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        try{
            Set<Id> recordIds = new Set<Id>();
            Set<Id> ResendrecordIds = new Set<Id>();
            Set<Id> digitalSPAIds = new Set<Id>();
            Set<Id> LeadIds = new Set<Id>();
            for(Communication_Preference__c pref : (List<Communication_Preference__c>)newList){
                Communication_Preference__c oldRecord = (Communication_Preference__c)oldmap.get(pref.Id);
                
                if(pref.Category__c == 'FastTrack' && pref.Active__c && pref.Status__c == 'Fasttrack Completed' && oldRecord.Status__c != pref.Status__c) {
                    recordIds.add(pref.Account__c);
                }
                //DIGITAL SALES CHIARG START
                if((pref.Category__c == 'Booking' && pref.Active__c && pref.Status__c == 'Fasttrack Completed' && oldRecord.Status__c != pref.Status__c) || Test.isRunningTest()) {
                    LeadIds.add(pref.Lead__c);
                }
                //DIGITAL SALES CHIARG END
                if(pref.Category__c == 'Digital SPA' && pref.Active__c && pref.Status__c == 'Link Sent' && oldRecord.Status__c != pref.Status__c){
                    digitalSPAIds.add(pref.Account__c); 
                }
                  
            }
            //Added by Daksh Sharma 
            if (!recordIds.isEmpty()) {
                PropertyTransferService.updatePTOffPlanVerificationSteps(recordIds);
            }
            //End by Daksh Sharma 
             
            //DIGITAL SALES CHIARG START
            Id opportunityId;
            if(LeadIds.size() >0){
                List<Lead> ldLIst = new List<Lead>();
                for(Lead ld :[SELECT Id,OwnerId FROM Lead WHERE Id =:LeadIds]){
                    ld.OwnerId = System.Label.Digital_SalesManager;
                    ldLIst.add(ld);
                }
                 LeadFirstMethodOfContactService.skipLeadTrigger = true;
                    update ldLIst;
                    LeadFirstMethodOfContactService.skipLeadTrigger = false;
                List<Database.LeadConvertResult> leadConversionResult = UtilitiesWithoutSharing.convertLeads(LeadIds);
                opportunityId = leadConversionResult[0].getOpportunityId();
            }
            List<Communication_Preference__c> cpList= new List<Communication_Preference__c>();
            for(Communication_Preference__c cp :[SELECT Id,Opportunity__c FROM Communication_Preference__c WHERE Lead__c =:LeadIds]){
                cp.Opportunity__c = opportunityId;
                cpList.add(cp);
            }
            if(cpList.size() >0){
                update cpList;
            }
            
            if(digitalSPAIds.size() >0){
                System.enqueueJob(new DigitalSPAQueueable(digitalSPAIds,'DigitalSPA'));
            }


            if(AccrecordIds.size() >0 && !Test.isRunningTest()){
                 Database.executeBatch(new SendWhatsAppLinkWithBitly(AccrecordIds,'FastTrack'),1);
            }
            
        } catch(Exception e) {
           /* String htmlEmailBody = 'Hello,</br></br> DigitalExpTriggerHandler afterUpdateMethod has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b>  ';
            Utilities.sendExceptionEmail('DigitalExpTriggerHandler','afterUpdateMethod',htmlEmailBody,'DigitalExpTriggerHandler afterUpdateMethod',e); */
            LoggerService.save(LoggerService.addApexLog(e,'Communication Preference Record Update Failed','DigitalExpTriggerHandler','afterUpdateMethod')); // Added by Tajinkumar
        }
    }
    
}