@RestResource (urlMapping = '/getBrokerCases')
global with sharing class BP_ManageBrokerCases extends BP_BaseRestResource{
    @HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
        try {
            String requestBody = RestContext.request.requestBody.toString();
            if (!String.isEmpty(requestBody)) {
                BP_ManageBrokerCases service = new BP_ManageBrokerCases();
                Map<String, String> params = RestContext.request.params;
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            } 
            
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        } 
        handler.finalize();
    }
global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
    try {
        Map<String, Object> requestBodyData = parseRequestBody(requestBody);
        String category  = (String) requestBodyData.get('category');
        String status    = (String) requestBodyData.get('status');
        String searchKey = (String) requestBodyData.get('searchKey');
    String caseNumber = (string) requestBodyData.get('caseNumber');
        Integer limits  = (Integer) requestBodyData.get('limits');
        Integer offsets = (Integer) requestBodyData.get('offsets');
        Boolean showcaseDocuments = (Boolean) requestBodyData.get('showcaseDocuments');

        return new ApiResponse(
            true, 
            200, 
            'Broker cases are fetched successfully', 
            new Map<String, Object>{
                 'caseList' => displayCaseRecords(category, status, searchKey, limits, offsets,showcaseDocuments,caseNumber),
                'totalRecordCount' => displayCaseRecords(category, status, searchKey, null, null,false,caseNumber).size()
           }
        );
    } catch (Exception e) {
        return new ApiResponse(false, 400, 'Failed to fetch broker cases: ' + e.getMessage(), null);
    }
}

@AuraEnabled
public static List<casewrapper> displayCaseRecords(String category, String status, String searchKey, Integer limits, Integer offsets,Boolean showcaseDocuments,string caseNumber) {
    List<String> conditions = new List<String>();
    List<casewrapper> wrapresponse = new List<casewrapper>();
    Set<Id> caseIds = new Set<Id>();

    Set<Id> conAccountIds = new Set<Id>();
    Set<Id> childAccountsId = new Set<Id>();
    Map<Id, Case> caseWithFiles = new Map<Id, Case>();
    List<Id> allCasesId = new List<Id>();
    List<Case> allCases = new List<Case>();
    User userInfo = Utilities.getLoggedInUserDetail();
    Id contactId = userInfo.ContactId;
    String loggedInUserProfile = userInfo.ProfileName__c; 
    Id conAccountId = ContactService.getAccountId(contactId);
    
    if (category != null) {
        conditions.add('Category__c= :category');
    }
    if (status != null) {
        conditions.add('Status= :status');
    }
   if (searchKey != null) {
    searchKey = '%' + searchKey + '%'; // Add wildcards for contains-like behavior
    conditions.add('Subject LIKE :searchKey');
}
      if (caseNumber != null) {
        caseNumber = '%' + caseNumber + '%'; // Add wildcards for contains-like behavior
        conditions.add('CaseNumber LIKE :caseNumber');
    }

    if (loggedInUserProfile == Constants.AGENCY_ADMIN_PROFILE || loggedInUserProfile == Constants.AGENCY_ADMIN_PROFILE_LOGIN) {
        Account accountRec = AccountService.fetchAccountById(conAccountId).isEmpty() ? null : AccountService.fetchAccountById(conAccountId)[0];
        Id parentAccountId = accountRec.ParentId;
        
        Map<Id, Account> parentAccountWithCases = new Map<Id, Account>(
            [SELECT ID, Name, (SELECT Id, Subject FROM Cases) FROM Account WHERE Id = :conAccountId]
        );
        
        if (parentAccountWithCases.size() > 0) {
            for (Account a : parentAccountWithCases.values()) {
                if (parentAccountWithCases.get(a.Id).Cases.size() > 0) {
                    allCases.addAll(parentAccountWithCases.get(a.Id).Cases);
                }
            } 
        }

        String caseQuery = getCaseQuery();
        caseQuery += ' WHERE (ID IN: allCases OR AccountId = :conAccountId OR Account.ParentId = :conAccountId)';
       
        if (conditions.size() > 0) {
            caseQuery += ' AND ' + String.join(conditions, ' AND ');
        }
        caseQuery += ' ORDER BY CreatedDate DESC';
        if (limits != null) {
            caseQuery += ' LIMIT :limits';
        }
        if (offsets != null) {
            caseQuery += ' OFFSET :offsets';
        }

        List<Case> caseWithFilesList = Database.query(caseQuery);
        caseWithFiles = new Map<Id, Case>(caseWithFilesList); 
    } else {
        String caseQuery = getCaseQuery();
        caseQuery += ' WHERE ContactId = :contactId';
        if (conditions.size() > 0) {
            caseQuery += ' AND ' + String.join(conditions, ' AND ');
        }
        caseQuery += ' ORDER BY CreatedDate DESC';
        if (limits != null) {
            caseQuery += ' LIMIT :limits';
        }
        if (offsets != null) {
            caseQuery += ' OFFSET :offsets';
        }

        List<Case> caseWithFilesList = Database.query(caseQuery);
        caseWithFiles = new Map<Id, Case>(caseWithFilesList); 
    }

    if (!caseWithFiles.isEmpty()) {
        for (Case ca : caseWithFiles.values()) {
            casewrapper wrap = new casewrapper(); 
            wrap.caseId = ca.Id;
            wrap.Attachment = (caseWithFiles.get(ca.Id).ContentDocumentLinks.size() > 0) ? 'Yes' : 'No'; 
            wrap.Category = ca.Category__c;
            wrap.ReferenceNumber = ca.CaseNumber;
            wrap.RequestedDate = (ca.CreatedDate).date();
            wrap.Status = ca.Status;
            wrap.Subject = ca.Subject;
            wrap.description = ca.Description;
            wrap.comments = ca.Comments;
             if (showcaseDocuments) {
                wrap.documents = fetchCaseDocuments(ca.Id);
            
            
     wrap.chatCommentHistory = CaseCommentsService.getCaseCommentsHistory(ca.Id);
             }
            wrapresponse.add(wrap);
        }
    }
    return wrapresponse;
}
  
