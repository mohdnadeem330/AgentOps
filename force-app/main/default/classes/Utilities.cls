public with sharing class Utilities {

    public static Map<String,String> constantsMap ;
    public static String objType = '';
    public static User userDetail ;
    public static List<String> groupNames = new List<String>();
    
    public static void sendExceptionEmail(String className,String methodName, String htmlBody,String emailSubject,Exception e) {
        LoggerService.save(LoggerService.addApexLog(e,className,methodName,''));
        List<String> recipientList = Label.SysAdminEmailAddress.split(';');
        sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), emailSubject, '',htmlBody,new List<Messaging.EmailFileAttachment>(), '')});
    }
    
    //Get End point of cybersource added by Noor
    public static List<MID_Config_for_Other_Charges__mdt> getMIDConigForOtherChargesMDT(string projectId){
       if(!Test.isRunningTest()){
              List<MID_Config_for_Other_Charges__mdt> midConfigMtd = [SELECT API_Key__c,id,Profile_Id__c,Secret_Key__c,Project_Id__c FROM MID_Config_for_Other_Charges__mdt  where Project_Id__c =:projectId ];
        return midConfigMtd;
       }
       return new List<MID_Config_for_Other_Charges__mdt>();
   
    }

    //Get Service End Point
    public static APISetting__mdt getServiceDetails(string serviceName){
        try{
            APISetting__mdt serviceDetails = [SELECT DEVELOPERNAME, Method__c, APIKey__c, SandboxURL__c, ProductionURL__c, UserName__c, APIId__c, Source__c, Password__c, Headers__c, SecretKey__c
                                                     FROM APISetting__mdt
                                                     WHERE DEVELOPERNAME =: serviceName];
            return serviceDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    //Get Service End Point
    public static MuleSoftSetting__mdt getMuleSoftDetails(string serviceName){
        try{
            MuleSoftSetting__mdt serviceDetails = [SELECT Id, Label, DeveloperName, SandboxURL__c, ProductionURL__c, APIKey__c, APIId__c, 
                                                    Method__c, RetryCount__c ,Table_Name__c FROM MuleSoftSetting__mdt WHERE DeveloperName =: serviceName];
            return serviceDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static ShipmentSetting__mdt getAramexDetails(string serviceName){
        try{
            ShipmentSetting__mdt serviceDetails = [SELECT Id, Label, DeveloperName, SandboxURL__c, ProductionURL__c, Method__c 
                                                    FROM ShipmentSetting__mdt WHERE DeveloperName =: serviceName];
            return serviceDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    //get SPA Checklist
    public static List<SPAChecklistItem__mdt> getChecklist(){
        try{
            List<SPAChecklistItem__mdt> serviceDetails = [SELECT DEVELOPERNAME,Applicablefor__c,CategorySequence__c,ItemNumber__c,Category__c,IsActive__c,  ItemName__c
                                                     FROM SPAChecklistItem__mdt ORDER BY CategorySequence__c,ItemNumber__c ASC
                                       ];
            return serviceDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    //get all records
    public static List<SPAChecklistItem__mdt> getAllmdtRec(String recordTypeName){
        try{
            System.debug('inside getAllmdt');
          //  List<SPAChecklistItem__mdt> getPersonRecords= new  List<SPAChecklistItem__mdt>();
            List<SPAChecklistItem__mdt> serviceDetails = [SELECT DEVELOPERNAME,ItemNumber__c,CategorySequence__c,Applicablefor__c,Category__c,IsActive__c,AccountRecordType__c, ItemName__c
                                                     FROM SPAChecklistItem__mdt WHERE isActive__c = true AND  (AccountRecordType__c =: recordTypeName OR AccountRecordType__c =null  ) ORDER BY CategorySequence__c,ItemNumber__c ASC   ];

           System.debug('mdt recrds:>>>>'+serviceDetails);
            return serviceDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    /*
    public static List<DocumentPlaceHolder__mdt> getJointOwnerDocuments(){
        try{
         
          List<DocumentPlaceHolder__mdt> jointOwnDoc=[SELECT Id,ApplicableforJointOwners__c,MasterLabel from DocumentPlaceHolder__mdt WHERE ApplicableforJointOwners__c=true ];
          
            return jointOwnDoc;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    public static List<DocumentPlaceHolder__mdt> getPersonAccountDocs(){
        try{
         
          List<DocumentPlaceHolder__mdt> personDoc=[ SELECT Id,IsPerson__c,MasterLabel from DocumentPlaceHolder__mdt WHERE isPerson__c=true];
          System.debug('personDoc'+personDoc) ;
          return personDoc;
          
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static List<DocumentPlaceHolder__mdt> getOrganisationAccountDocs(){
        try{
         
          List<DocumentPlaceHolder__mdt> orgDoc=[ SELECT Id,IsOrganisation__c,MasterLabel from DocumentPlaceHolder__mdt WHERE IsOrganisation__c=true];
          System.debug('orgDoc'+orgDoc) ;
          return orgDoc;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    */

    //Get System Messages
    public static SystemMessages__mdt getSystemMessages(string messageName){
        try{
            SystemMessages__mdt messageDetails = [SELECT DeveloperName, Message__c, MergeFieldsToReplace__c, LongMessage__c
                                                     FROM SystemMessages__mdt
                                                     WHERE DEVELOPERNAME =: messageName];
            return messageDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    //Get Timer Details
    public static Timer__mdt getTimer(string timerName){
        try{
            Timer__mdt timerDetails = [SELECT Timer__c, Time__c
                                        FROM Timer__mdt
                                        WHERE DEVELOPERNAME =: timerName];
            return timerDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    //Get Darna Loyalty Matrix
    public static List<DarnaLoyaltyMatrix__mdt> getDarnaLoyaltyMatrix(){
        try{
            List<DarnaLoyaltyMatrix__mdt> darnaLoyaltyDetails = [SELECT From__c, To__c, Percentage__c
                                        FROM DarnaLoyaltyMatrix__mdt];
            return darnaLoyaltyDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    //---- Get UniqueKey Mapping
    public static UniqueKeyMapping__mdt getUniqueKeyMapping(string uniqueKeyName){
        try{
            UniqueKeyMapping__mdt UniqueKeyDetails = [SELECT DeveloperName, Values__c
                                                     FROM UniqueKeyMapping__mdt
                                                     WHERE DEVELOPERNAME =: uniqueKeyName];
            return UniqueKeyDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    //Check if the instance is Sandbox or Production
    public static Organization getOrganizationDetails(){
        try{
            Organization org = [SELECT Id, InstanceName, IsSandbox, Name, OrganizationType 
                                FROM Organization];
            return org;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static EmailTemplate getEmailTemplate(string emailName){
        try{
            
            EmailTemplate emailTemplate = [SELECT name , Id, Subject, Description, HtmlValue, DeveloperName, Body 
            FROM EmailTemplate WHERE name=: emailName];

            return emailTemplate;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static String getOrgWideEmailAddressId(){
        try{
            
            OrgWideEmailAddress orgWideEmailAddress = [Select id,Address From OrgWideEmailAddress LIMIT 1];

            return orgWideEmailAddress.Id;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static string getOrgWideEmailAddressIdByName(String Name){        
        try{            
            OrgWideEmailAddress orgWideEmailAddress = [select id,Address from OrgWideEmailAddress where DisplayName= : Name limit 1];            
            return orgWideEmailAddress.Id;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static string getEmailtemplateIdByName(String templateName){        
        try{            
            Emailtemplate emailTemplateId = [select id, DeveloperName from emailtemplate where DeveloperName =: templateName limit 1];          
            return emailTemplateId.Id;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return '';
        }
    }
    
    public static SystemConfiguration__mdt getSystemInformation(string objectName){
        try{
            SystemConfiguration__mdt systemConfig = [SELECT DeveloperName,MasterLabel,
                                IsRunBeforeInsert__c,IsRunBeforeUpdate__c,IsRunAfterInsert__c,IsRunAfterUpdate__c,IsRunBeforeDelete__c,IsRunAfterDelete__c,IsRunTrigger__c
                                                     FROM SystemConfiguration__mdt 
                                                     WHERE MasterLabel =: objectName];
            return systemConfig ;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static Group getQueueInformation(string queueName){
        try{
            Group  leadQueue = [SELECT Id, name
                                                     FROM Group  
                                                     WHERE name  =: queueName];
            return leadQueue;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    //Added by Noor
     public static Map<String,Group> getQueues(){
           return new  Map<String,Group>([SELECT Id, name  FROM Group WHERE Type ='Queue']);
       
    }

    public static Map<Id,boolean> isAgentAvailable(Set<Id> userId){

        system.debug('Point: userId '+userId);

        Map<Id,boolean> availableUsersMap = new Map <Id,boolean>();
        try{
            List<UserServicePresence> userServicePresenceList = [SELECT IsCurrentState, userId FROM UserServicePresence where userId =: userId AND IsCurrentState = true];

            system.debug('Point: userServicePresenceList '+userServicePresenceList);

            boolean isAgentAvailable = false;

            for(UserServicePresence user : userServicePresenceList){
                availableUsersMap.put(user.userId,true);
            }
            return availableUsersMap;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
   
   
    /**
    * SendEmailWithTemplateID 
    *
    * This method will return SingleEmailMessage instance with given parameters
    * 
    * @usage all apex based emails
    *
    * @param    targetObject     contact/user/lead ID
    * @param    templateID       template ID to be used
    * @param    whatId           What ID for additinal merge details
    * @param    toRecipients     List of Send to address
    * @param    bccRecipients    List of BCC address
    * @param    ccRecipients     List of CC address
    * @param    emailSubject     Email Subject
    * @param    body             Plain text body
    * @param    htmlBody         Html Body
    * @param    fileAttachments  list of attachments
    * @param    OrgWideEmailAddressID    org wide email Id 
    *
    * @return Messaging.SingleEmailMessage instance
    */
    public static Messaging.SingleEmailMessage getEmailInstance( string targetObject, string templateID,string whatId , List<String> toRecipients,List<String> bccRecipients,List<String> ccRecipients,String emailSubject,String body,string htmlBody,List<Messaging.EmailFileAttachment> fileAttachments,string orgWideEmailAddressID) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(false);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if(targetObject!=null && targetObject!=''){
            mail.setTargetObjectId(targetObject);
        }
        if(whatId!=null && whatId!=''){
            mail.setWhatId(whatId);
        }
        if(templateID!=null && templateID!=''){
            mail.setTemplateID(templateID);
        }
        if(emailSubject!=null && emailSubject!=''){
            mail.setSubject(emailSubject);
        }
        if(toRecipients!=null && !toRecipients.isEmpty() ){
            mail.setToAddresses(toRecipients);
        }
        if(bccRecipients != null && !bccRecipients.isEmpty() ){
            mail.setbccAddresses(bccRecipients);
        }
        if(ccRecipients != null && !ccRecipients.isEmpty()){
            mail.setccAddresses(ccRecipients);
        }
        if (body!=null && body!='') {
            mail.setPlainTextBody(body);
        } 
        if (htmlBody!=null && htmlBody!='') {
            mail.setHtmlBody(htmlBody);
        }
        if(OrgWideEmailAddressID != null && OrgWideEmailAddressID!=''){
            mail.setOrgWideEmailAddressId(OrgWideEmailAddressID);
        }
        // Specify FileAttachments
        if(fileAttachments != null && !fileAttachments.isEmpty()) {
            mail.setFileAttachments(fileAttachments);
        }
        return mail;
    }   
    
    /**
    * SendEmailWithTemplateID 
    *
    * This method will trigger send email logic
    * 
    * @usage all apex based emails
    *
    * @param    mails     list<Messaging.SingleEmailMessage> to be sent
    *
    * @return none
    */
    public static list<Messaging.SendEmailResult> sendEmail(list<Messaging.SingleEmailMessage> mails) {
        return Messaging.sendEmail(mails); 
    }
        /**
    * makeHHTTPCallout 
    *
    * This is generic method to perform the callout
    *
    * @param method        HTTP method used for callout
    * @param endPointURL   The callout endpoint [endpoit must be configured in remote site setting]
    * @param requesteBody  HTTP request body to set
    * @param headerMap     header map to be set while making HTTP callout
    * @return HTTPResponse returned as a part of HTTP call out
    */
    public static HTTPResponse makeHHTTPCallout(String method, string endPointURL, String requesteBody,map<String,string> headerMap){
        Httprequest req = new Httprequest();
        HTTPResponse resp  = new HTTPResponse();
        Http http = new Http();
        try{
            req.setMethod(method);
            req.setEndpoint(endPointURL);
            if(!String.isBlank(requesteBody)){
                req.setBody(requesteBody);      
            }
            if(headerMap!=null){
                for(String headerKey: headerMap.keySet()){
                    Req.setHeader(headerKey,headerMap.get(headerKey));      
                }
            }
            req.setTimeout(120000);
            resp = http.send(req);
            
            if(resp.getStatusCode()!=200 && resp.getStatusCode()!=202){
                //createLog(Utilities.getAppSettings('LOG_TYPE_WARN') ,'Utilities','makeHHTTPCallout', 'Status:'+resp.getStatusCode() + 'Body:'+resp.getBody(),'EndPoint: '+endPointURL +'\n Body: '+requesteBody,null );
            }
            return resp;
        }catch(Exception e){ 
            system.debug(e);
            //createLog(Utilities.getAppSettings('LOG_TYPE_ERROR'),'WS_Utilities','makeHHTTPCallout',requesteBody,'EndPoint: '+endPointURL +'\n Body: '+requesteBody,e);
        }
        return null;
    }
    
   

    /*
    * Get Record Type Id by Object
    */
    public static Id getRecordTypeId(String objectName, String recordTypeName){
        Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
        Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
        return(describeResult.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
    }

    /*
* Get Record Type Name by Object
*/
@AuraEnabled
public static String getRecordTypeName(String objectName, String recordTypeId){
    Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
    Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
    return(describeResult.getRecordTypeInfosById().get(recordTypeId).getName());
}

    /*
    * Get Profile Details by Name
    */
    public static Set<Id> getProfileIds(Set<String> profileNames){      
        try{
            Set<Id> profileIds = new Set<Id>();
            for(Profile p : [Select id,Name from Profile where Name IN:profileNames]) {
                profileIds.add(p.Id);
            }
            return profileIds ;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
        }
        return null;
    }

    /*
    * Get Simillar Profile Details by Name
    */
    public static Set<Id> getSimillarProfileIds(String profileNames){      
        try{
            Set<Id> profileIds = new Set<Id>();
            profileNames += '%';
            for(Profile p : [Select id,Name from Profile where Name LIKE :profileNames]) {
                profileIds.add(p.Id);
            }
            return profileIds ;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
        }
        return null;
    }

   /*
    * Get Constant value
    */
    @AuraEnabled(cacheable=false)
    public static Integer getConstantValue(String constantName){

        Integer constantValue ;

        if(constantsMap == null){
            constantsMap = new Map<String,String>();
            for(Constant__mdt constant : [SELECT DeveloperName, MasterLabel, ConstantValue__c FROM Constant__mdt]){
                constantsMap.put(constant.DeveloperName,constant.ConstantValue__c);
            }   
        }
        
        if(constantsMap.containsKey(constantName))
            constantValue = Integer.ValueOF(constantsMap.get(constantName)); 
        
        return constantValue ;
    }

    /*
    * Get Constant value
    */
    @AuraEnabled(cacheable=false)
    public static Constant__mdt getConstant(string messageName){
        try{
            Constant__mdt constant = [SELECT DeveloperName, MasterLabel, ConstantValue__c, ConstantValueLong__c
            FROM Constant__mdt WHERE DEVELOPERNAME =: messageName];

            return constant;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    /*
    * Get Record Count for the App
    */
    public static integer getRecordCount(String constantName,Integer maxRecordCount){
        
        try{
            Integer recordCountToFetch = getConstantValue(constantName) ;
            recordCountToFetch = (recordCountToFetch != null && recordCountToFetch > 0 ) ? recordCountToFetch : 3000;
            if(maxRecordCount > 0){
                return recordCountToFetch > maxRecordCount ? maxRecordCount : recordCountToFetch;
            }else{
                return recordCountToFetch;
            }
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return 3000;
        }
    }

    public static string getWhereConditionfrmMap(Map<String,String> mapFieldApiFieldValues){
        List<String> whereCondition = new List<String>();

        if(mapFieldApiFieldValues != null && !mapFieldApiFieldValues.isempty()){
            for(string key : mapFieldApiFieldValues.keyset()){
                if(mapFieldApiFieldValues.get(key) != null && string.isNotEmpty(mapFieldApiFieldValues.get(key))){
                    String lowerCaseKey = key.toLowerCase();

                    if(objType == 'account'){
                         
                        if(lowerCaseKey == 'mobilenumber__c'){
                            whereCondition.add('(MobileNumber__c like \'%'+mapFieldApiFieldValues.get(key)+'%\''+' OR PersonMobilePhone like \'%'+mapFieldApiFieldValues.get(key)+'%\')');
                        }
                        else if(lowerCaseKey == 'email__c'){
                            whereCondition.add('(Email__c like \'%'+mapFieldApiFieldValues.get(key)+'%\''+' OR PersonEmail like \'%'+mapFieldApiFieldValues.get(key)+'%\')');
                        }
                        else if(lowerCaseKey == 'customertype__c' || lowerCaseKey == 'residentstatus__pc'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if(lowerCaseKey == 'name'){
                            whereCondition.add('(Name like \'%'+mapFieldApiFieldValues.get(key)+'%\''+' OR FirstName like \'%'+mapFieldApiFieldValues.get(key)+'%\''+' OR MiddleName like \'%'+mapFieldApiFieldValues.get(key)+'%\''+' OR LastName like \'%'+mapFieldApiFieldValues.get(key)+'%\')');
                        }
                        else{
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                       
                    }else if(objType == 'opportunity' ){
                        if(lowerCaseKey == 'accountid' || lowerCaseKey == 'stageName' || lowerCaseKey == 'project__c'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if (lowerCaseKey == 'status'){
                            System.debug(mapFieldApiFieldValues.get(key));
                            if(mapFieldApiFieldValues.get(key) == 'Open')
                            whereCondition.add('StageName != \''+'Closed Won\''+' AND StageName != \''+'Closed Lost\''+' AND ReservationApprovalStatus__c = \''+'Draft\'');
                        }     
                        else if(mapFieldApiFieldValues.get(key) == 'OpenOpportunities') {                           
                            whereCondition.add('StageName != \''+'Closed Won\''+' AND StageName != \''+'Closed Lost\'');
                        }                    
                        else{
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }

                    }else if(objType == 'inventory') {

                        if (lowerCaseKey == 'project'){
                            if(mapFieldApiFieldValues.get('digitalSales') == 'true'){
                                whereCondition.add('Project__c IN(\''+mapFieldApiFieldValues.get(key)+'\')');
                            }else{
                                whereCondition.add('Project__r.Name like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                            }
                        }else if(lowerCaseKey == 'digitalSales'){
                            if(mapFieldApiFieldValues.get('digitalSales') == 'true'){
                            whereCondition.add('DigitalSales__c =true');
                            }
                        }
                        else if (lowerCaseKey == 'building') {
                            if(mapFieldApiFieldValues.get('digitalSales') == 'true'){
                                whereCondition.add('BuildingSectionName__c ='+mapFieldApiFieldValues.get(key)+'');
                            }else{
                                whereCondition.add('BuildingSectionName__r.Name like \'%'+mapFieldApiFieldValues.get(key)+'%\''); 
                            }
                        }
                        else if(lowerCaseKey == 'unitname'){
                            if(mapFieldApiFieldValues.get('digitalSales') == 'true'){
                                whereCondition.add('Id ='+mapFieldApiFieldValues.get(key)+'');
                            }
                        }else if (lowerCaseKey == 'minimumprice') {
                            whereCondition.add('SellingPrice__c' + ' >= ' + mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'maximumprice') {
                            whereCondition.add('SellingPrice__c' + ' <= ' + mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'minimumsaleablearea') {
                            whereCondition.add('SaleableArea__c' + ' >= ' + mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'RelatedOpportunity__c') {
                            //Do Nothing for now. 
                        }
                        else if (lowerCaseKey == 'maximumsaleablearea') {
                            whereCondition.add('SaleableArea__c' + ' <= ' + mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'agentId') {
                            if(groupNames !=null && groupNames.size() > 0){
                                Integer groupCount = 0 ; 
                                String condition = 'AllocationGroupName__c IN (';
                                for(String groupName : groupNames){
                                    condition = condition + '\''+ groupName + '\'';
                                    groupCount = groupCount + 1;
                                    if(groupNames.size()>1 && groupCount != groupNames.size())
                                        condition = condition + ',' ;
                                }
                                condition = condition + ') OR AssignedToUserEmail__c like \'%'+mapFieldApiFieldValues.get(key)+'%\'';
                                whereCondition.add(condition);
                            }
                            else{
                                whereCondition.add('AssignedToUserEmail__c like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                            }
                        }
                        else{
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                    }else if(objType == 'salesorder') {

                        if (lowerCaseKey == 'orderFromDate'){
                            whereCondition.add('BookingDate__c >='+mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'orderToDate') {
                            whereCondition.add('BookingDate__c <='+mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'salesmanager__c' || lowerCaseKey == 'opportunity__c') {
                            //whereCondition.add('SalesManager__c = \''+mapFieldApiFieldValues.get(key)+'\'');
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if(mapFieldApiFieldValues.get(key) == 'open'){
                            whereCondition.add('('+key +' = \''+'Pending'+'\' OR '+key+' = \''+'Approve Pending'+'\')');
                        }
                        else if(lowerCaseKey == 'status__c' || lowerCaseKey == 'subStatus__c'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if(lowerCaseKey == 'ProjectName__c'){
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                        else if(lowerCaseKey == 'account__c'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if(lowerCaseKey == 'unitname'){
                            whereCondition.add('Unit__r.Name like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                        else{
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                    }
                    else if(objType == 'Task') {
                        if (lowerCaseKey == 'ownerid'){
                            whereCondition.add('OwnerId =\''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if (lowerCaseKey == 'opportunityid' || lowerCaseKey == 'accountid'){
                            whereCondition.add('WhatId =\''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if (lowerCaseKey == 'leadid'){
                            whereCondition.add('WhoId =\''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if (lowerCaseKey == 'dateFilter'){
                            whereCondition.add('ActivityDate ='+mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'Status'){
                            whereCondition.add('Status =\''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if (lowerCaseKey == 'fromDate'){
                            whereCondition.add('ActivityDate >='+mapFieldApiFieldValues.get(key));
                        }
                        else if (lowerCaseKey == 'toDate'){
                            whereCondition.add('ActivityDate <='+mapFieldApiFieldValues.get(key));
                        }
                    }                    
                    else if(objType == 'Lead') {

                        if(mapFieldApiFieldValues.get(key) == 'openlead'){
                            whereCondition.add('('+key +' = \''+'In Progress Lead'+'\' OR '+key+' = \''+'New Lead'+'\')');
                        }
                        else if(lowerCaseKey == 'project__c' || lowerCaseKey == 'leadSource' || lowerCaseKey == 'Status'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else if(lowerCaseKey == 'existingAccount__c'){
                            whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');
                        }
                        else{
                            whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                        }
                    }
                    else{
                        whereCondition.add(key +' like \'%'+mapFieldApiFieldValues.get(key)+'%\'');
                    }
                }
            }
        }

        return string.join(whereCondition, ' and ');
        
    }

    /*
    * Get Logged In User Details
    */
    public static User getLoggedInUserDetail(){
        User userDetail = Utilities.userDetail ;
        if(userDetail==null){
            userDetail = [SELECT Id,Name,Username,UserType,ProfileName__c,UserRole.Name,Profile.Name, UserRole.Id,AccountId, ContactId, Contact.AccountId,Contact.AgentID__c, Contact.Account.Email__c, Contact.Account.BadgesTier__c,Team__c,Email,UserRoleId,ProfileId,FullPhotoUrl,Title,Manager.Name,MobilePhone,Contact.Account.AgencyCategory__c  FROM USER WHERE Id=:UserInfo.getUserId()];
            Utilities.userDetail = userDetail ;
        }   
        return userDetail ;     
    }

    public static User getUserDetailByEmail(String email){
        User userDetail = [SELECT Id,Name,ProfileName__c,UserRole.Name,Profile.Name, UserRole.Id,AccountId, ContactId, Contact.AccountId,Contact.AgentID__c, Contact.Account.Email__c, Team__c,Email,UserRoleId,ProfileId,FullPhotoUrl,Title,Manager.Name,MobilePhone  FROM USER WHERE Email =: email LIMIT 1];
        return userDetail;
    }

    @AuraEnabled //modify by Nikhil (LAS-5)
    public static User getBrokerPortalUserDetails(Id userId){
       
         User   userDetail = [SELECT Id,Name,ProfileName__c,Email,IsActive,UserRole.Name, ContactId, Contact.Name, Team__c  FROM USER WHERE Id=:userId];
         System.debug('userDetail:>>>'+userDetail) ;
        return userDetail ;     
    }

     /*
    * Get User Details
    */
    public static Map<Id, User> getOwnersDetail(set<Id> usersIds){

        Map<Id, User> userDetail = new Map<Id, User>([SELECT Id,Name,ProfileName__c, UserRole.Name, ContactId, Team__c  FROM USER WHERE Id IN :usersIds]);

        return userDetail ;     
    }

    /*
    * Generate Randon Number
    */ 
    public static String getRandomNumber(Integer length){
        
        String str = String.valueof(Math.abs(Crypto.getRandomLong()));
        String randomNumber = str.substring(0, length);
        system.debug('Random Number-' + randomNumber);
        return randomNumber ; 
    }

    @AuraEnabled(cacheable=false)
    public static void documentReparent(List<String> documentIds, String newEntityId){
        for (Id documentId : documentIds) {
            insert new ContentDocumentLink(ContentDocumentID= documentId ,LinkedEntityId = newEntityId);

            // delete [SELECT ContentDocumentID,ContentDocument.title, ContentDocument.ownerId, Id, ContentDocument.FileExtension
            // FROM ContentDocumentLink
            // WHERE ContentDocumentID =: documentId ];
        }
    }

   

      @future
      public static void updateUserProfile(Id contactId, String profileName) {

        User adminUser = [SELECT contactId,profileid
                            FROM User Where contactId =: contactId LIMIT 1];
        system.debug('Request objectContact: '+ adminUser);

        Profile pf = [SELECT Id, name FROM profile 
                        WHERE name=: profileName LIMIT 1];
        system.debug('Request pf: '+ pf);

        adminUser.profileid = pf.Id;
                              
        update adminUser;

      }

        /*
        * Get Domain URL for VF page
        */
    @AuraEnabled(cacheable=false)
    public static String getVFDomainURL(){
        //String currentDomainURL = '';
        //string baseURL = URL.getOrgDomainUrl().toExternalForm();
        //currentDomainURL = baseURL.split('.my.')[0] + '.vf.force.com';        
        //currentDomainURL = 'https://aldarproperties--uatnew--c.sandbox.vf.force.com';

        //system.debug('baseURL' + baseURL);
        //system.debug('currentDomainURL' + currentDomainURL);
        //return currentDomainURL ;
       String baseURL = URL.getOrgDomainUrl().toExternalForm(); // e.g. https://aldarproperties--salesdev.sandbox.my.salesforce.com
        String domainPrefix = '';
        String vfDomain = '';
        if (baseURL.contains('.sandbox.my.salesforce.com')) {
            // Sandbox case
            domainPrefix = baseURL.substringBefore('.sandbox.my.salesforce.com');
            vfDomain = domainPrefix + '--c.sandbox.vf.force.com';
        } else if (baseURL.contains('.my.salesforce.com')) {
            // Production or Developer Edition
            domainPrefix = baseURL.substringBefore('.my.salesforce.com');
            vfDomain = domainPrefix + '--c.vf.force.com';
        } else {
            // Fallback if domain is unexpected
            throw new AuraHandledException('Unsupported domain format: ' + baseURL);
        }
        return vfDomain;
     
    }

    public class MyPickListInfo {
        public String validFor;
    }

    @AuraEnabled
    public static Map<String, List<String>> getDependentPickListValues(String objectName, String controllingField, String dependentField)  {
            
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>() ;
            
        //Get the type being dealt with
            
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName) ;
            
        Schema.DescribeSObjectResult  describeResult = objType.getDescribe () ;
            
        //Get controlling field values
            
        Schema.DescribeFieldResult  controllingFieldInfo = describeResult.fields.getMap ().get (controllingField).getDescribe() ;
            
            //Get dependent field values
            
        Schema.DescribeFieldResult  dependentFieldInfo = describeResult.fields.getMap ().get (dependentField).getDescribe () ;
            
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues () ;
            
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues () ;
            
        //Get the label for controlling picklist value set
            
        For (Schema.PicklistEntry currControllingValue  :  controllingValues)  {
            controllingInfo.put(currControllingValue.getLabel () , new List<String>() ) ;
        }

        //Iterate through the dependent values
        for  (Schema.PicklistEntry  currDependentValue  :  dependentValues)  {

            //get the validFor
    
            String  jsonString  =  JSON.serialize(currDependentValue) ;
    
            MyPickListInfo  info  =  (MyPickListInfo)  JSON.deserialize(jsonString,MyPickListInfo.class);
            String hexString  =  EncodingUtil.convertToHex (EncodingUtil.base64Decode (info.validFor)).toUpperCase () ;
    
            Integer  baseCount  =  0;
    
            for (Integer curr  :  hexString.getChars ()){
                Integer  val  =  0;
                    
                if(curr  >=  65){
                    val  =  curr  -  65  +  10;
                } else{
                    val  =  curr  -  48;
                }
    
                if  ((val & 8)  ==  8)  {
                    controllingInfo.get (controllingValues[baseCount  +  0].getLabel() ).add (currDependentValue.getLabel() ) ;
                }
    
                if  ((val & 4)  ==  4)  {
                    controllingInfo.get (controllingValues[baseCount  +  1].getLabel() ).add (currDependentValue.getLabel() ) ;
                }
    
                if  ((val & 2)  ==  2)  {
                    controllingInfo.get (controllingValues[baseCount  +  2].getLabel() ).add (currDependentValue.getLabel() ) ;
                }
                if  ((val & 1)  ==  1)  {
                    controllingInfo.get (controllingValues[baseCount  +  3].getLabel() ).add (currDependentValue.getLabel() ) ;
                }
                baseCount = baseCount  +  4;
            }
        }
        return controllingInfo;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getContentByTopics(Integer page, Integer pageSize,list<String> topics,String language, String filterby) {
        try {
            String networkId = Network.getNetworkId();
            ConnectApi.ManagedContentVersionCollection contentCollection = ConnectApi.ManagedContent.getManagedContentByTopics(networkId,topics,page,pageSize,language,filterby);
            return contentCollection.items;
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('Error Message : ' + e);
            List<ConnectApi.ManagedContentVersion> mcnvMap = new List<ConnectApi.ManagedContentVersion>();
            return mcnvMap;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getContentByType(Integer page, Integer pageSize,String language, String filterby) {
        try {
            String networkId = Network.getNetworkId();
            ConnectApi.ManagedContentVersionCollection contentCollection = ConnectApi.ManagedContent.getAllManagedContent(networkId,page,pageSize,language,filterby);
            return contentCollection.items;
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('Error Message : ' + e);
            List<ConnectApi.ManagedContentVersion> mcnvMap = new List<ConnectApi.ManagedContentVersion>();
            return mcnvMap;
        }
    }

    public static void createLogAudit(Id recordId,String recordName){
        
        LogRecordAudit__c logAudit = new LogRecordAudit__c();
        logAudit.Name = (String.isNotBlank(recordName)? recordName :Constants.GENERIC_MOBILE_LOG_VIEW) ;
        if(recordId.getSObjectType() == Lead.SObjectType)
            logAudit.Lead__c = recordId;
        if(recordId.getSObjectType() == Account.SObjectType)
            logAudit.Account__c = recordId;       
        insert logAudit ;
    }

    public static Map<String, List<String>> getDependentPickListValues(Schema.DescribeFieldResult  controllingFieldInfo,Schema.DescribeFieldResult  dependentFieldInfo)  {
            
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>() ;
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues () ;
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues () ;
            
        //---- Get the label for controlling picklist value set   
        For (Schema.PicklistEntry currControllingValue  :  controllingValues)  {
            controllingInfo.put(currControllingValue.getValue () , new List<String>() ) ;
        }

        //----Iterate through the dependent values
        for  (Schema.PicklistEntry  currDependentValue  :  dependentValues)  {
            //---get the validFor
            String  jsonString  =  JSON.serialize(currDependentValue) ;
            MyPickListInfo  info  =  (MyPickListInfo)  JSON.deserialize(jsonString,MyPickListInfo.class);
            String hexString  =  EncodingUtil.convertToHex (EncodingUtil.base64Decode (info.validFor)).toUpperCase () ;
            Integer  baseCount  =  0;
    
            for (Integer curr  :  hexString.getChars ()){
                Integer  val  =  0;
                    
                if(curr  >=  65){
                    val  =  curr  -  65  +  10;
                } else{
                    val  =  curr  -  48;
                }
    
                if  ((val & 8)  ==  8)  {
                    controllingInfo.get (controllingValues[baseCount  +  0].getValue() ).add (currDependentValue.getValue() ) ;
                }
    
                if  ((val & 4)  ==  4)  {
                    controllingInfo.get (controllingValues[baseCount  +  1].getValue() ).add (currDependentValue.getValue() ) ;
                }
    
                if  ((val & 2)  ==  2)  {
                    controllingInfo.get (controllingValues[baseCount  +  2].getValue() ).add (currDependentValue.getValue() ) ;
                }
                if  ((val & 1)  ==  1)  {
                    controllingInfo.get (controllingValues[baseCount  +  3].getValue() ).add (currDependentValue.getValue() ) ;
                }
                baseCount = baseCount  +  4;
            }
        }
        return controllingInfo;
    }

    //----- Get System Messages by set of strings
    public static Map<String,SystemMessages__mdt> getSystemMessages(Set<String> messageNames){
        Map<String,SystemMessages__mdt> systemMessagesMap = new Map<String,SystemMessages__mdt>();

        try{
            for(SystemMessages__mdt messageDetails : [SELECT DeveloperName, Message__c, MergeFieldsToReplace__c, LongMessage__c
            FROM SystemMessages__mdt WHERE DeveloperName IN: messageNames]){
                systemMessagesMap.put(messageDetails.DeveloperName,messageDetails);
            }
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }

        return systemMessagesMap ; 
    }
   
    /*
    * Purpose : To fetch the records from ValidationFields__mdt metadata
    * Created by : Ajay Thakur
    */
    public static Map<String,List<ValidationFields__mdt>> getValidationFields()
    {
        List<ValidationFields__mdt> valFieldList = ValidationFields__mdt.getall().values();
        
        Map<String,List<ValidationFields__mdt>> validationFieldsMap = new Map<String,List<ValidationFields__mdt>>();
        
        for(ValidationFields__mdt vf : valFieldList)
        {
            if(!validationFieldsMap.containsKey(vf.ObjectName__c))
                validationFieldsMap.put(vf.ObjectName__c, new List<ValidationFields__mdt>{vf});
            else
            {
                List<ValidationFields__mdt> valfldList = validationFieldsMap.get(vf.ObjectName__c);
                valfldList.add(vf);
                validationFieldsMap.put(vf.ObjectName__c, valfldList);
            }
                
        }
        
        return validationFieldsMap;
    }

    /*
    * Purpose : To fetch the records from CaseFieldDependency__mdt metadata
    * Created by : Ajay Thakur
    */
    public static List<CaseFieldDependency__mdt> getCaseFieldDependency()
    {
        List<CaseFieldDependency__mdt> caseDependencyList = CaseFieldDependency__mdt.getall().values();
        return caseDependencyList;
    }
     // Case Revamp : To populate fields from new revised metadata  
    // public static List<Case_Field_Dependency_Revised__mdt> getCaseFieldDependencyNew()
    // {
    //     List<Case_Field_Dependency_Revised__mdt> caseDependencyList = Case_Field_Dependency_Revised__mdt.getall().values();
    //     return caseDependencyList;
    // }
    
    /*
* Purpose : To fetch the records from MobileAppStatus__mdt metadata
* Created by : Ajay Thakur
*/
    public static Map<String,MobileAppStatus__mdt> getMobileAppColorCode()
    {
        List<MobileAppStatus__mdt> mobileAppFieldList = MobileAppStatus__mdt.getall().values();
        
        Map<String,MobileAppStatus__mdt> mobileAppMap = new Map<String,MobileAppStatus__mdt>();
        
        for(MobileAppStatus__mdt mobileAppStatus : mobileAppFieldList)
        {
            if(!mobileAppMap.containsKey(mobileAppStatus.MasterLabel))
                mobileAppMap.put(mobileAppStatus.MasterLabel, mobileAppStatus);            
                
        }
        
        return mobileAppMap;
    }

    /*
    * Purpose : To fetch the records from OfferLinesService__mdt metadata
    * Created by : Ajay Thakur
    */
    public static Map<String,OfferLinesService__mdt> getOfferLineService()
    {
        List<OfferLinesService__mdt> OfferLineService = OfferLinesService__mdt.getall().values();
        
        Map<String,OfferLinesService__mdt> OfferLineServiceMap = new Map<String,OfferLinesService__mdt>();
        
        for(OfferLinesService__mdt OfferService : OfferLineService)
        {
            if(!OfferLineServiceMap.containsKey(OfferService.FieldAPI__c))
            OfferLineServiceMap.put(OfferService.FieldAPI__c, OfferService);            
                
        }
        
        return OfferLineServiceMap;
    }

    /**
    * amountInWords 
    *
    * This method is used to convert the amount into text
    * 
    * @usage opportunityUnitSearchController
    *
    * @param amount    amount to be converted
    * @param currencyUnit   primary currency unit
    * @param currencySubUnit    secondary unit/subunit
    * @return   string amount in words
    */
    public static string amountInWords(decimal amount, string currencyUnit, String currencySubUnit){
        String amountInWords = '';
        if(amount !=null){
            Decimal totalAmount = amount.setScale(2) ;
            String totalAmountString = String.valueOf(totalAmount);
            String beforeDecimal='';
            String afterDecimal='';
            
            if(totalAmountString.contains('.')){
                beforeDecimal = totalAmountString.substringBefore('.');
                beforeDecimal = NumberToText.convert(Integer.valueOf(beforeDecimal));

                afterDecimal = totalAmountString.substringAfter('.');
                afterDecimal = NumberToText.convert(Integer.valueOf(afterDecimal));
                
            }else{
                beforeDecimal = NumberToText.convert(Integer.valueOf(totalAmount));
            }
            
            if(String.isNotBlank(beforeDecimal)){
                amountInWords =  beforeDecimal + ' '+currencyUnit+' ';
            }
            if(String.isNotBlank(afterDecimal) && afterDecimal !='Zero'){
                amountInWords = amountInWords + 'and ' +afterDecimal + ' '+currencySubUnit+' ';
            }
            amountInWords = amountInWords +'Only.' ;
        }
        return amountInWords;
    }

    public static Messaging.EmailFileAttachment setEmailFileAtt(ContentVersion cvObj) {
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
        Blob fileData = cvObj.VersionData;
        emlAtt.setFilename(cvObj.Title);
        emlAtt.setBody(fileData);
        return emlAtt;
    }

    //----- Get SR Automation by set of strings
    public static Map<String,SRAutomation__mdt> getSRAutomation(Set<String> srTypes){
        Map<String,SRAutomation__mdt> srAutomationMap = new Map<String,SRAutomation__mdt>();
        
        List<SRAutomation__mdt> srAutomationList = SRAutomation__mdt.getall().values();

        for(SRAutomation__mdt srAutomationDetails : srAutomationList){
            if(srTypes.contains(srAutomationDetails.MasterLabel)){
                srAutomationMap.put(srAutomationDetails.MasterLabel,srAutomationDetails);
            }
        } 
        return srAutomationMap ; 
    }

    // To get all sub roles.
    public static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {

        Set<ID> currentRoleIds = new Set<ID>();
    
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId 
             IN :roleIds AND ParentRoleID != null]) {
            currentRoleIds.add(userRole.Id);
        }
    
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
    
        return currentRoleIds;
    }
    // To get all Parent Roles.
    public static Set<ID> getParentRoleId(Set<ID> roleIds) {

        Set<ID> currentRoleIds = new Set<ID>();
    
        
        // get all of the parent roles.
        for(UserRole ur :[select Id, ParentRoleId from UserRole where Id IN: roleIds]) {
            currentRoleIds.add(ur.ParentRoleId);
        }
    
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getParentRoleId(currentRoleIds));
        }
    
        return currentRoleIds;
    }

    @AuraEnabled
    public static String maskString(String strText, integer start1, integer end1, String maskChar){
    
        if(strText == null || strText.equals(''))
            return '';
    
        if(start1 < 0)
            start1 = 0;
    
        if( end1 > strText.length() ) 
            end1 = strText.length();
    
            integer maskLength = end1 - start1;
    
        if(maskLength == 0)
            return strText;
    
        String sbMaskString='';
    
        for(integer i = 0; i < maskLength; i++){
            sbMaskString += maskChar;
        }   
    
        return strText.substring(0, start1) + sbMaskString + strText.substring(start1 + maskLength);
    }
    
    public static List<String> getChangedFields(SObject newRec, SObject oldRec, String checkFieldsStr) {
        List<String> updatedFields;
        if(newRec != null || checkFieldsStr != null){
            List<String> toCheckFields =  !(checkFieldsStr.trim().equalsIgnoreCase('OFF')) ? checkFieldsStr.normalizeSpace().replaceAll(', ', ',').split(',') : new List<String>();
            for(String fieldApiName : toCheckFields){
                if( ( oldRec == null && newRec.get(fieldApiName) != null) 
                    || ( oldRec != null && newRec.get(fieldApiName) != oldRec.get(fieldApiName) ) 
                ){
                    if(updatedFields == null) updatedFields = new List<String>();
                    updatedFields.add(fieldApiName);
                }
            }
        }
        return updatedFields;
    }
}