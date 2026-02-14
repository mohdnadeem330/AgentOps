/***
Class       : RETL_ContractorPortalRegistration
Author      : Smaartt
Description : To register new community user
TestClass   : RETL_ContractorPortalRegistrationTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              13/02/2024           Initial Version 
****************************************************************************************************************/
public without sharing class RETL_ContractorPortalRegistration {
    @AuraEnabled
    public static void createAccount( Account accountobj, Contact Contactobj, RETL_Contact_role__c contactRoleObj, string accountFile,string contactFile, String contactRetailPassportFile, String contactRetailVisaFile) {
        System.debug('AccountFile- '+ accountFile);
        System.debug('ContactFile- '+ contactFile); 
        System.debug('Account Obj- '+ accountobj);   
        System.debug('Contact Obj- '+ Contactobj);   
        accountobj.MobileNumber__c = accountobj.MobileCountryCode__c + accountobj.MobileNumber1__c;
        Contactobj.MobilePhone = Contactobj.MobileCountryCode__c + Contactobj.MobilePhone__c;
		Contactobj.Is_Portal_Register_User__c = true;       
        
        string contactemail = Contactobj.Email;
        String TradeLicenseNumber = accountobj.RegistrationNumber__c;
        String RegisterNumber = accountobj.UAEVATRegisterNumber__c; 
        List<Account> existingAccounts = new List<Account>();
        List<Contact> existingContact = new List<Contact>();
        string AccountId;
        String query = 'SELECT Id,RegistrationNumber__c,UAEVATRegisterNumber__c FROM Account';
        if (TradeLicenseNumber != null && RegisterNumber == null) {
            query += ' WHERE RegistrationNumber__c = \'' + TradeLicenseNumber + '\'';
        } 
        else if (RegisterNumber != null && TradeLicenseNumber == null) {
            query += ' WHERE UAEVATRegisterNumber__c = \'' + RegisterNumber + '\'';
        }
        else if (TradeLicenseNumber != null && RegisterNumber != null) {
            query += ' WHERE RegistrationNumber__c = \'' + TradeLicenseNumber + '\' AND UAEVATRegisterNumber__c = \'' + RegisterNumber + '\'';
        }
        
        if (TradeLicenseNumber != null || RegisterNumber != null){
            existingAccounts = Database.query(query);
        }
        if(contactemail != null){
            existingContact = [Select Id,Email From Contact where Email =: contactemail];  
        }
        if(accountobj.CustomerVertical__c =='Retail'){
            accountobj.RecordTypeId =  Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
        }
        else{
        	accountobj.RecordTypeId =  Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_AccountRecordType).getRecordTypeId();
        }
        Savepoint sp = Database.setSavepoint();
        
        try {
            if(!existingAccounts.isEmpty()){
                throw new AuraHandledException('User has already registered with this company\'s details');
            }
            if(!existingContact.isEmpty()){
                throw new AuraHandledException('User has already registered with this contact email');
            }
           Database.SaveResult[] srList = Database.insert(new List<Account>{accountObj}, false);
           string accountIdVal = '';
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    accountIdVal = sr.getId();
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        throw new AuraHandledException(err.getMessage());
                    }
                }
             }
            if(accountobj.CustomerVertical__c =='Retail'){
            	contactobj.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();
            }
            else{
                contactobj.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_ContactRecordType).getRecordTypeId();
            }
            contactobj.AccountId = accountobj.Id;
            List<RETL_Contact_role__c> contactRoleToInsert = new List<RETL_Contact_role__c>();
            if (accountIdVal != '') {
                Database.SaveResult[] srList1 = Database.insert(new List<Contact>{contactobj }, false);
            for (Database.SaveResult sr : srList1) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
                    if( contactRoleObj != null){
                        contactRoleObj.RETL_Contact__c = sr.getId();
                        contactRoleObj.Name = contactRoleObj.RETL_Contact_role__c;
                        contactRoleObj.RETL_Account_Name__c = accountobj.Id;
                        contactRoleObj.RETL_Primary__c = true;
                        contactRoleToInsert.add(contactRoleObj);
                    }
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());                        
                        System.debug('Contact fields that affected this error: ' + err.getFields());
                        throw new AuraHandledException(err.getMessage());
                    }
                }
             }
                if( !contactRoleToInsert.isEmpty()) {
                    Database.SaveResult[] srCRList1 = Database.insert(contactRoleToInsert, false);
                } 
                if(accountFile != null && accountFile != '' ){
                    fileWrapper fwa = (fileWrapper)JSON.deserialize(accountFile,fileWrapper.class);
                   
                    if (fwa != null) {
                        List<ContentVersion> cvalist = new List<ContentVersion>();
                        ContentVersion cva = new ContentVersion();
                        cva.VersionData = EncodingUtil.base64Decode(fwa.Base64);
                        cva.Title = fwa.fileName;
                        cva.PathOnClient = fwa.fileName;
                        cvalist.add(cva);
                        insert cvalist;
                        
                        Document__c doc = new Document__c();
                        doc.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doc.DocumentType__c = Label.Dm_DocumentTypeTradeLicense;
                        doc.Account__c = accountobj.Id;
                        insert doc;
                        System.debug('cvalist: ' + cvalist);
                        attachFilesToRecord(doc.Id, cvalist);
                        
                    }
                }
                if(contactFile != null && contactFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
                if(contactRetailVisaFile != null && contactRetailVisaFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactRetailVisaFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = fwc.documentType;//Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
                if(contactRetailPassportFile != null && contactRetailPassportFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactRetailPassportFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = fwc.documentType;//Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
            }
          
        } catch (DmlException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }        
    }
    @TestVisible
    private static void attachFilesToRecord(Id recordId, List<ContentVersion> files) {
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        List<ContentVersion> vList = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :files
        ];
        
        if (vList.isEmpty()) {
            System.debug('ContentVersion not found → skip or throw custom error');
            return;
        }
        
        
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = vList[0].ContentDocumentId;
        /*documentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: files[0].id
        ].ContentDocumentId;*/
        documentLink.LinkedEntityId = recordId;
        documentLink.ShareType = 'V'; 
        documentLink.Visibility = 'AllUsers'; 
        documentLinks.add(documentLink);
        
        insert documentLinks;
    }
   
    public class fileWrapper{
        @AuraEnabled
        public string fileName { get; set; }
        @AuraEnabled
        public string Base64 { get; set; }
        @AuraEnabled
        public string documentType { get; set; }
    }
     
    @AuraEnabled
    public static Boolean isReCAPTCHAValid(String tokenFromClient) {
        String SECRET_KEY = Label.reCaptchaSecretKey;
        String RECAPTCHA_SERVICE_URL = 'https://www.google.com/recaptcha/api/siteverify';
        Http http = new Http();
        
        HttpRequest request = new HttpRequest();       
        request.setEndpoint(RECAPTCHA_SERVICE_URL+'?secret=' + SECRET_KEY + '&response=' + tokenFromClient);
        request.setMethod('POST');
        request.setHeader('Content-Length', '0');
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        
        Map<String, Object> mapOfBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        Boolean success = (Boolean) mapOfBody.get('success');
        
        return success;
    }
    @AuraEnabled
    public static map<string,string> validateMobileNumber(string mobNo){
        if(mobNo != null){
            map<string,string> res = MobileNumberValidation.validatePhoneNo(new list<string>{mobNo});
            return res;
        }else{
            return null;
        }         
    } 
     @AuraEnabled
    public static boolean validateEmailId(string email){
        return EmailValidation.getValidateEmailWithAura(email);
    }
    
    @AuraEnabled
    public static void updateAccount( Account accountobj, Contact Contactobj, RETL_Contact_role__c contactRoleObj, string accountFile,string contactFile, String contactRetailPassportFile, String contactRetailVisaFile, 
                                     Boolean isTradeLicenseUpdated, Boolean isVATUpdated, Boolean isContactEmailUpdated){
        System.debug('Account Obj- '+ accountobj);   
        System.debug('Contact Obj- '+ Contactobj);   
        accountobj.MobileNumber__c = accountobj.MobileCountryCode__c + accountobj.MobileNumber1__c;
        Contactobj.MobilePhone = Contactobj.MobileCountryCode__c + Contactobj.MobilePhone__c;
        Contactobj.Is_Portal_Register_User__c = true;       
        
        string contactemail = Contactobj.Email;
        String TradeLicenseNumber = accountobj.RegistrationNumber__c;
        String RegisterNumber = accountobj.UAEVATRegisterNumber__c; 
        List<Account> existingAccounts = new List<Account>();
        List<Contact> existingContact = new List<Contact>();
        String AccountId;
        if(isTradeLicenseUpdated){
            String query = 'SELECT Id,RegistrationNumber__c,UAEVATRegisterNumber__c FROM Account';
            
            if (TradeLicenseNumber != null && RegisterNumber == null) {
                query += ' WHERE RegistrationNumber__c = \'' + TradeLicenseNumber + '\'';
            } 
            else if (RegisterNumber != null && TradeLicenseNumber == null) {
                query += ' WHERE UAEVATRegisterNumber__c = \'' + RegisterNumber + '\'';
            }
            else if (TradeLicenseNumber != null && RegisterNumber != null) {
                query += ' WHERE RegistrationNumber__c = \'' + TradeLicenseNumber + '\' AND UAEVATRegisterNumber__c = \'' + RegisterNumber + '\'';
            }
            if (TradeLicenseNumber != null || RegisterNumber != null){
                existingAccounts = Database.query(query);
            }
        }
        if(isContactEmailUpdated){
            if(contactemail != null){
                existingContact = [Select Id,Email From Contact where Email =: contactemail];  
            }
        }
        if(accountobj.CustomerVertical__c =='Retail'){
            accountobj.RecordTypeId =  Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
        }
        else{
        	accountobj.RecordTypeId =  Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_AccountRecordType).getRecordTypeId();
        }
        Savepoint sp = Database.setSavepoint();
        
        try {
            if(!existingAccounts.isEmpty()){
                throw new AuraHandledException('User has already registered with this company\'s details');
            }
            if(!existingContact.isEmpty()){
                throw new AuraHandledException('User has already registered with this contact email');
            }
           Database.SaveResult[] srList = Database.update(new List<Account>{accountObj}, false);
           string accountIdVal = '';
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    accountIdVal = sr.getId();
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        throw new AuraHandledException(err.getMessage());
                    }
                }
             }
            if(accountobj.CustomerVertical__c =='Retail'){
            	contactobj.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            }
            else{
                contactobj.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_ContactRecordType).getRecordTypeId();
            }
            contactobj.AccountId = accountobj.Id;
            if (accountIdVal != '') {
                Database.SaveResult[] srList1 = Database.update(new List<Contact>{contactobj }, false);
                
            for (Database.SaveResult sr : srList1) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
                    if( contactRoleObj != null){
                        Database.SaveResult[] srCRList1 = Database.update(new List<RETL_Contact_Role__c>{contactRoleObj}, false);
                    }
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());                        
                        System.debug('Contact fields that affected this error: ' + err.getFields());
                        throw new AuraHandledException(err.getMessage());
                    }
                }
             }
                
                if(accountFile != null && accountFile != '' ){
                    fileWrapper fwa = (fileWrapper)JSON.deserialize(accountFile,fileWrapper.class);
                   
                    if (fwa != null) {
                        List<ContentVersion> cvalist = new List<ContentVersion>();
                        ContentVersion cva = new ContentVersion();
                        cva.VersionData = EncodingUtil.base64Decode(fwa.Base64);
                        cva.Title = fwa.fileName;
                        cva.PathOnClient = fwa.fileName;
                        cvalist.add(cva);
                        insert cvalist;
                        
                        Document__c doc = new Document__c();
                        doc.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doc.DocumentType__c = Label.Dm_DocumentTypeTradeLicense;
                        doc.Account__c = accountobj.Id;
                        insert doc;
                        System.debug('cvalist: ' + cvalist);
                        attachFilesToRecord(doc.Id, cvalist);
                        
                    }
                }
                if(contactFile != null && contactFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
                if(contactRetailVisaFile != null && contactRetailVisaFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactRetailVisaFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = fwc.documentType;//Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
                if(contactRetailPassportFile != null && contactRetailPassportFile != ''){
                    fileWrapper fwc = (fileWrapper)JSON.deserialize(contactRetailPassportFile,fileWrapper.class);
                    if (fwc != null) {
                        List<ContentVersion> cvclist = new List<ContentVersion>();
                        ContentVersion cvc= new ContentVersion();
                        cvc.VersionData = EncodingUtil.base64Decode(fwc.Base64);
                        cvc.Title = fwc.fileName;
                        cvc.PathOnClient = fwc.fileName;
                        cvclist.add(cvc);
                        insert cvclist;
                        Document__c doccon = new Document__c();
                        doccon.RecordTypeId =  Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                        doccon.DocumentType__c = fwc.documentType;//Label.Dm_DocumentTypeEmirates;
                        doccon.Contact__c = Contactobj.Id;
                        insert doccon;
                        System.debug('cvclist: ' + cvclist);
                        attachFilesToRecord(doccon.id, cvclist);
                    }
                }
            }
          
        } catch (DmlException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }    
    }
    
}