public static List<DocumentWrapper> fetchCaseDocuments(Id caseId) { 
    List<DocumentWrapper> documentList = new List<DocumentWrapper>();

    // Fetch the latest ContentDocumentId linked to the Case
    List<ContentDocumentLink> cdlList = [
        SELECT ContentDocumentId 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :caseId
    ];
    
    if (!cdlList.isEmpty()) {
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        
        // Fetch the most recently created version of the document
        List<ContentVersion> cvList = [
            SELECT Id, Title, FileExtension, VersionData, CreatedDate 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!cvList.isEmpty()) {
            ContentVersion latestCV = cvList[0];
            DocumentWrapper docWrap = new DocumentWrapper();
            docWrap.title = latestCV.Title;
            docWrap.fileExtension = latestCV.FileExtension;
            docWrap.base64Data = EncodingUtil.base64Encode(latestCV.VersionData);
            documentList.add(docWrap);
        }
    }
    
    return documentList;
}



public class casewrapper {
    @AuraEnabled public String Attachment { get; set; }
    @AuraEnabled public Id caseId { get; set; } 
    @AuraEnabled public String Status { get; set; } 
    @AuraEnabled public String Category { get; set; } 
    @AuraEnabled public String Subject { get; set; } 
    @AuraEnabled public String CreatedByName { get; set; } 
    @AuraEnabled public String ReferenceNumber { get; set; } 
    @AuraEnabled public Date RequestedDate { get; set; }  
     @AuraEnabled public String description { get; set; } 
    @AuraEnabled public string comments { get; set; } 
     @AuraEnabled public List<DocumentWrapper> documents { get; set; }
      @AuraEnabled public List<CaseComment> chatCommentHistory { get; set; }
}
public class DocumentWrapper {
    @AuraEnabled public String title { get; set; }
    @AuraEnabled public String fileExtension { get; set; }
    @AuraEnabled public String base64Data { get; set; }
}
public static String getCaseQuery() {
    return 'SELECT Id, AccountId, CreatedDate, CaseNumber, Category__c,Description,CaseComments__c,Comments, Status, Subject, ' + 
           '(SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, ContentDocument.Title, ContentDocument.CreatedDate, ContentDocument.FileType ' + 
           'FROM ContentDocumentLinks) FROM Case';
}


}