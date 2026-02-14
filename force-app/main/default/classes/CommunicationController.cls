/**********************************************************************************************************************
* Name               : CommunicationController                                                        
* Description        : Class to perform communication and communication template create and updating functionality 
* Usage              : Communication LWC (Used for standard action overrides)                                                     
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public with sharing class CommunicationController {
    /**
    * getAllAgency
    *
    * This method used to return all the agencies in the system
    *
    * @param  none
    * @return list of Agency Account records
    */
    @AuraEnabled(cacheable=true)
    public static list<Account> getAllAgency(string regionFilter,string emiratesFilter, String selectAgencyCountry, String team){
        System.debug(regionFilter);
        System.debug(emiratesFilter);
        // Convert SOQL to Dynamic SOQL by Moh Sarfaraj for BPM-553
        
        Set<Id> setAgencyIds = new Set<Id>();
        Set<Id> setAgencyRecordTypeIds = new Set<Id>{Constants.BROKER_AGENCY_RECORD_TYPE_ID, Constants.NON_REGISTERED_TYPE_ID};
        String query = 'SELECT Account.Id FROM User WHERE Account.RecordTypeId IN : setAgencyRecordTypeIds ';
        
        if(String.isNotBlank(team)){
             query += ' AND Account.Owner.Team__c = :team ';
        }

        if(String.isNotBlank(emiratesFilter)){
            query += ' AND Account.BillingState = :emiratesFilter ';
        }

        if(String.isNotBlank(regionFilter)){
            query += ' AND Account.AgencyRegion__c = :regionFilter ';
        }

        if(String.isNotBlank(selectAgencyCountry)){
            query += ' AND Account.BillingCountry = :selectAgencyCountry ';
        }

        System.debug('query---'+query);
        
        for(User eachUser : (List<User>) Database.query(query)){
            setAgencyIds.add(eachUser.Account.Id);
        }
        
        return [SELECT Id,Name,BillingCountry FROM Account WHERE Id IN :setAgencyIds WITH SECURITY_ENFORCED ORDER BY Name];
    }
    /**
    * getRelatedUsers
    *
    * This method used to return all the users under the given agencies
    *
    * @param  accountIds Agency Ids
    * @return list of Agency user records
    */
    @AuraEnabled(cacheable=true)
    public static list<User> getRelatedUsers(list<String> accountIds){
        return [select id,AccountId,ContactId,Name,Contact.Name,FirstName,LastName,Email from User where AccountId in :accountIds and isActive=true WITH SECURITY_ENFORCED order by name];
    }

    /**
    * getReletedCommunicationRecords
    *
    * This method used to return communication records along with related Communication template
    *
    * @param  CommunicationTemplate__c record ID
    * @return list of CommunicationTemplate__c template records with related child records
    */
    @AuraEnabled(cacheable=false)
    public static list<CommunicationTemplate__c> getReletedCommunicationRecords(String recordId){
        return [select id,name,Compliance__c,MassCommunication__c,HTMLBody__c,Offense__c,PlainTextBody__c,Status__c,SuspensionEndDate__c,SuspensionStartDate__c,Title__c,Type__c,(select id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__r where CommunicationTemplate__r.MassCommunication__c=false limit 1000) from CommunicationTemplate__c where id = :recordId WITH SECURITY_ENFORCED];
    }

    // Added by Moh Sarfaraj BPE-62
    @AuraEnabled(cacheable=false)
    public static void sendToSpecificEmirateAllAgencies(String regionName, 
                                                        String emirateName, 
                                                        String templateId, 
                                                        String testEmail,
                                                        String bannerId) { 
        // Commented by Moh Sarfaraj for BRP-6244 starts  
        //Get the template details
        // CommunicationTemplate__c tempCommunicationRecord = [SELECT Id,Name,Status__c,Compliance__c,SuspensionEndDate__c,
        //                                                     SuspensionStartDate__c,Offense__c,Title__c,PlainTextBody__c,HTMLBody__c 
        //                                                     FROM CommunicationTemplate__c where id = :templateId WITH 
        //                                                     SECURITY_ENFORCED limit 1];
        // //create new
        // Set<Id> setAccountIds = new Set<Id>();
        // list<Communication__c> childRecordsToInsert = new list<Communication__c>();
        // Map<id, String> childRecordsToInsertMap = new Map<Id, String>();
        
        // for(Account eachAcc : getAllAgency(regionName, emirateName, '', '')){
        //     setAccountIds.add(eachAcc.Id);
        // }
        // Map<ID,User> userMapId = new Map<Id,User>();
        // if(!setAccountIds.isEmpty()){
        //     userMapId = new Map<ID,User>([SELECT id,AccountId,ContactId,FirstName,LastName,Email FROM user WHERE 
        //                                  AccountId IN: setAccountIds AND isActive = true WITH SECURITY_ENFORCED]);
        // }
        // for(Communication__c tempCom : [SELECT id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__c where CommunicationTemplate__c = :templateId WITH SECURITY_ENFORCED]){
        //     userMapId.remove(tempCom.Recipient__c);
        // }
        // if(!userMapId.isEmpty()){
        //     for(User tempUser : userMapId.values() ){
        //         if(!childRecordsToInsertMap.containsKey(tempUser.ContactId)){
        //             childRecordsToInsert.add(new Communication__c(CommunicationTemplate__c=templateId, Agency__c= tempUser.AccountId, Agent__c = tempUser.ContactId,Recipient__c=tempUser.Id));
        //             childRecordsToInsertMap.put(tempUser.ContactId, templateId);
        //         }
        //     }
        // }
        // if(!childRecordsToInsert.isEmpty() && tempCommunicationRecord.Status__c == 'Published'){
        //     if(!Schema.sObjectType.Communication__c.isCreateable()){throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        //     //insert childRecordsToInsert;
        //     Database.executeBatch(new CommunicationTryBatch(childRecordsToInsert, tempCommunicationRecord.Id, bannerId));
        // }
        // if(testEmail!=null && testEmail !=''){sendTestEmail(tempCommunicationRecord,testEmail, bannerId);
        // }
        // Commented by Moh Sarfaraj for BRP-6244 end

        // Added by Moh Sarfaraj for BRP-6244 
        Database.executeBatch(new CommunicationBatchByRegion(regionName, emirateName, templateId, testEmail, bannerId), 50);
    }
    
    
    @AuraEnabled(cacheable=false)
    public static void updateUserSelection(String templateId,list<ID> userIDs, list<ID> acountIds, boolean sendAllFlag, string testEmail, String bannerId){
        
        //Get the template details
        CommunicationTemplate__c tempCommunicationRecord = [select id,name,Status__c,Compliance__c,SuspensionEndDate__c,SuspensionStartDate__c,Offense__c,Title__c,PlainTextBody__c,HTMLBody__c from CommunicationTemplate__c where id = :templateId WITH SECURITY_ENFORCED limit 1];
        //create new
        list<Communication__c> childRecordsToInsert = new list<Communication__c>();
        Map<id, String> childRecordsToInsertMap = new Map<Id, String>();


        if(sendAllFlag){tempCommunicationRecord.MassCommunication__c=true;
        }else{
            tempCommunicationRecord.MassCommunication__c=false;
            //delete no required child records
            if(!Schema.sObjectType.Communication__c.isDeletable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            delete [select id from Communication__c where CommunicationTemplate__c= :templateId and ( not Recipient__c in :userIDs) ];
            delete [select id from Communication__c where CommunicationTemplate__c= :templateId and Agency__r.RecordTypeId = :Constants.NON_REGISTERED_TYPE_ID and ( not Agency__c in :acountIds)];
            
           
            //get Non Registered accounts 
            map<id,Account> nonRegisteredAccounts = new map<id,Account>([select id from Account where RecordTypeId = :Constants.NON_REGISTERED_TYPE_ID and id in :acountIds ]);
        
            //Fromr equired once skip the already present once
            set<ID> userIdSet = new set<ID>(userIDs);
            //set<ID> relatedAccountIds = new set<ID>();
            for(Communication__c tempCom : [select id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__c where CommunicationTemplate__c = :templateId WITH SECURITY_ENFORCED]){
                    userIdSet.remove(tempCom.Recipient__c);
                    //relatedAccountIds.add(tempCom.Agency__c);
                    if(nonRegisteredAccounts.containsKey(tempCom.Agency__c)){nonRegisteredAccounts.remove(tempCom.Agency__c);
                    }
            }
            
            if(!userIdSet.isEmpty()){
                for(User tempUser : [select id,AccountId,ContactId,FirstName,LastName,Email from User where id in :userIdSet and isActive=true WITH SECURITY_ENFORCED]){
                    if(!childRecordsToInsertMap.containsKey(tempUser.ContactId)){
                        childRecordsToInsert.add(new Communication__c(CommunicationTemplate__c=templateId, Agency__c= tempUser.AccountId, Agent__c = tempUser.ContactId,Recipient__c=tempUser.Id));
                        childRecordsToInsertMap.put(tempUser.ContactId, templateId);
                    }
                    //relatedAccountIds.add(tempUser.AccountId);
                }
            }
            if(!nonRegisteredAccounts.isEmpty()){
                for(Account tempAcc : nonRegisteredAccounts.values()){childRecordsToInsert.add(new Communication__c(CommunicationTemplate__c=templateId, Agency__c= tempAcc.Id));
                }
            }
        }
        update tempCommunicationRecord;
        
        //Perform action
        if(tempCommunicationRecord.Status__c == 'Published' && tempCommunicationRecord.MassCommunication__c==true){
            map<ID,User> userMapId = new map<ID,User>([select id,AccountId,ContactId,FirstName,LastName,Email from User where accountId!=null and isActive=true and Account.RecordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID WITH SECURITY_ENFORCED]);
                
            for(Communication__c tempCom : [select id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__c where CommunicationTemplate__c = :templateId WITH SECURITY_ENFORCED]){
                userMapId.remove(tempCom.Recipient__c);
            }

            if(!userMapId.isEmpty()){
                for(User tempUser : userMapId.values() ){
                    if(!childRecordsToInsertMap.containsKey(tempUser.ContactId)){
                        childRecordsToInsert.add(new Communication__c(CommunicationTemplate__c=templateId, Agency__c= tempUser.AccountId, Agent__c = tempUser.ContactId,Recipient__c=tempUser.Id));
                        childRecordsToInsertMap.put(tempUser.ContactId, templateId);
                    }
                    
                }
            }
            
            
        }
        // Below comments are by Tharun
        //execute for reaining USers
        //if(tempCommunicationRecord.Status__c == 'Published'){
        //    Database.executeBatch(new CommunicationBatch(tempCommunicationRecord.Id),200);
        //} 

        if(!childRecordsToInsert.isEmpty() && tempCommunicationRecord.Status__c == 'Published'){
            if(!Schema.sObjectType.Communication__c.isCreateable()){throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            //Below comments are by Tharun
            //insert childRecordsToInsert;
            Database.executeBatch(new CommunicationTryBatch(childRecordsToInsert, tempCommunicationRecord.Id, bannerId));
        }
        // Below comments are by Tharun
        
        if(testEmail!=null && testEmail !=''){sendTestEmail(tempCommunicationRecord,testEmail,bannerId);
        }
    }
    public static void sendTestEmail(CommunicationTemplate__c tempCommunicationRecord, string testEmail, String bannerId){
        //Send admin Email
            //EMail list
            String orgWideEmailAddress='';
            for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL limit 1 ]){
                orgWideEmailAddress=tempRec.Id;
            }
            list<Messaging.SingleEmailMessage> emails = new list<Messaging.SingleEmailMessage>();
            list<Communication__c> emailStatusToUpdate = new list<Communication__c>();
            
            //get attachment 
            map<id,list<ID>> templateToContentDocs = new map<id,list<ID>>();
            map<Id,ContentVersion> contentDocToVersion = new map<Id,ContentVersion>();
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :tempCommunicationRecord.Id WITH SECURITY_ENFORCED]){
                if(templateToContentDocs.isEmpty()){
                    templateToContentDocs.put(cdl.LinkedEntityId, new list<ID>());
                }
                templateToContentDocs.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                contentDocToVersion.put(cdl.ContentDocumentId,null);
            }
            for(ContentVersion cv : [SELECT VersionData,title, FileExtension,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in :contentDocToVersion.keySet() AND IsLatest = true WITH SECURITY_ENFORCED]){
                contentDocToVersion.put(cv.ContentDocumentId,cv);
            }
            list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
            if(!contentDocToVersion.isEmpty()){
            
                for(ID conDocId : templateToContentDocs.get(tempCommunicationRecord.Id)){
                    if(contentDocToVersion.containsKey(conDocId)){
                        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
                        Blob fileData = contentDocToVersion.get(conDocId).VersionData;
                        emlAtt.setFilename(contentDocToVersion.get(conDocId).title +'.'+ contentDocToVersion.get(conDocId).FileExtension);
                        emlAtt.setBody(fileData);
                        attachmentList.add(emlAtt);
                    }
                }
            }
            // Below modifications on CommunicationHeader are done by Tharun BPE-175
            // Actual public url for document is "https://aldarproperties--pruat.sandbox.file.force.com/servlet/servlet.ImageServer?id=01525000001XMc2&oid=00D250000009MVUEA2"
            // String baseURL = URL.getOrgDomainUrl().toExternalForm().split('.')[0] +'.file.force.com';
            String CommunicationHeader = URL.getOrgDomainUrl().toExternalForm().split('\\.')[0] + ( Utilities.getOrganizationDetails().IsSandbox ? '.sandbox' : '' ) +'.file.force.com' + '/servlet/servlet.ImageServer?id=' + bannerId + '&oid=' + UserInfo.getOrganizationId();
            System.Debug('CommunicationHeader-----'+CommunicationHeader);
            String htmlData='<body class="setupTab" ><style background-color="#FFFFFF" bEditID="b1st1" bLabel="body" ></style><center ><table cellpadding="0" width="500" cellspacing="0" id="topTable" height="450" ><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r1st1" bLabel="header" vertical-align="top" height="100px" text-align="left" ></style><img border="0" bEditID="r1sp1" bLabel="headerImage" id="r1sp1" src="'+CommunicationHeader+'"></img></td></tr><tr valign="top" ><td ><style background-color="#FFFFFF" bEditID="r2st1" bLabel="accent1" height="5px" ></style>#CONTENT#</td></tr></table></center></body>';
            list<string> adminEmails = testEmail.split(';');
            emails.add(Utilities.getEmailInstance(null,'',null,adminEmails,null,null,tempCommunicationRecord.Title__c,tempCommunicationRecord.PlainTextBody__c,htmlData.replace('#CONTENT#',tempCommunicationRecord.HTMLBody__c),attachmentList,orgWideEmailAddress));
            if(!emails.isEmpty()){
                list<Messaging.SendEmailResult> emailResult  = Utilities.sendEmail(emails);
            }
    }
    /**
    * blockUnblockRelatedAccounts
    *
    * This method used to block the account access, the account trigger is supposed to block all the access
    * This method must be called from scheduled flow of CommunicationTemplate__c object
    *
    * @param  CommunicationTemplate__c record ID
    * @param  status Blocking status
    * @return none
    ****NOT IMPLEMENTED YET
    @AuraEnabled(cacheable=false)
    public static void blockUnblockRelatedAccounts(list<String> templateIds,string status){
        map<id,Account> accountsToUpdate = new map<id,Account>();
        for(Communication__c communicationRecord : [select id,Agency__c from Communication__c where CommunicationTemplate__c in :templateIds WITH SECURITY_ENFORCED] ){
            if(!accountsToUpdate.containsKey(communicationRecord.Agency__c)){
                accountsToUpdate.put(communicationRecord.Agency__c, new Account(id = communicationRecord.Agency__c,AgencyStatus__c=status));
            }
        }
        if(!Schema.sObjectType.Account.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update accountsToUpdate.values();
        
    }*/

    /**
    * reparentCDL
    *
    * This method used to reparent all the uploaded attachment under the selected CommunicationTemplate__c record
    *
    * @param  fileData List of files with name and ContentDocumentId
    * @param  templateId record ID where all documents must be reparented
    * @return none
    */
    @AuraEnabled(cacheable=false)
    public static void reparentCDL(list<FileResponse> fileData,String templateId){
        list<ContentDocument> cdlToDelete = new list<ContentDocument>();
        set<String> documentIDs = new set<String>();
        for(FileResponse tempRec : fileData){
            documentIDs.add(tempRec.documentId);
        }
        for(ContentDocumentLink cdl : [select id,ContentDocumentId from ContentDocumentLink where LinkedEntityId = :templateId WITH SECURITY_ENFORCED]){
            if(documentIDs.contains(cdl.ContentDocumentId)){
                documentIDs.remove(cdl.ContentDocumentId);
            }else{
                cdlToDelete.add(new ContentDocument(id = cdl.ContentDocumentId));
            }
            
        }
        
        list<ContentDocumentLink> cdlToInsert = new list<ContentDocumentLink>();
        for(String docID : documentIDs){
            cdlToInsert.add(new ContentDocumentLink(ContentDocumentId=docID , LinkedEntityId=templateId));
        }
        if(!cdlToInsert.isEmpty()){
            insert cdlToInsert;
        }
        if(!cdlToDelete.isEmpty()){ delete cdlToDelete;
        }
    }

    /**
    * getExistingCDL
    *
    * This method used to retrive existing ContentDocuments with name and Ids
    *
    * @param  templateId record ID where all documents available
    * @return FileResponse wwarraper with name and ContentDocumentId
    */
    @AuraEnabled(cacheable=false)
    public static list<FileResponse> getExistingCDL(String templateId){
        list<FileResponse> listToReturn = new list<FileResponse>();
        
        if(templateId!=null && templateId!=''){
            for(ContentDocumentLink tempCDL : [select id, ContentDocumentId, ContentDocument.Title,ContentDocument.FileExtension,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :templateId WITH SECURITY_ENFORCED]){
                listToReturn.add(new FileResponse(tempCDL.ContentDocument.Title+'.'+ tempCDL.ContentDocument.FileExtension,tempCDL.ContentDocumentId) );
            }
        }
        return listToReturn;
    }

    /**
    * getExistingCDL
    *
    * FileResponse warraper with name and ContentDocumentId
    */
    public class FileResponse{
        @AuraEnabled
        public string name  {get; set;}
        @AuraEnabled
        public string documentId  {get; set;}
        public FileResponse(){}
        public FileResponse(string fname, string docId){
            name=fname;
            documentId=docId;
        }
    }

    /**
    * getCommunicationInbox
    *
    * This method used to get the communications inbox
    *
    * @return list of loged in user inbox communications
    */
    @AuraEnabled(cacheable=true)
    public static List<CommunicationWrapper> getCommunicationInbox(string title, string offense){
        
        List<CommunicationWrapper> CommunicationWrapperValues = new List<CommunicationWrapper>();
          for(Communication__c tempCommunication : [select CommunicationTemplate__r.Offense__c,
                                                    CommunicationTemplate__r.PlainTextBody__c,
                                                    CommunicationTemplate__r.Status__c, CreatedById,
                                                    OwnerId,Owner.FirstName,Owner.LastName,CreatedBy.FirstName, 
                                                    CreatedBy.LastName, CommunicationTemplate__r.Title__c, 
                                                    CommunicationTemplate__r.Type__c, CommunicationTemplate__r.Id,
                                                    isPublished__c, CreatedDate, Recipient__c,Recipient__r.FirstName,
                                                    Recipient__r.LastName from Communication__c WHERE 
                                                    Recipient__c = :UserInfo.getUserId() AND isPublished__c= true 
                                                    order by lastModifiedDate desc]){
                                                        
              CommunicationWrapperValues.add(new CommunicationWrapper(tempCommunication));
          }
        
        return CommunicationWrapperValues;
    }

    /**
    * getCommunicationOutbox
    *
    * This method used to get the communications outbox
    *
    * @return list of loged in user outbox communications
    */
    @AuraEnabled(cacheable=false)
    public static List<CommunicationWrapper> getCommunicationOutbox(string title, string offense){

        /*List<CommunicationWrapper> CommunicationWrapperValues = new List<CommunicationWrapper>();

       if (String.isNotEmpty(title) && String.isNotEmpty(offense)) {
            for(Communication__c tempCommunication : [select CommunicationTemplate__r.Offense__c,CommunicationTemplate__r.Status__c, CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CommunicationTemplate__r.Title__c, CommunicationTemplate__r.Type__c , isPublished__c, CreatedDate, Recipient__c , Recipient__r.FirstName, Recipient__r.LastName from Communication__c WHERE CreatedById=:UserInfo.getUserId()  AND CommunicationTemplate__r.Title__c  LIKE:'%' + title + '%' AND CommunicationTemplate__r.Offense__c =:offense]){
                CommunicationWrapperValues.add(new CommunicationWrapper(tempCommunication));
            }
        } else if (String.isNotEmpty(title)){
            for(Communication__c tempCommunication : [select CommunicationTemplate__r.Offense__c,CommunicationTemplate__r.Status__c, CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CommunicationTemplate__r.Title__c, CommunicationTemplate__r.Type__c , isPublished__c, CreatedDate, Recipient__c , Recipient__r.FirstName, Recipient__r.LastName from Communication__c WHERE CreatedById=:UserInfo.getUserId()  AND CommunicationTemplate__r.Title__c  LIKE:'%' + title + '%']){
                CommunicationWrapperValues.add(new CommunicationWrapper(tempCommunication));
            }     
        } else if (String.isNotEmpty(offense)){
            for(Communication__c tempCommunication : [select CommunicationTemplate__r.Offense__c,CommunicationTemplate__r.Status__c, CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CommunicationTemplate__r.Title__c, CommunicationTemplate__r.Type__c , isPublished__c, CreatedDate, Recipient__c , Recipient__r.FirstName, Recipient__r.LastName from Communication__c WHERE CreatedById=:UserInfo.getUserId()  AND CommunicationTemplate__r.Offense__c =:offense]){
                CommunicationWrapperValues.add(new CommunicationWrapper(tempCommunication));
            }    
        } else {
            for(Communication__c tempCommunication : [select CommunicationTemplate__r.Offense__c,CommunicationTemplate__r.Status__c, CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CommunicationTemplate__r.Title__c, CommunicationTemplate__r.Type__c , isPublished__c, CreatedDate, Recipient__c , Recipient__r.FirstName, Recipient__r.LastName from Communication__c WHERE CreatedById=:UserInfo.getUserId() ]){
                CommunicationWrapperValues.add(new CommunicationWrapper(tempCommunication));
            }
        }*/
        List<CommunicationWrapper> CommunicationWrapperValues = new List<CommunicationWrapper>();
        for( CommunicationTemplate__c templatRecord:[select id,name,CreatedById,Owner.FirstName,Owner.LastName, CreatedDate, CreatedBy.FirstName,OwnerId, CreatedBy.LastName,Compliance__c,HTMLBody__c,Offense__c,PlainTextBody__c,Status__c,SuspensionEndDate__c,SuspensionStartDate__c,Title__c,Type__c,(select id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__r) from CommunicationTemplate__c where CreatedById=:UserInfo.getUserId() WITH SECURITY_ENFORCED order by lastModifiedDate desc]){
            CommunicationWrapperValues.add( new CommunicationWrapper(templatRecord));
        }
        return CommunicationWrapperValues;

    }

    class CommunicationWrapper {
        @AuraEnabled
        public String Status{ get; set;}
        @AuraEnabled
        public String CreatedById{ get; set;}
        @AuraEnabled
        public String Title{ get; set;}
        @AuraEnabled
        public String Type{ get; set; }
        @AuraEnabled
        public Boolean isPublished{ get; set;}
        @AuraEnabled
        public String Recipient{ get; set;}
        @AuraEnabled
        public String Offense{ get; set;}
        @AuraEnabled
        public String id{ get; set;}
        @AuraEnabled
        public Date createdDate{ get; set;}
        @AuraEnabled
        public String message{ get; set;}
      
        CommunicationWrapper(Communication__c communicationRecord){
            Status = communicationRecord.CommunicationTemplate__r.Status__c;
            CreatedById = communicationRecord.Owner.FirstName + ' ' + communicationRecord.Owner.LastName;
            Type = communicationRecord.CommunicationTemplate__r.Type__c;
            Title = communicationRecord.CommunicationTemplate__r.Title__c;
            isPublished = communicationRecord.isPublished__c;
            Recipient = communicationRecord.Recipient__r.FirstName + ' ' + communicationRecord.Recipient__r.LastName;
            Offense = communicationRecord.CommunicationTemplate__r.Offense__c;
            id = communicationRecord.CommunicationTemplate__r.Id;
            message = communicationRecord.CommunicationTemplate__r.PlainTextBody__c;
            createdDate = date.newinstance(communicationRecord.CreatedDate.year(), communicationRecord.CreatedDate.month(), communicationRecord.CreatedDate.day());
        }
        CommunicationWrapper(CommunicationTemplate__c templateRecord){
            Status = templateRecord.Status__c;
            CreatedById = templateRecord.Owner.FirstName + ' ' + templateRecord.Owner.LastName;
            Type = templateRecord.Type__c;
            Title = templateRecord.Title__c;
            isPublished = (templateRecord.Status__c == 'Published');
            Recipient = '';
            Offense = templateRecord.Offense__c;
            id = templateRecord.Id;
            message = templateRecord.PlainTextBody__c;
            createdDate = date.newinstance(templateRecord.CreatedDate.year(), templateRecord.CreatedDate.month(), templateRecord.CreatedDate.day());
        }

    }

    /**
    * sendEmailBrokerFilterCommunication
    * This method used to Send Communication for all classified Brokers
    * @param 
    * @return true or false
    * @description Developed by Moh Sarfaraj for BPE-79, BPE-113
    */
    @AuraEnabled(cacheable=false)
    public static Boolean sendEmailBrokerFilterCommunication(String commTemplateId, 
                                                             Boolean isClassifiedBroker, 
                                                             Boolean isCustomEmail, 
                                                             String emails, 
                                                             Boolean isAgentCategory, 
                                                             String filter, 
                                                             String testEmail,
                                                             String bannerId){
        Boolean isSuccess = false;
        //Get the template details
        CommunicationTemplate__c tempCommunicationRecord = [SELECT Id,Name,Status__c,Compliance__c,SuspensionEndDate__c,
                                                            SuspensionStartDate__c,Offense__c,Title__c,PlainTextBody__c,HTMLBody__c 
                                                            FROM CommunicationTemplate__c where id = :commTemplateId WITH 
                                           
                                                            SECURITY_ENFORCED LIMIT 1];

        List<Communication__c> childRecordsToInsert = new List<Communication__c>();
        Map<String,String> childRecordsToInsertMap = new Map<String,String>();

        if((isClassifiedBroker || isAgentCategory || String.isNotBlank(filter))){
            // updated by Moh Sarfaraj for BPE-113 
            Map<Id,User> userMapId = new Map<Id,User>();
            if(isClassifiedBroker){
                userMapId = new Map<Id,User>([SELECT Id,AccountId,ContactId,FirstName,LastName,Email FROM User WHERE Account.BrokerPremiumClassification__c = true AND 
                                              Account.RecordTypeId IN (:Constants.BROKER_AGENCY_RECORD_TYPE_ID, :Constants.NON_REGISTERED_TYPE_ID) AND isActive = true WITH SECURITY_ENFORCED]);
            }else if(isAgentCategory && String.isNotBlank(filter)){
                Set<String> setAgentCategory = new Set<String>(((filter.subStringBetween('[',']')).replaceAll('"', '')).split(','));
                userMapId = new Map<Id,User>([SELECT Id,AccountId,ContactId,FirstName,LastName,Email FROM User WHERE Contact.AgentCategory__c IN: setAgentCategory AND
                                                Account.RecordTypeId IN (:Constants.BROKER_AGENCY_RECORD_TYPE_ID, :Constants.NON_REGISTERED_TYPE_ID) AND isActive = true WITH SECURITY_ENFORCED]);
            } // Added by Moh Sarfaraj for BPE-167
            else if(String.isNotBlank(filter) && filter.contains('sendToAgencyAdminOwner')){
                userMapId = new Map<Id,User>([SELECT Id,AccountId,ContactId,FirstName,LastName,Email FROM User WHERE Contact.BrokerType__c IN ('Partner/Owner', 'Agency Admin') AND
                                                Account.RecordTypeId IN (:Constants.BROKER_AGENCY_RECORD_TYPE_ID, :Constants.NON_REGISTERED_TYPE_ID) AND isActive = true WITH SECURITY_ENFORCED]);
            }
            if(!userMapId.isEmpty()){
                for(User tempUser : userMapId.values()){
                    if(!childRecordsToInsertMap.containsKey(tempUser.ContactId)){
                        childRecordsToInsert.add(
                            new Communication__c(
                                CommunicationTemplate__c = commTemplateId, Agency__c = tempUser.AccountId, 
                                Agent__c = tempUser.ContactId, Recipient__c = tempUser.Id
                            )
                        );
                        childRecordsToInsertMap.put(tempUser.ContactId, commTemplateId);
                    }
                }
            }
        }else if(isCustomEmail){
            if(String.isNotBlank(emails)){
                for(String email : emails.split(',')){
                    if(!childRecordsToInsertMap.containsKey(email)){
                        childRecordsToInsert.add(
                            new Communication__c(
                                CommunicationTemplate__c = commTemplateId, Email__c = email.trim()
                            )
                        );
                        childRecordsToInsertMap.put(email, commTemplateId);
                    }
                }
            }
        }
        if(!childRecordsToInsert.isEmpty() && tempCommunicationRecord.Status__c == 'Published'){
            if(!Schema.sObjectType.Communication__c.isCreateable()){throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
            //insert childRecordsToInsert;
            Database.executeBatch(new CommunicationTryBatch(childRecordsToInsert, tempCommunicationRecord.Id,bannerId));
            isSuccess = true;
        }
        if(testEmail != null && testEmail != ''){
            sendTestEmail(tempCommunicationRecord,testEmail, bannerId);
        }
        return isSuccess;
    }
    
    /**
    * getBrokerDocBanners
    * @Description  :This method used to get banners which are used in Communication Template
    * @Author       :Tharun
    * @JIRA         :BPE-175
    */
    @AuraEnabled(cacheable=true)
    public static list<Document> getBrokerDocBanners(){
        return [SELECT id, Name, Keywords FROM 
                Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                ORDER BY CreatedDate DESC];
    }
}