@RestResource(urlMapping='/Ecss_ExistingCustomerUpdate')
global without sharing class ECSS_CustomerUpdateWebService {
    @HttpPost
    global static void UpdateExistingCustomer() {
        RestContextHandler handler = new RestContextHandler(false);
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestBody = req.requestBody.toString();
        system.debug('requestBody==> '+requestBody);
        
        String modifiedRequestBody = requestBody;
        system.debug('modifiedRequestBody==> '+modifiedRequestBody);
        Object parsed = JSON.deserializeUntyped(modifiedRequestBody);
        Map<String, Object> requestMap = parsed instanceof List<Object> ? (Map<String, Object>)
            (((List<Object>)parsed)[0]):(Map<String, Object>)parsed;
        
        //Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(modifiedRequestBody);
        
        String emailId = (String) requestMap.get('PersonEmail');
        String emiratesId = (String) requestMap.get('NationalIdNumber__pc');
        String mobileNumber = (String) requestMap.get('PersonMobilePhone');
        String FirstName = (String) requestMap.get('FirstName');
        String LastName = (String) requestMap.get('LastName');
        String PassportNumber = (String) requestMap.get('PassportNumber__pc');
        String OrgEmail = (String) requestMap.get('Email__c');
        String recordtypeId = (String)requestMap.get('RecordTypeId');
        String RegistrationNumber = (String)requestMap.get('RegistrationNumber__c');
        String RecordType ='';
        string personAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId() ;
        string orgAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId() ;
        string sapAccId = (String) requestMap.get('SapAccountID__c');
        
        
        try{ 
            
            
            String accountWhrClause ='';
            String query = '';
            if(recordtypeId == personAccountRT){
               accountWhrClause = '  RecordTypeId = \'' + personAccountRT + '\' ';
                
                accountWhrClause +=' AND MergedAccount__c = false ';
                Boolean hasEmail = !String.isBlank(emailId);
                Boolean hasMobile = !String.isBlank(mobileNumber);
                Boolean hasEmiratesId = !String.isBlank(emiratesId);
                Boolean hasPassport = !String.isBlank(PassportNumber);
                 List<String> idConditions = new List<String>();
                if(hasEmail || hasEmiratesId || hasPassport){
                	accountWhrClause += ' AND (';
                    if (hasEmiratesId) {
                        idConditions.add('NationalIdNumber__pc = \'' + emiratesId + '\'');
                    }
                    if (hasPassport) {
                        idConditions.add('PassportNumber__pc = \'' + PassportNumber + '\'');
                    }
                    if (hasEmail) {
                        idConditions.add('personEmail = \'' + emailId + '\'');
                    }
                    if(!string.isBlank(sapAccId) ){
                        idConditions.add('SapAccountID__c = \'' + sapAccId + '\'');
                    }
                	accountWhrClause += String.join(idConditions, ' OR ') + ')';
                }
                // Start of OR conditions group
                
               /* if (hasEmail && (hasMobile || hasEmiratesId || hasPassport)) {
                    accountWhrClause += ' AND (';
                    
                    if (hasEmail && hasMobile) {
                        accountWhrClause += '(personEmail = \'' + emailId + '\' AND PersonMobilePhone = \'' + mobileNumber + '\')';
                    }
                    
                    if (hasEmail && (hasEmiratesId || hasPassport)) {
                        if (hasEmail && hasMobile) {
                            accountWhrClause += ' OR ';
                        }
                        accountWhrClause += '(personEmail = \'' + emailId + '\' AND (';
                        
                       
                        
                        accountWhrClause += String.join(idConditions, ' OR ') + '))';
                    }
                    
                    accountWhrClause += ')';
                }*/
            }

            //Org account fileds
            
            String orgaccountWhrClause ='';
            if(recordtypeId == orgAccountRT){
                List<String> idConditions = new List<String>();
                orgaccountWhrClause = '  RecordTypeId = \'' + orgAccountRT + '\' ';
                  if(!String.isBlank(RegistrationNumber) || !String.isBlank(OrgEmail) ){
                    orgaccountWhrClause += ' AND (';
                    if(!String.isBlank(RegistrationNumber)){
                        idConditions.add('RegistrationNumber__c = \'' + RegistrationNumber + '\'');
                    }
                    if(!String.isBlank(OrgEmail)){
                         idConditions.add('Email__c = \'' + OrgEmail + '\'');
                    }
                     if(!string.isBlank(sapAccId) ){
                        idConditions.add('SapAccountID__c = \'' + sapAccId + '\'');
                    }
                	orgaccountWhrClause += String.join(idConditions, ' OR ') + ')';
                  }
            }
            /*if(!String.isBlank(Name)){
orgaccountWhrClause += 'AND Name =\''+Name+'\' ';
}*/
            String whereClause ='';
            if(orgaccountWhrClause != ''){
                whereClause = ' (' + orgaccountWhrClause.trim() + ')'; 
            }else{
                whereClause = '(' + accountWhrClause.trim() + ')'; 
            }
            
            
            String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
            query = 'SELECT Id,Name,SapAccountID__c,PersonEmail,CustomerVertical__c,(SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ) FROM Account WHERE '+whereClause;
            system.debug('Generated SOQL Query==> '+query);
            List<Account> queriedAccounts = Database.query(query);
            system.debug('No.of queriedAccounts==> '+queriedAccounts);
            if(queriedAccounts.size() ==1){
                Account acc = new Account();
                acc.Id =queriedAccounts[0].Id;
                system.debug('Queried Account Id:' +acc.Id);
                if(String.isBlank(acc.Id)){
                    throw new CustomException('Account Id is missing.Cannot perform update.');
                }
                if(queriedAccounts[0].SapAccountID__c ==null){
                    Set<String> verticals = new Set<String>();
                    System.debug((String)requestMap.get('SapAccountID__c'));
                    acc.SapAccountID__c =(String)requestMap.get('SapAccountID__c'); 
                    system.debug('acc.SapAccountID__c==> '+acc.SapAccountID__c);
                    if (queriedAccounts[0].CustomerVertical__c != null) {
                        verticals.addAll(queriedAccounts[0].CustomerVertical__c.split(';'));
                    }else{
                        acc.CustomerVertical__c = 'Aldar Estates';
                        verticals.add('Aldar Estates');
                    }
                    if (!verticals.contains('Aldar Estates')) {
                        acc.CustomerVertical__c =  queriedAccounts[0].CustomerVertical__c + ';Aldar Estates';
                    }
                    update acc;
                    handler.response.success = true;
                    handler.response.data = acc ;
                    handler.response.message ='Account updated successfully';
                    handler.finalize();
                }else if(queriedAccounts[0].SapAccountID__c !=null && queriedAccounts[0].SapAccountID__c != (String)requestMap.get('SapAccountID__c')){
                    Account newacc =createAccount(requestMap);
                    handler.response.success = true;
                    handler.response.data = newacc ;
                    handler.response.message ='Account Created with SAPId';
                    handler.finalize();
                    
                }
                else{
                    acc.SapAccountID__c = (String)requestMap.get('SapAccountID__c');
                    handler.response.success = true;
                    handler.response.data = acc ;
                    handler.response.message ='Account already having Sap Account Id';
                    handler.finalize();
                }
                
                
                
                
                
            }else if(queriedAccounts.size() >1){
                Boolean ismatchedAc = false;
                for(Account acc : queriedAccounts){
                        if(acc.SapAccountID__c == (String) requestMap.get('SapAccountID__c'))	{
                           ismatchedAc = true;
                        }
                 }
                Account Acrec = new Account();
                if(ismatchedAc == false){
                Integer Count =0;
                Account aa;
                for(Account acc : queriedAccounts){
                    Integer SalesOrderCount =acc.Opportunity_Units__r != null ? acc.Opportunity_Units__r.size() : 0;
                    if((Count == 0 || SalesOrderCount > Count) && acc.SapAccountID__c ==null){
                        count = acc.Opportunity_Units__r != null ? acc.Opportunity_Units__r.size() : 0;
                        aa = acc;
                    }
                }
                list<Account> accsListToUpdate = new list<Account>();
                
                if(aa != null){
                    for (Account accRecord : [SELECT Id,CustomerVertical__c,SapAccountID__c FROM Account WHERE Id=:aa.Id]){
                        Acrec = accRecord;
                        if(accRecord.SapAccountID__c == null){
                            Set<String> verticals = new Set<String>();
                            accRecord.SapAccountID__c =(String) requestMap.get('SapAccountID__c'); 
                            if (accRecord.CustomerVertical__c != null) {
                                verticals.addAll(accRecord.CustomerVertical__c.split(';'));
                            }else{
                                accRecord.CustomerVertical__c = 'Aldar Estates';
                                verticals.add('Aldar Estates');
                            }
                            if (!verticals.contains('Aldar Estates')) {
                                accRecord.CustomerVertical__c =  accRecord.CustomerVertical__c + ';Aldar Estates';
                            }
                            accsListToUpdate.add(accRecord);
                            Acrec = accRecord;
                        }
                    }
                    if(!accsListToUpdate.isEmpty()){
                        update accsListToUpdate;
                    }
                }
                }else{
                    Boolean ismatched = false;
                    for(Account acc : queriedAccounts){
                        if(acc.SapAccountID__c == (String) requestMap.get('SapAccountID__c'))	{
                           ismatched = true;
                            Acrec = acc;
                        }
                    }
                    if(!ismatched && queriedAccounts.size() >0){
                            Account newacc =createAccount(requestMap);
                            handler.response.success = true;
                            handler.response.data = newacc ;
                            handler.response.message ='Account Created with SAPId';
                            handler.finalize();
                        Acrec = newacc;
                    }
                }
                system.debug('queriedAccounts==> '+queriedAccounts.size());
                Case cs = new Case();
                Group queue = Utilities.getQueueInformation('MergeCaseQueue');
                system.debug('queue ==> '+queue);
                system.debug('queue.Id ==> '+queue.Id);
                
                
                String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();
                
                Case newCase   = new Case();
                newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
                newCase.CustomerType__c = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
                newCase.Origin  = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
                newCase.AccountId     = queriedAccounts[0].Id;
                system.debug('newCase.AccountId before insert ==> '+newCase.AccountId);
                newCase.SubVertical__c  = 'Customer Portal and App - Live Aldar';
                newCase.CaseCategory__c   = 'Data - Account Merge';
                newCase.Subject   = CustomerAPIConstants.MULTI_ACCOUNT_FOUND_SUBJECT + ' ' + queriedAccounts[0].PersonEmail;
                // newCase.CustomerComment__c = isRegistration ? CustomerAPIConstants.MULTI_ACCOUNT_FOUND_REGISTRATION : CustomerAPIConstants.MULTI_ACCOUNT_FOUND_LOGIN;
                newCase.OwnerId    = caseOwnerId;
                newCase.isValidationBypass__c = true;
                //newCase.IsEcssCase__c=true;
                system.debug('newCase before insert ==> '+newCase);
                insert newCase;
                system.debug('newCase==> '+newCase);
                
                
                // Creating Logger Record
                Logger__c newLog = new Logger__c();newLog.Message__c = 'Many Accounts are there';newLog.ExecutingProcessName__c = 'Ecss Customer update';newLog.ResponseMessage__c = 'Many Accounts are there with name/Email';newLog.ExceptionMessage__c = requestBody;newLog.ExecutingProcessName__c = 'Ecss Customer update API';newLog.ClassName__c = 'ECSS_CustomerUpdateWebService';newLog.MethodName__c = 'UpdateExistingCustomer';insert newLog;
                handler.response.success = true;
                handler.response.data = Acrec;
                handler.response.message ='Merge case Created as Duplicate Accounts Found!';
                handler.finalize();
                
                system.debug('newLog==> '+newLog);
            }else{
                Account newacc =createAccount(requestMap);
                handler.response.success = true;
                handler.response.data = newacc ;
                handler.response.message ='Account Created with SAPId';
                handler.finalize();
            }
            
            
        }catch(Exception ex){
            System.debug('Exception  '+ex.getMessage());
            System.debug('Exception '+ex.getLineNumber());
            Logger__c lgs = LoggerService.createApexLog(ex,'EcssCustomerUpdate','ECSS_CustomerUpdateWebService','UpdateExistingCustomer');
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);  
        }
        
    }
    public static Account createAccount(Map<String, Object> requestMap){
        String personTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        String orgTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
         String recordtypeId = (String)requestMap.get('RecordTypeId');
        String RecordType ='';

        Account newacc = new Account();
        newacc.RecordTypeId = recordtypeId ;
        if( recordtypeId == orgTypeId){
            newacc.TradeName__c = (String) requestmap.get('TradeName__c');
            newacc.Name = (String) requestmap.get('Name');
            newacc.Phone = (String) requestmap.get('Phone');
            newacc.RegistrationNumber__c = (String) requestmap.get('RegistrationNumber__c');
            if (requestMap.get('RegistrationExpiryDate__c') != null)
                newacc.RegistrationExpiryDate__c = Date.valueOf((String) requestMap.get('RegistrationExpiryDate__c'));
            newacc.Email__c = (String) requestmap.get('Email__c');
            
        }else{
            newacc.LastName = (String) requestmap.get('LastName');
            newacc.FirstName = (String) requestmap.get('FirstName');
            newacc.Salutation = (String) requestmap.get('Salutation');
            newacc.PersonEmail = (String) requestmap.get('PersonEmail');
            if (requestMap.get('PersonBirthdate') != null)
                newacc.PersonBirthdate = Date.valueOf((String) requestMap.get('PersonBirthdate'));
            newacc.NationalIdNumber__pc = (String) requestmap.get('NationalIdNumber__pc');
            newacc.CustomerVertical__c = (String) requestmap.get('CustomerVertical__c');
            newacc.SapAccountID__c = (String) requestmap.get('SapAccountID__c');
            newacc.CountryOfResidence__pc = (String) requestmap.get('CountryOfResidence__pc');
            newacc.Nationality__pc = (String) requestmap.get('Nationality__pc');
            newacc.PassportNumber__pc = (String) requestmap.get('PassportNumber__pc');
            newacc.MiddleName = (String) requestmap.get('MiddleName');
            if (requestMap.get('ECSS_LastModifiedByIntegration__c') != null)
                newacc.ECSS_LastModifiedByIntegration__c = (Boolean) requestMap.get('ECSS_LastModifiedByIntegration__c');
            newacc.MobileCountryCode__pc = (String) requestmap.get('MobileCountryCode__pc');
            newacc.MobilePhone__pc = (String) requestmap.get('MobilePhone__pc');
            newacc.PersonMobilePhone = (String) requestmap.get('PersonMobilePhone');
            if (requestMap.get('PassportIssueDate__pc') != null)
                newacc.PassportIssueDate__pc = Date.valueOf((String) requestMap.get('PassportIssueDate__pc'));
            
            if (requestMap.get('PassportExpiryDate__pc') != null)
                newacc.PassportExpiryDate__pc = Date.valueOf((String) requestMap.get('PassportExpiryDate__pc'));
            
            if (requestMap.get('NationalIdExpiryDate__pc') != null)
                newacc.NationalIdExpiryDate__pc = Date.valueOf((String) requestMap.get('NationalIdExpiryDate__pc'));
            
        }
        
        newacc.Phone = (String) requestmap.get('Phone');
        newacc.ECSS_Customer_Type__c = (String) requestmap.get('ECSS_Customer_Type__c');
        newacc.MobileCountryCode__c = (String) requestmap.get('MobileCountryCode__c');
        newacc.MobileNumber1__c = (String) requestmap.get('MobileNumber1__c');
        newacc.MobileNumber__c = (String) requestmap.get('MobileNumber__c');
        newacc.ShippingStreet = (String) requestmap.get('ShippingStreet');
        newacc.ShippingPostalCode = (String) requestmap.get('ShippingPostalCode');
        newacc.ShippingCity = (String) requestmap.get('ShippingCity');
        newacc.PlaceOfRegistration__c = (String) requestmap.get('PlaceOfRegistration__c');
        newacc.CustomerVertical__c ='Aldar Estates';
        newacc.SkipCustomerLogin__c = true;
        newacc.SapAccountID__c =(String) requestmap.get('SapAccountID__c');
        insert newacc;
        return newacc;
        
    }
    
}