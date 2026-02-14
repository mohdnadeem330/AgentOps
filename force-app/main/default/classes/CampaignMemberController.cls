public without Sharing class CampaignMemberController {
    public static Boolean skipAccountTrigger = false;
    public static void createCampaignMember(List<Lead> leadList){
        try{
         List<Campaign_member_Custom__c> newCampaignMembers = new List<Campaign_member_Custom__c>();
        Map<Id, Id> mapAccountWithContact = new Map<Id, Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> ProjectNames = new Set<String>();
        Map<String,Id> ProjectNameMap = new Map<String,Id>();
        Map<String,Id>AccMap = new Map<String,Id>();
        List<Account> accLIst = new List<Account>();
        Set<String> leadEmailSet = new Set<String>();
        Set<String> phoneNoSet = new Set<String>();
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
        List<Lead> LdList = [SELECT Id,CreatedById,FirstName,NationalId__c,BrokerAgent__c,CorporateWealthName__c,TradeName__c,Date_of_Birth__c,RegistrationNumber__c,RegistrationIssueDate__c,RegistrationExpiryDate__c,PlaceOfRegistration__c,NameArabic__c,UnifiedNumber__c,UAEVATRegisterNumber__c,Bank_Email__c,LastName,CountryCode,Email,MobileNumber1__c,MobilePhone,ExistingAccount__c, ExistingAccount__r.Sync_with_SFMC__pc,ExistingAccount__r.Sync_with_SFMC__c,ExistingAccount__r.RecordTypeId,ExistingAccount__r.CustomerVertical__c,CustomerType__c,CustomerSubType__c,ResidentStatus__c,Lead_Type__c,LeadSubType__c,CustomerLocation__c,Nationality__c,CountryOfResidence__c,Address,SalesType__c,PurposeOfUse__c,PropertyUsage__c,   PropertyReadiness__c,BuyRent__c,Financing__c,Project__c,UnitType__c,CustomerBudget__c,NumberOfBedrooms__c,SalesOrigin__c,LeadOrigin__c,LeadSource,EnquiryCategory__c,EnquiryTrigger__c,Offer1__c,SalutationAR__c,Salutation,MobileCountryCode__c,InitiateDigitalBooking__c, RecordTypeId,Campaign_Name__c,BrokerAgency__c,BrokerAgency__r.AgencySubCategory__c FROM Lead WHERE Id=:leadList];//Added Camapign name and team in query by nikhil mehra
        Map<Id, Account> accountMap = new Map<Id, Account>();
        
        //added by Nikhil Mehra 02/10/25
        Map<Id,User> userMap = new Map<Id,User>();
        Set<Id> userIds = new Set<Id>();
        Map<Id,Id> leadIdToUserIdMap = new Map<Id,Id>();

        for (Lead newLead : LdList) {

            if(String.isNotBlank(newLead.Email) && newLead.ExistingAccount__c == null){
                    leadEmailSet.add(newLead.Email);
                }
                if(String.isNotBlank(newLead.MobilePhone) && newLead.ExistingAccount__c == null){
                    phoneNoSet.add(newLead.MobilePhone);
                }
             accountIds.add(newLead.ExistingAccount__c);
             ProjectNames.add(newLead.Project__c);
             userIds.add(newLead.CreatedById);//added by Nikhil Mehra 02/10/25
             /*if(newLead.ExistingAccount__c != NULL && UnifiedAccountController.manageSFMCAccount(newLead.ExistingAccount__r) != NULL) {
                Account acc = UnifiedAccountController.manageSFMCAccount(newLead.ExistingAccount__r);
                acc = UnifiedAccountController.getCustomerVertical(acc, newLead);
                accountMap.put(newLead.ExistingAccount__c, acc);
             }*/

        }
        //added by Nikhil Mehra 02/10/25
        if(userIds.size() > 0){
            userMap = getUserByIds(userIds);
        }
       
        if(!leadEmailSet.isEmpty() || !phoneNoSet.isEmpty()){
           accountEmailPhoneMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(leadEmailSet);
         }
        for(Lead ld : LdList){
            if(ld.ExistingAccount__c == null){
                String emailPhoneKey = ld.Email;
                if(accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(emailPhoneKey) && accountEmailPhoneMap.get(emailPhoneKey) != null ){
                    for(UtilitiesWithoutSharing.DuplicateAccountWrapper ac :accountEmailPhoneMap.get(emailPhoneKey)){
                        accountIds.add(ac.account.Id);

                        /*if(ac.account.Id != NULL && UnifiedAccountController.manageSFMCAccount(ac.account) != NULL) {
                            Account acc = UnifiedAccountController.manageSFMCAccount(ac.account);
                            accountMap.put(ac.account.Id, acc);
                        }*/
                    }
                }else if(ld.RecordTypeId == Constants.PERSON_LEAD_RT_ID){
                    Account acc = CampaignMemberController.creatAccount(ld);
                    accLIst.add(acc);
                }
            }
        }
        
        if(accLIst.size() >0){
            if(Auth.CommunitiesUtil.isGuestUser()){
                skipAccountTrigger = true;
                insert accLIst;
                skipAccountTrigger = false;
            }else{ 
                insert accLIst;
            }
        }
        for(Account acc :accLIst){
           accountIds.add(acc.Id);
        }
        for(Campaign_Custom__c cc :[SELECT Id,Name FROM Campaign_Custom__c WHERE Project_Name__c=:ProjectNames]){
            ProjectNameMap.put(cc.Name,cc.Id);
        }
        for (Account ac : [SELECT Id, PersonContactId,PersonEmail,PersonMobilePhone FROM Account WHERE Id IN :accountIds ORDER BY CreatedDate ASC]) {
            mapAccountWithContact.put(ac.Id , ac.PersonContactId);
            AccMap.put(ac.PersonEmail, ac.Id);
            
        } 
        List<Lead> DigitalLeads = new List<Lead>();//DIGITAL SALES CHIARG START
        for(Lead leadRec:LdList){
            if (leadRec.LastName != null && leadRec.Campaign_Name__c != 'LondonSquareMarketingAsia' 
                && leadRec.Campaign_Name__c != 'SquareRootsMarketing' 
                && leadRec.Campaign_Name__c != 'LondonSquareMarketing'
                && userMap.get(leadRec.CreatedById).Team__c != 'LSQ' 
                && (leadRec.BrokerAgency__c == null || (leadRec.BrokerAgency__c != null && leadRec.BrokerAgency__r.AgencySubCategory__c != 'LSQ broker'))
                ) {// modify by Nikhil mehra 02/10/25
                 ////DIGITAL SALES CHIARG START
                 if(leadRec.InitiateDigitalBooking__c == true ){
                    if(leadRec.ExistingAccount__c == null && AccMap.containsKey(leadRec.Email)){
                        leadRec.ExistingAccount__c =AccMap.get(leadRec.Email);
                    }
                    leadRec.OwnerId = System.label.Digital_SalesManager; 
                    DigitalLeads.add(leadRec);
                }
                //DIGITAL SALES CHIARG END
            Campaign_member_Custom__c newCampaignMember = new Campaign_member_Custom__c();
                if(leadRec.ExistingAccount__c != null){
                    newCampaignMember.Existing_Account__c = leadRec.ExistingAccount__c;
                }else if(AccMap.containsKey(leadRec.Email)){
                    newCampaignMember.Existing_Account__c = AccMap.get(leadRec.Email);
                }
            
            newCampaignMember.Lead__c = leadRec.Id;
            newCampaignMember.Name = leadRec.FirstName +' '+leadRec.LastName;
            newCampaignMember.Campaign_Custom__c = ProjectNameMap.get(leadRec.Project__c+' Campaign');
            if (mapAccountWithContact != null && mapAccountWithContact.containsKey(newCampaignMember.Existing_Account__c)) {
                newCampaignMember.Contact_ID__c = mapAccountWithContact.get(newCampaignMember.Existing_Account__c);
            }
               
            newCampaignMembers.add(newCampaignMember);
            }
        }        
        //ASF - 3152 Insert new Campaign_member_Custom__c records if there are any
        if (!newCampaignMembers.isEmpty()) {
            insert newCampaignMembers;
        }
        //DIGITAL SALES CHIARG START
        if(DigitalLeads.size() >0){
            LeadFirstMethodOfContactService.skipLeadTrigger = true;
            update DigitalLeads;
            LeadFirstMethodOfContactService.skipLeadTrigger = false;
        }
        //DIGITAL SALES CHIARG END
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'CampaignMemberController','createCampaignMember',''));
            /*String htmlEmailBody = 'Hello,</br></br> CampaignMemberController createCampaignMember has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + ex.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + ex.getStackTraceString() + ' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');*/
            //Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'createCampaignMember Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        }
    }
    
    public static Map<Id, User> getUserByIds(Set<Id> userIds){
        return new Map<Id, User>(
            [SELECT Id, Name, Team__c,Email,ProfileName__c FROM User WHERE Id IN :userIds]
        );
    }
     public static Account creatAccount(Lead leadRec){
        String recordTypeName = Constants.PERSON_ACCOUNT_RT;
        Account ac = new Account();
        ac.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        UnifiedAccountController.getCustomerVertical(ac, leadRec);
        ac.FirstName = leadRec.FirstName;
        ac.LastName = leadRec.LastName;
        ac.PersonEmail = leadRec.Email;
        ac.MobileCountryCode__pc = leadRec.MobileCountryCode__c;
        /*if(leadRec.MobileNumber1__c != null){
            ac.MobilePhone__pc = leadRec.MobileNumber1__c;
        }*/
        ac.MobilePhone__pc = leadRec.MobileNumber1__c != null ? leadRec.MobileNumber1__c : leadRec.MobilePhone; // Added by Tajinkumar LAV-395
        ac.PersonMobilePhone = leadRec.MobilePhone; 
        ac.BankEmail__c = leadRec.Bank_Email__c;
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
        //ac.OwnerId = System.Label.AldarDevelopmentUser;
        
        return ac;
    }
}