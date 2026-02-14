/**********************************************************************************************************************
* Name               : ActivityController                                                        
* Description        : Class to create and access broker events and activities
* Usage              : Event and Activities LWC 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public with sharing class ActivityController{
    /**
    * getMyAgencyEventsActivities
    *
    * This method used to return all activities and Events related to logged in user's Account
    *
    * @param  none
    * @return ActivityDetails wapper
    */
    @AuraEnabled(cacheable=true)
    public static list<ActivityDetails> getMyAgencyEventsActivities(){
        return getMyBrokerActivityRecords(new set<ID>{Schema.SObjectType.BrokerActivities__c.getRecordTypeInfosByDeveloperName().get(Constants.BROKER_ACTIVITY_TYPE_ACTIVITY).getRecordTypeId(),Schema.SObjectType.BrokerActivities__c.getRecordTypeInfosByDeveloperName().get(Constants.BROKER_ACTIVITY_TYPE_EVENT).getRecordTypeId()});
    }
    
    /**
    * getMyAgencyEvents
    *
    * This method used to return all Events related to logged in user's Account
    *
    * @param  none
    * @return ActivityDetails wapper
    */
    @AuraEnabled(cacheable=true)
    public static list<ActivityDetails> getMyAgencyEvents(){
        return getMyBrokerActivityRecords(new set<ID>{Schema.SObjectType.BrokerActivities__c.getRecordTypeInfosByDeveloperName().get(Constants.BROKER_ACTIVITY_TYPE_EVENT).getRecordTypeId()});
    }

    /**
    * getMyAgencyActivity
    *
    * This method used to return all Activities related to logged in user's Account
    *
    * @param  none
    * @return ActivityDetails wapper
    */
    @AuraEnabled(cacheable=true)
    public static list<ActivityDetails> getMyAgencyActivity(){
        return getMyBrokerActivityRecords(new set<ID>{Schema.SObjectType.BrokerActivities__c.getRecordTypeInfosByDeveloperName().get(Constants.BROKER_ACTIVITY_TYPE_ACTIVITY).getRecordTypeId()});
    }
    
    /**
    * getMyBrokerActivityRecords
    *
    *  This method used to return all activities and Events related to logged in user's Account based on record type
    *
    * @param  recodTypeIds activity and/or event record type ids to retrive
    * @return ActivityDetails wapper
    */
    public static list<ActivityDetails> getMyBrokerActivityRecords(set<Id> recodTypeIds){
        Date twoMotnhsBack = system.today().addMonths(-12);
        list<ActivityDetails> recordToReturn = new list<ActivityDetails>();
        //get all the records for my Agency
        set<ID> assignedActivities = new set<ID>();
        User tempUser =[select id,AccountId,ContactId from User where id =:userInfo.getUserId() limit 1];
        system.debug(tempUser.AccountId);
        if(tempUser.AccountId !=null ){
            set<ID> relatedAccounts = new set<Id>{tempUser.AccountId};
            for(AccountContactRelation tempACRel :[select id,AccountId from AccountContactRelation where ContactId = :tempUser.ContactId WITH SECURITY_ENFORCED]){
                relatedAccounts.add(tempACRel.AccountId);
            }
            for(ActivityMapping__c tempRec: [select id, Activity__c from ActivityMapping__c where Agency__c = :relatedAccounts WITH SECURITY_ENFORCED]){
                assignedActivities.add(tempRec.Activity__c);
            }
            list<BrokerActivities__c> activities = [select id,Name,RecordType.Name, Description__c, EndDate__c, EndTime__c, ExternalLink__c, Location__c, ShortDescription__c, SocialMediaLink1__c,
                                                     StartDate__c, StartTime__c, Status__c, Type__c, VirtualTourLink__c,(select id,DocumentType__c from Documents__r) from BrokerActivities__c where StartDate__c > :twoMotnhsBack and id in :assignedActivities and recordTypeId in :recodTypeIds and Status__c != :Constants.OPPO_UNIT_STATUS_PENDING WITH SECURITY_ENFORCED order by StartDate__c desc];
            
            if(!activities.isEmpty()){
                map<id,list<Document__c>> activityToDocMap = getActivityDocs((new map<id,BrokerActivities__c>(activities)).keySet());

                map<id,list<PublicLinkDetails>> docRelatedContentVersions = new map<id,list<PublicLinkDetails>>();
                for(BrokerActivities__c tempActivity : activities){
                    if(activityToDocMap.containsKey(tempActivity.Id) ){
                        for(Document__c tempDoc : activityToDocMap.get(tempActivity.Id) ){
                            docRelatedContentVersions.put(tempDoc.Id ,new list<PublicLinkDetails>());
                        }
                    }
                }
                for(ContentDistribution dist : getPublicDocumentURL(docRelatedContentVersions.keySet()) ){
                    docRelatedContentVersions.get(dist.RelatedRecordId).add(new PublicLinkDetails(dist));
                }
                for(BrokerActivities__c tempActivity : activities){
                    map<String,list<PublicLinkDetails>> docDetails = new map<String,list<PublicLinkDetails>>();
                    if(activityToDocMap.containsKey(tempActivity.Id) ){
                        for(Document__c tempDoc : activityToDocMap.get(tempActivity.Id) ){
                            docDetails.put(tempDoc.DocumentType__c , docRelatedContentVersions.get(tempDoc.Id) );
                        }
                    }
                    recordToReturn.add(new ActivityDetails(tempActivity, docDetails) );
                }
            }
            
        }
        return recordToReturn;
    }

    /**
    * getAllAgency
    *
    * This method used to return all the agencies in the based on account name
    *
    * @param  none
    * @return list of Agency Account records
    */
    @AuraEnabled(cacheable=true)
    public static list<Account> getAllAgency(String accountName){
        if (accountName != null) {
            return [select id,Name from account where recordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID AND ApprovalStatus__c!=:Constants.SUBMITTED AND  AgencyStatus__c = :Constants.ACTIVE And Name LIKE :'%' + accountName + '%' WITH SECURITY_ENFORCED];
        }else{
            return [select id,Name from account where recordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID AND ApprovalStatus__c!=:Constants.SUBMITTED AND AgencyStatus__c = :Constants.ACTIVE WITH SECURITY_ENFORCED ];
        }
    }


    /**
    * getSelectedAgency
    *
    * This method used to retrive ActivityMapping__c for the given activities (used to preselect the accounts)
    *
    * @param  none
    * @return list of Agency Account records
    */
    @AuraEnabled(cacheable=true)
    public static list<ActivityMapping__c> getSelectedAgency(String recordId){
        return [select id,Agency__c from ActivityMapping__c where Activity__c =:recordId WITH SECURITY_ENFORCED];
    }


    /**
    * saveActivityMapping
    *
    * This method used to store all the activity and account mapping records
    *
    * @param  activityID activity ID
    * @param  accountIDs list of account to associate with
    * @param  emailFlag flag  represents weather to send notification or not
    * @return list of Agency Account records
    */
    @AuraEnabled
    public static String saveActivityMapping(String activityID, list<String> accountIDs, Boolean emailFlag){
        String message='success';
        try{
            set<String> relatedAgency = new set<String>(accountIDs);
            list<ActivityMapping__c> agencyRecordsToDelete = new list<ActivityMapping__c>();
            list<ActivityMapping__c> agencyRecordsToInsert = new list<ActivityMapping__c>();
            for(ActivityMapping__c tempRec : [select id,Agency__c from ActivityMapping__c where Activity__c = :activityID]){
                if(relatedAgency.contains(tempRec.Agency__c)){
                    relatedAgency.remove(tempRec.Agency__c);
                }else{
                    agencyRecordsToDelete.add(tempRec);
                }
            }
            
            for(String tempID : relatedAgency){
                agencyRecordsToInsert.add(new ActivityMapping__c(Activity__c= activityID, Agency__c=tempID ,SendNotification__c= emailFlag) );
            }
            
         // Run batch for insert records
        if(!agencyRecordsToInsert.isEmpty()){
            if(!Schema.sObjectType.ActivityMapping__c.isCreateable()) { 
                throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); 
            }
            ActivityMappingNotificationBatch insertBatch = new ActivityMappingNotificationBatch(agencyRecordsToInsert, 'insert');
            Database.executeBatch(insertBatch, 1);
        }

        // Run batch for delete records
        if(!agencyRecordsToDelete.isEmpty()){
            if(!Schema.sObjectType.ActivityMapping__c.isDeletable()) { 
                throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); 
            }
            ActivityMappingNotificationBatch deleteBatch = new ActivityMappingNotificationBatch(agencyRecordsToDelete, 'delete');
            Database.executeBatch(deleteBatch, 1);
        }
        }catch(exception e){
            message=e.getMessage();
        }
        return message;

    }

    /**
    * ActivityDetails
    *
    * Wrapper class to store activity details with link
    *
    */
    public class ActivityDetails{
        @AuraEnabled
        public BrokerActivities__c activityDetail;
        @AuraEnabled
        public map<String,list<PublicLinkDetails>> relatedDocuments;
        public ActivityDetails(BrokerActivities__c activity,map<String,list<PublicLinkDetails>> docDetails){
            activityDetail = activity;
            relatedDocuments = docDetails;
        }   
    }

        /**
    * getActivityDocs
    *
    * This method used to return all the documents related to Event and Activities
    *
    * @param  none
    * @return map of id and document
    */
    public static map<id,list<Document__c>> getActivityDocs(set<id> accIds){
        map<id,list<Document__c>> activityMap = new map<id,list<Document__c>>();
        for(Document__c docRecord : [select id,DocumentType__c,Activity__c from Document__c where Activity__c in :accIds ]){
            if(!activityMap.containsKey(docRecord.Activity__c)){
                activityMap.put(docRecord.Activity__c,new list<Document__c>() );
            }
            activityMap.get(docRecord.Activity__c).add(docRecord);
        }
        return activityMap;
    }

    /**
    * getPublicDocumentURL
    *
    * This method used to return all the public link related to docs
    *
    * @param  none
    * @return list of ContentDistribution
    */
    public static list<ContentDistribution> getPublicDocumentURL(set<id> docIds){
        return [select id,RelatedRecordId,ContentDownloadUrl,DistributionPublicUrl,PdfDownloadUrl,ContentVersion.Title from ContentDistribution where RelatedRecordId in:docIds];
    }

    /**
    * PublicLinkDetails
    *
    * Warpper class to store the link details
    *
    */
    public class PublicLinkDetails{
        @AuraEnabled
        public string uid;
        @AuraEnabled
        public string name;
        @AuraEnabled
        public string link;
        public publicLinkDetails(ContentDistribution cdDetails){
            uid=cdDetails.Id;
            name=cdDetails.ContentVersion.Title;
            link=cdDetails.ContentDownloadUrl;
        }
    }
}