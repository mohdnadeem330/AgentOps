/**********************************************************************************************************************
* Name               : DashboardWitoutShareController                                                        
* Description        : Class to provide helper methods for the Dashboard. WITHOUT SHARING IS USED TO PROVIDE RANKING ACCESS OF OTHER ACCOUNTS
* Usage              : Agency Dashboard LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
//This code is executing in without sharing contect to provide relative ranking with respect to other Agencies 
//This also returns the public link for the document records
public without sharing class DashboardWitoutShareController{
    /**
    * getAccountRanking
    *
    * This method used to return all the accounts to sorted by ClassificationSalesAmount__c (used for ranking)
    *
    * @param  none
    * @return list of accounts sorted by ClassificationSalesAmount__c (used for ranking)
    */
    public static list<Account> getAccountRanking(){
        return [select id,Name,ClassificationSalesAmount__c,BrokerClassification__c,BrokerClassification__r.Name,BadgesTier__c from Account where recordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID WITH SECURITY_ENFORCED order by ClassificationSalesAmount__c desc nulls last, createdDate asc];
    }

    /**
    * getActivityDocs

    * This method used to return all the documents related to Event and Activities
    *
    * @param  activityIds
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
}