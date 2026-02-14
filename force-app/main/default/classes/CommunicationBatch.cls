/**********************************************************************************************************************
* Name               : CommunicationBatch                                                        
* Description        : Class to perform mass communication communication (Email/SMS/WhatsApp). 
* Usage              : CommunicationController 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
global class CommunicationBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    private Id templateId;
    Id bannerId;
    //should be executed with 1 template at a time
    public CommunicationBatch(Id templateIdsToProcess, Id receivedBannerId){
        templateId 	= templateIdsToProcess;
        bannerId 	= receivedBannerId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id, Agency__c,Agency__r.Email__c,Agency__r.MobileCountryCode__c,Agency__r.MobileNumber1__c, Agent__c,Agent__r.MobileCountryCode__c,Agent__r.MobilePhone__c, Recipient__c,CommunicationTemplate__c,Recipient__r.MobilePhone,Email__c from Communication__c where CommunicationTemplate__c = :templateId and Status__c != \'Sent\' order by CommunicationTemplate__c';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Communication__c> scope){
        map<id,CommunicationTemplate__c> templateDetails = new map<id,CommunicationTemplate__c>([select id,Title__c,Type__c,HTMLBody__c,PlainTextBody__c from CommunicationTemplate__c where id = :templateId WITH SECURITY_ENFORCED]);
       
        //EMail list
        String orgWideEmailAddress='';
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_BROKER limit 1 ]){
            orgWideEmailAddress=tempRec.Id;
        }
        list<Messaging.SingleEmailMessage> emails = new list<Messaging.SingleEmailMessage>();
        list<Communication__c> emailStatusToUpdate = new list<Communication__c>();
        
        //get attachment 
        map<id,list<ID>> templateToContentDocs = new map<id,list<ID>>();
        map<Id,ContentVersion> contentDocToVersion = new map<Id,ContentVersion>();
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in :templateDetails.keySet() WITH SECURITY_ENFORCED]){
            if(templateToContentDocs.isEmpty()){
                templateToContentDocs.put(cdl.LinkedEntityId, new list<ID>());
            }
            templateToContentDocs.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            contentDocToVersion.put(cdl.ContentDocumentId,null);
        }
        for(ContentVersion cv : [SELECT VersionData,title, FileExtension,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in :contentDocToVersion.keySet() AND IsLatest = true WITH SECURITY_ENFORCED]){
            contentDocToVersion.put(cv.ContentDocumentId,cv);
        }

        //Phone List
        //SMS non bulified
        String phoneMessage='';
        list<String> phoneNumbers = new list<String>();
        list<Communication__c> phoneStatusToUpdate = new list<Communication__c>();
        list<Communication__c> phoneStatusToUpdate_FailedNoNumber = new list<Communication__c>();

		// Below modifications on CommunicationHeader are done by Tharun BPE-175
        // Actual public url for document is "https://aldarproperties--pruat.sandbox.file.force.com/servlet/servlet.ImageServer?id=01525000001XMc2&oid=00D250000009MVUEA2"
        // String baseURL = URL.getOrgDomainUrl().toExternalForm().split('.')[0] +'.file.force.com';
        String CommunicationHeader = URL.getOrgDomainUrl().toExternalForm().split('\\.')[0] + ( Utilities.getOrganizationDetails().IsSandbox ? '.sandbox' : '' ) +'.file.force.com' + '/servlet/servlet.ImageServer?id=' + bannerId + '&oid=' + UserInfo.getOrganizationId();
        System.Debug('CommunicationHeader-----'+CommunicationHeader);
        String htmlData='<body class="setupTab" ><style background-color="#FFFFFF" bEditID="b1st1" bLabel="body" ></style><center ><table cellpadding="0" width="500" cellspacing="0" id="topTable" height="450" ><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r1st1" bLabel="header" vertical-align="top" height="100px" text-align="left" ></style><img border="0" bEditID="r1sp1" bLabel="headerImage" id="r1sp1" src="'+CommunicationHeader+'"></img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r2st1" bLabel="accent1" height="5px" ></style>#CONTENT#</td></tr></table></center></body>';
        //string htmlData='<body class="setupTab" ><style background-color="#FFFFFF" bEditID="b1st1" bLabel="body" ></style><center ><table cellpadding="0" width="500" cellspacing="0" id="topTable" height="450" ><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r1st1" bLabel="header" vertical-align="top" height="100px" text-align="left" ></style><img border="0" bEditID="r1sp1" bLabel="headerImage" id="r1sp1" src="'+System.Label.CommunicationHeader+'"></img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r2st1" bLabel="accent1" height="5px" ></style>#CONTENT#</td></tr></table></center></body>';
        //For each record
        for(Communication__c tempRecord :scope ){
            if(templateDetails.containsKey(tempRecord.CommunicationTemplate__c)){
                CommunicationTemplate__c templateRecord = templateDetails.get(tempRecord.CommunicationTemplate__c);
                if(templateRecord.Type__c == 'Email'){
                    list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
                    if(templateToContentDocs.containsKey(templateRecord.Id)){
                   
                        for(ID conDocId : templateToContentDocs.get(templateRecord.Id)){
                            if(contentDocToVersion.containsKey(conDocId)){
                                Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
                                Blob fileData = contentDocToVersion.get(conDocId).VersionData;
                                emlAtt.setFilename(contentDocToVersion.get(conDocId).title +'.'+ contentDocToVersion.get(conDocId).FileExtension);
                                emlAtt.setBody(fileData);
                                attachmentList.add(emlAtt);
                            }
                        }
                    }
                    if(tempRecord.Recipient__c!=null){
                        emails.add(Utilities.getEmailInstance(tempRecord.Recipient__c,'',null,null,null,null,templateRecord.Title__c,templateRecord.PlainTextBody__c,htmlData.replace('#CONTENT#',templateRecord.HTMLBody__c),attachmentList,orgWideEmailAddress));
                    }else if(String.isNotBlank(tempRecord.Email__c)){
                        emails.add(Utilities.getEmailInstance(null,'',null,new List<String>{tempRecord.Email__c},null,null,templateRecord.Title__c,templateRecord.PlainTextBody__c,htmlData.replace('#CONTENT#',templateRecord.HTMLBody__c),attachmentList,orgWideEmailAddress));
                    }else{
                        emails.add(Utilities.getEmailInstance(null,'',null,new List<String>{tempRecord.Agency__r.Email__c},null,null,templateRecord.Title__c,templateRecord.PlainTextBody__c,htmlData.replace('#CONTENT#',templateRecord.HTMLBody__c),attachmentList,orgWideEmailAddress));
                    }
                    
                    emailStatusToUpdate.add(tempRecord);
                }else if(templateRecord.Type__c == 'SMS'){
                    phoneMessage=templateRecord.PlainTextBody__c;
                    if(tempRecord.Recipient__c !=null && tempRecord.Agent__r.MobileCountryCode__c!=null && tempRecord.Agent__r.MobilePhone__c!='' ){
                        phoneNumbers.add(tempRecord.Agent__r.MobileCountryCode__c + tempRecord.Agent__r.MobilePhone__c);
                        phoneStatusToUpdate.add(tempRecord);
                    }else if(tempRecord.Recipient__c==null && tempRecord.Agency__r.MobileCountryCode__c !=null && tempRecord.Agency__r.MobileNumber1__c !=null ){
                        phoneNumbers.add(tempRecord.Agency__r.MobileCountryCode__c+tempRecord.Agency__r.MobileNumber1__c);
                        phoneStatusToUpdate.add(tempRecord);
                    }else{
                        tempRecord.Status__c='Failed';
                        phoneStatusToUpdate_FailedNoNumber.add(tempRecord);
                    }

                }else if(templateRecord.Type__c == 'WhatsApp'){

                }
            }
        }
      
        if(!emails.isEmpty()){
            list<Messaging.SendEmailResult> emailResult  = Utilities.sendEmail(emails);
            for(integer i=0 ; i< emailResult.size() ; i ++){
                emailStatusToUpdate[i].Status__c = emailResult[i].isSuccess()?'Sent':'Failed';
            }
            if(!Schema.sObjectType.Communication__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            update emailStatusToUpdate;
        }
        if(!phoneNumbers.isEmpty()){
            APISetting__mdt  smsAPI = Utilities.getServiceDetails(Constants.SMSBULK);
            
            map<string,object> requestMap = new map<string,object>();
            requestMap.put('source',smsAPI.Source__c);
            requestMap.put('destination',phoneNumbers);
            requestMap.put('text',phoneMessage);
            string JSONBody = JSON.serialize(requestMap);

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            Blob headerValue = Blob.valueOf(smsAPI.username__c + ':' + smsAPI.apiId__c);
            
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(headerValue));
            request.setEndpoint(smsAPI.SandboxURL__c);
            request.setMethod(smsAPI.Method__c);
            request.setBody(JSONBody);
            request.setTimeout(120000);
            HttpResponse response = http.send(request);
            boolean success = (response!=null && response.getStatusCode() == 200);
            list<object> responseMap =  new list<object>();
            if(success){
                responseMap = (list<object>) JSON.deserializeUntyped(response.getBody());
            }
            for(integer i=0 ; i< phoneStatusToUpdate.size() ; i ++){
                phoneStatusToUpdate[i].Status__c = (success && Integer.ValueOF(((map<string,object>) responseMap[i]).get('ErrorCode'))==0 )?'Sent':'Failed';
            }
            

        }
        if(!phoneStatusToUpdate.isEmpty()){
            if(!Schema.sObjectType.Communication__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            update phoneStatusToUpdate;
        }
        if(!phoneStatusToUpdate_FailedNoNumber.isEmpty()){
            if(!Schema.sObjectType.Communication__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            update phoneStatusToUpdate_FailedNoNumber;
        }

    }    
    global void finish(Database.BatchableContext bc){}    
}