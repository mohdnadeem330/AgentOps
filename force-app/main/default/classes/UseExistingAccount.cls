public without sharing class UseExistingAccount {
    
    // Duplicate Account related changes
    @AuraEnabled 
    public static List<UtilitiesWithoutSharing.DuplicateAccountWrapper> getAccountDuplicate(String nationalId,String passPortNumber, String nationality, Date dateofBirth){
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> duplicateWrapper = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
        String dt = '';
        if(dateofBirth !=null){
            Integer year = dateofBirth.year();
            Integer month = dateofBirth.month();
            Integer day = dateofBirth.day();
            dt = String.valueOf(year) + '-' + 
                            (month < 10 ? '0' + month : String.valueOf(month)) + '-' + 
                            (day < 10 ? '0' + day : String.valueOf(day));
        }
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> mapofDuplicateWrapper = UtilitiesWithoutSharing.findDuplicateAccountsByEmirateIdPassport(nationalId, passPortNumber,nationality,dt);
        for(String keyStr : mapofDuplicateWrapper.keySet()){
            duplicateWrapper.addAll(mapofDuplicateWrapper.get(keyStr));
        }
        return duplicateWrapper;
    }
    
     // Duplicate Account related changes
    
    @AuraEnabled
    public static List<Account> getAccount(String recId,String nationalId,String passPortNumber, String nationality, Date dateofBirth){
        List<Account> lstToReturn = new List<Account>();
        String soqlQuery = 'SELECT Id,Name,ResidentStatus__pc,NationalIdNumber__pc,PassportNumber__pc,Nationality__pc,PersonBirthdate,SkipDuplicateApprovalStatus__c from Account WHERE';
        if(!String.isBlank(nationalId)){
            soqlQuery = soqlQuery + ' NationalIdNumber__pc =\''+nationalId+'\'';
        }
        if(!String.isBlank(passPortNumber)){
            if(soqlQuery.contains('=')){
                soqlQuery = soqlQuery + ' AND PassportNumber__pc =\''+passPortNumber+'\'';
            }else{
            	soqlQuery = soqlQuery + ' PassportNumber__pc =\''+passPortNumber+'\'';
            }
        }
        if(!String.isBlank(nationality)){
            if(soqlQuery.contains('=')){
                soqlQuery = soqlQuery + ' AND Nationality__pc =\''+nationality+'\'';
            }else{
            	soqlQuery = soqlQuery + ' Nationality__pc =\''+nationality+'\'';
            }
        }
        if(dateofBirth !=null){
            Integer year = dateofBirth.year();
            Integer month = dateofBirth.month();
            Integer day = dateofBirth.day();
            String dt = String.valueOf(year) + '-' + 
                            (month < 10 ? '0' + month : String.valueOf(month)) + '-' + 
                            (day < 10 ? '0' + day : String.valueOf(day));
            
            if(soqlQuery.contains('=')){
                soqlQuery = soqlQuery + ' AND PersonBirthdate ='+dt;
            }else{
            	soqlQuery = soqlQuery + ' PersonBirthdate = '+dt;
            }
        }
        soqlQuery = soqlQuery + ' AND Id !=\''+recId+'\'';
        system.debug('soqlQuery:'+soqlQuery);
        lstToReturn = Database.query(soqlQuery);
        return lstToReturn;
    }
    
     // Duplicate Account related changes
    @AuraEnabled
    public static Boolean updateOpportunity(Id newId, Id existingId){
        Boolean havingIssue = false;
        List<Opportunity> lstToUpdate = new List<Opportunity>();
        Set<Id> accIds = new Set<Id>{newId,existingId}; 
        for(Opportunity opp:[SELECT Id,AccountId from Opportunity WHERE AccountId =:existingId AND ISClosed=False AND OWNERID =:Userinfo.getUserId() ]){
            opp.AccountId = newId;
            lstToUpdate.add(opp);
        }
       if(!lstToUpdate.isEmpty()){
            try{
                update lstToUpdate;
                havingIssue = false;
                List<Account> lstAccount = [SELECT Id, Name, FirstName,CustomerVertical__c, LastName, PersonEmail, MobileCountryCode__pc, MobilePhone__pc, Nationality__pc, NationalIdNumber__pc, BillingCountry, AllowLiveAldarRegistration__c, ERPID__c FROM Account WHERE Id IN : accIds];
                Case caseObj = CustomerProfileWebservice.createCaseHelper(lstAccount,false);
                insert caseObj;
            }catch(Exception e){
                LoggerService.save(LoggerService.createApexLog(e,'existingId','UseExistingAccount','updateOpportunity'));
                havingIssue = true;
            }
        }
        return havingIssue;
    }
    // Account Duplicate logic changes: Get accounts without sharing
    public static List<Account> getDuplicateAccounts(Set<String> emiratesId, Set<String> passportSet, Set<String> nationalitySet, Set<Date> dateOfBirthSet){
        return [SELECT ID,ResidentStatus__pc,NationalIdNumber__pc,PassportNumber__pc,Nationality__pc,PersonBirthdate FROM Account WHERE NationalIdNumber__pc IN:emiratesId OR PassportNumber__pc IN:passportSet OR Nationality__pc IN:nationalitySet OR PersonBirthdate IN:dateOfBirthSet];
    }
     // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
     // Created a new method to get duplicate account based on email and mobile number
     public static List<UtilitiesWithoutSharing.DuplicateAccountWrapper> findDuplicateAccountsByEmailAndMobileNumber(Set<String> EmailSet, Set<String> mobileNumbers) {
        if(System.Label.DuplicateAccountEnable.trim().toUpperCase() == 'FALSE'){
            return new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
        }
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> dupeWrapperMap = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
        
        String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        String accountWhrClause = ' ( RecordType.Name = \'' + Constants.PERSON_ACCOUNT_RT + '\')';
        String query = 'SELECT Id, Name, PersonEmail,EmailApprovalsReason__c,PassportNumber__pc,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,SkipLiveAldarReason__c,CustomerSubType__c,NationalIdNumber__pc,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c,PersonBirthdate,PassportExpiryDate__pc,BlacklistReason__c,SkipDuplicateApprovalStatus__c,VIPClass__c,CustomerAppWebUser__c,Nationality__pc,PersonMobilePhone,FastTrackedAccount__c,ScreeningStatus__c,NationalIdExpiryDate__pc, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ),(SELECT Id,LastModifiedDate,DocumentType__c FROM Documents__r WHERE (DocumentType__c=\'Signed KYC Form\' OR DocumentType__c=\'Signed CIS Sheet\') AND Status__c =\'Uploaded\' ORDER BY LastModifiedDate ASC)  FROM Account WHERE '+accountWhrClause+' AND (PersonMobilePhone IN :mobileNumbers OR PersonEmail IN :EmailSet) AND MergedAccount__c= false ORDER BY CreatedDate DESC';                
        System.debug('Print acc query '+query);
        //Execute the query 
        List<Account> queriedAccounts = Database.query(query);
        
        if(!queriedAccounts.isEmpty() && queriedAccounts.size() > 0){
            
            for(Account ac : queriedAccounts){
                UtilitiesWithoutSharing.DuplicateAccountWrapper wrapper = new UtilitiesWithoutSharing.DuplicateAccountWrapper();
                wrapper.account = ac;
                wrapper.salesOrderCount = ac.Opportunity_Units__r.size() > 0 ? ac.Opportunity_Units__r.size() : 0;
                dupeWrapperMap.add(wrapper);
            }
        }
        
        return dupeWrapperMap;
    }
    
}