public without sharing class CaseCommentsService {

    @AuraEnabled
    public static List<CaseComment> getCaseCommentsHistory(Id caseId){
        try {
          List<CaseComment> commentHist=[SELECT Id, ParentId,CreatedDate,CreatedBy.FirstName,CreatedBy.LastName, CommentBody FROM CaseComment where ParentId=:caseId];
          
          return commentHist;
        
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        } 
    
    }  

   
  
    @AuraEnabled
    public static String createnewComments(Id caseId, String comment){
        try {
            Case cs = [SELECT Id, Status FROM Case WHERE Id =: caseId];
            cs.Status = Constants.CASE_IN_PROGRESS;
            update cs;
            
          String cmtId;
          CaseComment cmt = new CaseComment();
          cmt.ParentId=caseId;
          cmt.CommentBody=comment;
          insert cmt;
          cmtId=cmt.Id;
          return cmtId;
        
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        } 
        
        
    }  

    @AuraEnabled
    public static ContentDistribution getAttachmentURL(Id csId, Id cvId){
  
        try {system.debug('#####################inside cntdist. cvId>>>>'+cvId+ 'csid>>'+csId);
            return [SELECT Id, DistributionPublicUrl, RelatedRecordId, ContentVersionId FROM ContentDistribution WHERE RelatedRecordId =: csId AND ContentVersionId =: cvId LIMIT 1];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}