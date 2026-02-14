public with sharing class ProjectDocumentUtility {

    
    /**
    * getProjectDetailsRecords
    *
    *  This method used to return all documents related to projectIds
    *
    * @param  projectIds project ids to retrive
    * @return ProjectDetails wapper
    */
    @AuraEnabled(cacheable=true)
    public static list<ProjectDetails> getProjectDetailsRecords(List<Id> projectIds, Boolean isResale){
        list<ProjectDetails> recordToReturn = new list<ProjectDetails>();

        list<Project__c> projects = [select id,Name,(select id,DocumentType__c from Documents__r) from Project__c where id in: projectIds ];

        if(!projects.isEmpty()){
            map<id,list<PublicLinkDetails>> docRelatedContentVersions = new map<id,list<PublicLinkDetails>>();

            for(Project__c tempProject : projects){
                // projectsMap.put(tempProject.Id ,tempProject);
                if(!tempProject.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempProject.Documents__r){
                        docRelatedContentVersions.put(tempDoc.Id ,new list<PublicLinkDetails>());
                    }
                }
            }

            if(isResale == null || !isResale){
            for(ContentDistribution dist : [select id,RelatedRecordId,ContentDownloadUrl,DistributionPublicUrl,PdfDownloadUrl,ContentVersion.Title from ContentDistribution where RelatedRecordId in:docRelatedContentVersions.keySet()] ){
                docRelatedContentVersions.get(dist.RelatedRecordId).add(new PublicLinkDetails(dist));
            }
            }else if(isResale != null && isResale){
                for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN: docRelatedContentVersions.keySet()]) {
                    docRelatedContentVersions.get(cdl.LinkedEntityId).add(new PublicLinkDetails(cdl));
                }
            }
            for(Project__c tempProject : projects){
                map<String,list<PublicLinkDetails>> docDetails = new map<String,list<PublicLinkDetails>>();
                if(!tempProject.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempProject.Documents__r){
                        if (docDetails.containsKey(tempDoc.DocumentType__c) && !docDetails.get(tempDoc.DocumentType__c).isEmpty() && !docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            list<PublicLinkDetails> tempList = docDetails.get(tempDoc.DocumentType__c);
                            tempList.addAll(docRelatedContentVersions.get(tempDoc.Id));
                            docDetails.put(tempDoc.DocumentType__c, tempList);
                        } else if (!docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            docDetails.put(tempDoc.DocumentType__c, docRelatedContentVersions.get(tempDoc.Id));
                        }
                    }
                }
                recordToReturn.add(new ProjectDetails(tempProject, docDetails) );
            }
        }

        return recordToReturn;
    }

    /**
    * ProjectDetails
    *
    * Wrapper class to store activity details with link
    *
    */
    public class ProjectDetails{
        @AuraEnabled
        public Project__c projectDetail;
        @AuraEnabled
        public map<String,list<PublicLinkDetails>> relatedDocuments;
        public ProjectDetails(Project__c project,map<String,list<PublicLinkDetails>> docDetails){
            projectDetail = project;
            relatedDocuments = docDetails;
        }   
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
        public publicLinkDetails(ContentDocumentLink cldDetails){
            uid=cldDetails.ContentDocument.LatestPublishedVersionId;
            name=cldDetails.ContentDocument.Title;
            // both the ways are working, but sees a bit of lag
            // link='https://aldarproperties--pruat.sandbox.file.force.com/sfc/servlet.shepherd/document/download/'+cldDetails.ContentDocumentId;
            link='/sfc/servlet.shepherd/version/download/'+cldDetails.ContentDocument.LatestPublishedVersionId;
        }
    }
}