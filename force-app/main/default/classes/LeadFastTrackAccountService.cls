public class LeadFastTrackAccountService {
    public static Boolean skipAccountTrigger = false;
    
    public static void updateBrokerLeads(List<Lead> newList){
        String recordTypeName = Constants.PERSON_ACCOUNT_RT;
        Map<Id,Account> mapLeadIdToAccounts = new Map<Id,Account>();
        Boolean applicableForAllProjects = System.Label.LeadFasttrackProjects.equalsIgnoreCase('All');
        List<String> LeadFasttrackProjects = System.Label.LeadFasttrackProjects.split(';');
        List<Lead> leadToUpdateList = new List<Lead>();
        Set<String> leadEmailSet = new Set<String>();
        Set<String> phoneNoSet = new Set<String>();
        //Map<String, List<Account>> accountEmailPhoneMap = new Map<String, List<Account>>();
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
        
        try{
            for(Lead lead : newList){
                if(String.isNotBlank(lead.Email) && lead.ExistingAccount__c == null){
                    leadEmailSet.add(lead.Email);
                }
                if(String.isNotBlank(lead.MobilePhone) && lead.ExistingAccount__c == null){
                    phoneNoSet.add(lead.MobilePhone);
                }
            }
            
            if(!leadEmailSet.isEmpty() || !phoneNoSet.isEmpty()){
                accountEmailPhoneMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(leadEmailSet);
            } 
            System.debug('accountEmailPhoneMap '+accountEmailPhoneMap);
            
            for(Lead leadRec : newList){
                String emailPhoneKey = leadRec.Email;//leadRec.Email+'-'+leadRec.MobilePhone;
                System.debug('emailPhoneKey '+emailPhoneKey);
                if(accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(emailPhoneKey) && accountEmailPhoneMap.get(emailPhoneKey) != null ){
                    Lead lead = new Lead(Id=leadRec.Id, ExistingAccount__c = accountEmailPhoneMap.get(emailPhoneKey)[0].account.Id);
                    leadToUpdateList.add(lead);
                    
                } else if(leadRec.ExistingAccount__c == null ){// removed logic to create ExistingAccount for Every Lead //&& (applicableForAllProjects || LeadFasttrackProjects.contains(leadRec.Project__c)
                    Account acnt = creatAccount(leadRec);
                    mapLeadIdToAccounts.put(leadRec.Id, acnt);
                }
            }
            
            if(!mapLeadIdToAccounts.values().isEmpty()){
                if(Auth.CommunitiesUtil.isGuestUser()){
                	skipAccountTrigger = true;
                    Insert mapLeadIdToAccounts.values();
                    skipAccountTrigger = false;  
                }else{
                    Insert mapLeadIdToAccounts.values();
                }
                
                for(Lead ld: [SELECT Id, ExistingAccount__c FROM Lead WHERE Id IN :mapLeadIdToAccounts.keySet()]){
                    if(ld.ExistingAccount__c == NULL && mapLeadIdToAccounts.containsKey(ld.Id) && mapLeadIdToAccounts.get(ld.Id).Id != null) {
                        Lead leadToUpdate = new Lead(Id = ld.Id, ExistingAccount__c = mapLeadIdToAccounts.get(ld.Id).Id);
                        leadToUpdateList.add(leadToUpdate);
                    }
                }
            }
            
            if(!leadToUpdateList.isEmpty()){
                LeadFirstMethodOfContactService.skipLeadTrigger = true;
                update leadToUpdateList;
                LeadFirstMethodOfContactService.skipLeadTrigger = false;
            }
            
            
        }catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'LeadFastTrackAccountService','updateBrokerLeads',''));
            String htmlEmailBody = 'Hello,</br></br> LeadFastTrackAccountService updateBrokerLeads has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'LeadFastTrackAccountService updateBrokerLeads', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        }
    }
    
    public static Account creatAccount(Lead leadRec){
        String recordTypeName = Constants.PERSON_ACCOUNT_RT;
        Account ac = new Account();
        
        ac.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        ac.FirstName = leadRec.FirstName;
        ac.LastName = leadRec.LastName;
        ac.PersonEmail = leadRec.Email;
        UnifiedAccountController.getCustomerVertical(ac, leadRec);
        ac.MobileCountryCode__c = leadRec.CountryCode;
        /*if(leadRec.MobileNumber1__c != null){
            ac.MobilePhone__pc = leadRec.MobileNumber1__c;
        }*/
        ac.PersonMobilePhone = leadRec.MobilePhone; 
        ac.BankEmail__c = leadRec.Bank_Email__c;
        ac.BrokerAgent__c = leadRec.BrokerAgent__c;
        ac.CorporateWealthName__c = leadRec.CorporateWealthName__c;
        ac.CustomerSubType__c = leadRec.CustomerSubType__c;
        ac.CustomerType__c = leadRec.CustomerType__c;
        ac.Date_of_Birth__c = leadRec.Date_of_Birth__c;
        ac.NameInArabic__c = leadRec.NameArabic__c;
        ac.PlaceOfRegistration__c = leadRec.PlaceOfRegistration__c;
        ac.RegistrationExpiryDate__c = leadRec.RegistrationExpiryDate__c;
        ac.RegistrationIssueDate__c = leadRec.RegistrationIssueDate__c;
        ac.RegistrationNumber__c = leadRec.RegistrationNumber__c;
        //ac.ResidentialAddressSameAsPermanent__c = leadRec.ResidentialAddressSameAsPermanent__c;
        ac.Salutation_AR__c = leadRec.SalutationAR__c;
        ac.Salutation = leadRec.Salutation;
        ac.TradeName__c = leadRec.TradeName__c;
        ac.UAEVATRegisterNumber__c = leadRec.UAEVATRegisterNumber__c;
        ac.UnifiedNumber__c = leadRec.UnifiedNumber__c;                
        ac.NationalIdNumber__pc = leadRec.NationalId__c;
        ac.Nationality__pc = leadRec.Nationality__c;
        ac.ResidentStatus__pc = leadRec.ResidentStatus__c;
        ac.CountryOfResidence__pc = leadRec.CountryOfResidence__c;
        ac.PurposeofBuying__c = leadRec.PurposeOfUse__c;
        ac.Sync_with_SFMC__pc = true;
        ac.Sync_with_SFMC__c = true;
//        ac.AllowLiveAldarRegistration__c = true;
        ac.ProspectAccount__c = true;
        ac.OwnerId = System.Label.AldarDevelopmentUser;
        
        return ac;
    }
    
    @InvocableMethod(label='updateFastTrackSentTime' description='updateFastTrackSentTime') 
    public static void updateFastTrackSentTime( List<Id> accountIds ) {
        updateAccount( accountIds );
    }
    @future
    public static void updateAccount(List<Id> accountIds){
        try{
            Account ac = new Account(Id = accountIds[0], FasttrackSentTime__c = DateTime.parse(System.Now().format()));
            
            skipAccountTrigger = true;
            update ac;
            skipAccountTrigger = false;
        }catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'LeadFastTrackAccountService','updateFastTrackSentTime',''));
            String htmlEmailBody = 'Hello,</br></br> LeadFastTrackAccountService updateFastTrackSentTime has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'LeadFastTrackAccountService updateFastTrackSentTime', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        }
        
    }
    
}