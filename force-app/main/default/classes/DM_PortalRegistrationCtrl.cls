/***
Class       : DM_PortalRegistrationCtrl
Author      : Smaartt
Description : To register new community user
TestClass   : DM_PortalRegistrationCtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              13/02/2024           Initial Version 
****************************************************************************************************************/
public without sharing class DM_PortalRegistrationCtrl {
    @AuraEnabled
    public static void createAccount( Account accountobj, Contact Contactobj,string accountFile,string contactFile) {
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
        accountobj.RecordTypeId =  Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_AccountRecordType).getRecordTypeId();
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
            
            contactobj.RecordTypeId =  Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_ContactRecordType).getRecordTypeId();
            contactobj.AccountId = accountobj.Id;
            
            if (accountIdVal != '') {
                Database.SaveResult[] srList1 = Database.insert(new List<Contact>{contactobj }, false);
            for (Database.SaveResult sr : srList1) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
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
            }
          
        } catch (DmlException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }        
    }
    @TestVisible
    private static void attachFilesToRecord(Id recordId, List<ContentVersion> files) {
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: files[0].id
        ].ContentDocumentId;
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
}