/***
Class       : DM_UtilityController
Author      : Smaartt
Description :
TestClass   :
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0               28/06/2024          Initial Version
****************************************************************************************************************/
public without sharing class DM_UtilityController {
    @auraEnabled
    public static map<string,string> getPicklistValues(string objName,String fldName){
        map<string,string> labelVsValue = new map<string,string>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fldName).getDescribe();
        for(Schema.PicklistEntry ple : fieldResult.getPicklistValues()){
            labelVsValue.put(ple.getLabel(),ple.getValue());
        }
        return labelVsValue;
    }
    @AuraEnabled
    public static List<User> getUserInfo(){
        return [Select Id,FirstName,LastName,Name,Email,AccountId,ContactId,Contact.MobileCountryCode__c,Contact.MobilePhone__c,MobilePhone,Profile.Name,Username, Contact.Account.CustomerVertical__c from User where Id = :UserInfo.getUserId()];
    }
    public static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    public static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    public static void sendBellNotification(Set<String> recipientsIds, String targetId,string title,string body) {
        CustomNotificationType notificationType =
            [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName=:label.DM_customNotification];

        Messaging.CustomNotification notifications = new Messaging.CustomNotification();
        notifications.setTitle(title);
        notifications.setBody(body);
        notifications.setNotificationTypeId(notificationType.Id);
        notifications.setTargetId(targetId);

        // Actually send the notification
        try {
            notifications.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    @auraEnabled
    public static string genericValidationMsgGenerator(Id recordId){

        string validationMsg = '';
        String sObjectName = recordId.getSObjectType().getDescribe().getName();

        List<ValidationFields__mdt> validationList = [SELECT Id,MasterLabel,Label,FieldAPI__c,ObjectName__c,Process__c,RecordType__c FROM ValidationFields__mdt WHERE ObjectName__c=:sObjectName ];

        Set<String> fieldList = new Set<String>();
        if(validationList.size()>0){
            for (ValidationFields__mdt vl : validationList) {
                fieldList.add(vl.FieldAPI__c);
            }
        }

        System.debug('fieldList--'+fieldList);

        Sobject sobjectData = getDataWithAllFields(recordId,fieldList);

        if(validationList.size()>0 && sobjectData!= null){

            for(ValidationFields__mdt vl : validationList){
                validationMsg += (String.isNotBlank(String.valueOf( sobjectData.get(vl.FieldAPI__c))) ? '': (String.isNotBlank(validationMsg) ? +', ' : '') + vl.Label);
            }
            system.debug(validationMsg);
        }
        return validationMsg;
    }
    public static Sobject getDataWithAllFields(Id recordId, Set<String> fieldList){
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        String fields = string.join(new list<string>(fieldList),',');
        String query = 'SELECT ' + fields +' From '+sObjectName+' WHERE Id = :recordId';
        return Database.Query(query);
    }

    public static List<String> getEmailAddresses(Case caseRecord) {
        List<String> emailAddresses = new List<String>();
        List<DM_Security_Emails_Config__mdt> emailConfigRecords = [SELECT EmailIds__c FROM DM_Security_Emails_Config__mdt
            WHERE Type__c = :caseRecord.Type AND Development_Name__c = :caseRecord.Development_Name__c];

        for (DM_Security_Emails_Config__mdt emailConfig : emailConfigRecords) {
            if (emailConfig.EmailIds__c != null) {
                List<String> emails = emailConfig.EmailIds__c.split(',');
                emailAddresses.addAll(emails);
            }
        }
        return emailAddresses;
    }

    @AuraEnabled(cacheable=true)
        public static Wire_Transfer_Bank_Details__mdt getBankTransferDetails() {
        String developmentName = Label.DM_WireTransferInfo;
        Wire_Transfer_Bank_Details__mdt bankDetails = [SELECT Account_Name__c, Account_Number__c, Bank_Name__c, Branch_Name__c, IBAN__c, Swift_Code__c
            FROM Wire_Transfer_Bank_Details__mdt WHERE MasterLabel =: developmentName LIMIT 1];
        return bankDetails;
    }

    @auraEnabled
    public static void updateContact(Contact con){
        try{
            Update con;
            User u = new User();
            u.Id = UserInfo.getUserId();
            u.LastName = con.LastName;
            u.FirstName= con.FirstName;
            u.MobilePhone= con.MobilePhone;
            Update u;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static void sendMobileOTP(Contact con){
        try{
            String otp = String.valueOf(Utilities.getRandomNumber(6));
            con.BrokerLoginOTPNumber__c=otp;
            con.BrokerLoginOTPDateTime__c= Datetime.now();
            update con;
            SmsNotificationAPI.SmsRequest sms = new SmsNotificationAPI.SmsRequest();
            sms.destination = con.MobilePhone;
            sms.record = con;
            sms.smsBody=otp+' '+Label.DmSMSOtpText;
            SmsNotificationAPI.sendSmsNotification(new list<SmsNotificationAPI.SmsRequest>{sms});
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static string verifyOtp(string otp){
        List<User> userInfo = [SELECT Id,Contact.BrokerLoginOTPNumber__c FROM User where Id=:UserInfo.getUserId()];
        if(userInfo.size()>0){
            string otpSent = userInfo[0].Contact.BrokerLoginOTPNumber__c;
            if(otp.equals(otpSent)){
                return 'Success';
            }
        }
        return 'WrongOTP';

    }
    public static String CommaseparatedValues(Decimal amount) {

        List<String> args = new List<String>{'0', 'number', '###,###,##0.00'};
        String updatedAmount = String.format(amount.format(), args);
         return updatedAmount;
     }
    public static Map<string,string> getCaseRecTypeName(list<string> CaseIds){
        Map<string,string> caseIdvsCaseRectype = new Map<string,string>();
        for(Case ca :[select Id,RecordType.name from Case where Id=:CaseIds]){
            caseIdvsCaseRectype.put(ca.Id,ca.RecordType.name);
        }
        return caseIdvsCaseRectype;
    }
    public static HttpResponse makeCallout(String processName,String requestBody){
        //---- Fetch mulesoft URLs
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
        Organization org = Utilities.getOrganizationDetails();

        String endPointURL = mulesoftAPI.SandboxURL__c ;

        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        System.debug('**Request Body**'+requestBody);
        request.setBody(requestBody);

        return http.send(request);
    }

    @auraEnabled
    public static void deleteRecord(string recordId){
        SobjectType sob = Id.valueOf(recordId).getSObjectType();
        SObject recordToDelete = sob.newSObject(recordId);
        try{
            delete recordToDelete;
        }
        catch (Exception e) {
            throw new AuraHandledException('Failed to delete record: ' + e.getMessage());
        }
    }
}