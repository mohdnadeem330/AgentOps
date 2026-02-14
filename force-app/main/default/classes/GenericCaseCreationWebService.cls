@RestResource(urlMapping='/GenericCaseAPI')
global with sharing class GenericCaseCreationWebService {
    
    @HttpPost
    global static void createCase() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            // Parse JSON body into a Map1
            Map<String, Object> caseData = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            object responseData;
            
            
            if(caseData != null  && caseData.get('operation') != null){
                if(caseData != null  && caseData.get('operation') == 'create'){
                    responseData = createCase(caseData);
                }
                else if(caseData != null  && caseData.get('operation') == 'get'){
                    responseData =   getExistingCaseDetails(caseData);
                } 
                else if(caseData != null  && caseData.get('operation') == 'cancel'){
                    responseData =   cancelCase(caseData);
                }
                
                handler.response.data = responseData;
                handler.response.success = true;
                handler.finalize();
            }
            else{
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = '400 Bad Request - Missing parameter "operation"';
                handler.finalize();
            }
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            Logger__c lgs = LoggerService.createApexLog(ex,'GenericCaseCreationHandler','GenericCaseCreationWebService','CaseCreation');
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    public static GenericCaseCreationResponse cancelCase(Map<String, Object> caseData){
        
        GenericCaseCreationResponse genericCaseCreationResponse = new GenericCaseCreationResponse();
        
        if(caseData != null  && caseData.get('entityId') != null){
            
            String whereClause = '';
            whereClause += 'Id = \'' + caseData.get('entityId') + '\'';
            
            List<Case> caseList = returnCaseDetails(whereClause);
            Case existingCase = new Case();
            
            if(!caseList.isEmpty()){
                existingCase = caseList[0];
                existingCase.Status = 'Cancelled';
                Update existingCase;
            }
            
            
            return getCaseDetails(new List<Case>{existingCase});
        }
        
        return genericCaseCreationResponse;
    }
    
    public static GenericCaseCreationResponse createCase(Map<String, Object> caseDataInput){
        // Create a new Case record
        Case newCase = new Case();
        String RecTypeId ='';
        Map<String, Object> caseData = caseDataInput;
        Map<String, Object> caseDataHardCodeValue = Constants.CASE_TYPE_CATALOG.get(String.valueof(caseDataInput.get('Type')));
        
        if(System.Label.GeneralCaseType.split(';').contains(String.valueof(caseDataInput.get('Type')))){
            caseDataHardCodeValue.putAll(caseDataInput);
            caseData = caseDataHardCodeValue;
            String assetId = getAssetId((Id)caseData.get('Unit__c'));
            String salesOrderId = getSalesOrderId((Id)caseData.get('Unit__c'));
            If(caseData.get('Unit__c') != null && String.isNotBlank(assetId)){
                newCase.put('AssetId',assetId);
            }
            If(caseData.get('Unit__c') != null && String.isNotBlank(salesOrderId)){
                newCase.put('SalesOrder__c',salesOrderId);
            }
            
            If(caseData.get('CustomerType__c') != null  && caseData.get('CustomerType__c') == 'Tenant' && String.isNotBlank(assetId)){
                String contractId = getContractId(assetId);
                if(String.isNotBlank(contractId))
                    newCase.put('ECSS_Contract__c',contractId);
            }
            
        }
        
        // Dynamically set field values using the API names
        for (String fieldName : caseData.keySet()) {
            
                if(fieldName =='RecordTypeName'){
                    Object value = caseData.get(fieldName);
                    RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf(value)).getRecordTypeId();
                    newCase.put('RecordTypeId', RecTypeId);
                }
                
                else if (Schema.sObjectType.Case.fields.getMap().containsKey(fieldName)) {
                    // Only set valid fields
                    Object value = caseData.get(fieldName);
                    newCase.put(fieldName, value);
                }
        }
        
        system.debug('newCase-->'+newCase);
        
        insert newCase;
        
        return getCaseDetails(new List<Case>{newCase});
    }
    
    public static GenericCaseCreationResponse getExistingCaseDetails(Map<String, Object> caseData){
        
        GenericCaseCreationResponse genericCaseCreationResponse = new GenericCaseCreationResponse();
        String whereClause = '';
        
        if(caseData == null && caseData.get('AccountId') == null && caseData.get('Type') == null){
            return genericCaseCreationResponse;
        }  
        whereClause = 'AccountId = \'' + (string)caseData.get('AccountId') + '\' ' +
            'AND Type = \'' + (string)caseData.get('Type') + '\' ' +
            'AND Status NOT IN (\'Closed\', \'Cancelled\', \'Completed\')';
        
        List<Case> caseList = returnCaseDetails(whereClause);
        return getGenericCaseResponse(caseList); 
    }
    
    public static GenericCaseCreationResponse getCaseDetails(List<Case> newCase){
        
        String whereClause = '';
        List<Case> caseList = new List<Case>();
        
        if(!newCase.isEmpty() && newCase[0]?.Id != null){
            whereClause = 'Id = \'' + newCase[0]?.Id + '\' ';
            caseList = returnCaseDetails(whereClause);
        }
        
        return getGenericCaseResponse(caseList);
    }
    
    public static List<Case> returnCaseDetails(String whereClause){ 
        
        String query= 'SELECT Id,Status,(select id, CommentBody, CreatedDate, LastModifiedDate from CaseComments),CaseNumber,OwnerName__c,Owner.Name ,CaseComments__c ,Unit__c,Unit__r.Project__r.OA_Community_Name__c,Unit__r.BuildingSectionName__r.Precint_Name__c,LastModifiedDate,Unit__r.Name,Type,Description,CreatedDate,CommentsForCustomer__c';
        query += ' FROM Case ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query-->'+query);
        
        return Database.query(query); 
    }
    
    public static GenericCaseCreationResponse getGenericCaseResponse(List<Case> caseList){
        
        GenericCaseCreationResponse genericCaseCreationResponse = new GenericCaseCreationResponse();
        
        if (!caseList.isEmpty()) {
            
            genericCaseCreationResponse.caseId = caseList[0].Id;
            genericCaseCreationResponse.referenceNumber = getReferenceNumber(caseList[0]);
            genericCaseCreationResponse.description = caseList[0].Description;
            genericCaseCreationResponse.ownerName = caseList[0].Owner.Name ;
            genericCaseCreationResponse.status = caseList[0].status;
            genericCaseCreationResponse.createdDate = string.valueof(caseList[0].CreatedDate);
            genericCaseCreationResponse.caseNumber = caseList[0].CaseNumber;
            genericCaseCreationResponse.CaseComments = getCaseComments(caseList[0]);
            genericCaseCreationResponse.type = caseList[0].Type;
            genericCaseCreationResponse.commentsForCustomer = caseList[0].CommentsForCustomer__c;
            genericCaseCreationResponse.modifiedDate = string.valueof(caseList[0].LastModifiedDate);
            genericCaseCreationResponse.precinctName = caseList[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            genericCaseCreationResponse.unitName = caseList[0].Unit__r.Name;
            genericCaseCreationResponse.communityName = caseList[0].Unit__r.Project__r.OA_Community_Name__c;
            genericCaseCreationResponse.CommunityManager = getCommunityManagerNames(caseList[0].OwnerId);
        }
        
        return genericCaseCreationResponse;
    }
    
    public static List<CaseCommentBlock> getCaseComments (Case newCase){
        
        List<CaseCommentBlock> CaseComments = new List<CaseCommentBlock>();
        
        For(CaseComment  caseCommentBody : newCase.CaseComments){
            CaseCommentBlock currentCaseComment = new CaseCommentBlock();
            currentCaseComment.createdDate = string.valueof(caseCommentBody.CreatedDate);
            currentCaseComment.commentbody = caseCommentBody.CommentBody;
            CaseComments.add(currentCaseComment);
        }
        
        return caseComments;
    }
    
    public static list<string> getCommunityManagerNames (String ownerId){
        
        list<string> CommunityManagerNames= new list<string>();
        Set<Id> userIds = new Set<Id>();
        
        List<GroupMember> queueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :ownerId];
        
        for (GroupMember gm : queueMembers) {
            if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                userIds.add(gm.UserOrGroupId);
                system.debug('userIds::'+userIds);
            }
        }
        if(!userIds.isEmpty()){
            List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
            for (User u : users) {
                system.debug('Com Manager::'+u);
                CommunityManagerNames.add(u.Name);
            }
        }
        
        return CommunityManagerNames;
    }
    
    public static String getAssetId(Id unitId){
        
        List<Asset> assestList = [Select Id from Asset where Unit__c =:unitId limit 1];
        
        If(!assestList.isEmpty()){
            return assestList[0].Id;
        }
        
        return null;
    }
    
    public static String getSalesOrderId(Id unitId){
        
        List<SalesOrder__c> salesOrderList = [Select Id from SalesOrder__c where Unit__c =:unitId AND Status__c  NOT IN ('Cancelled','Cancelled By User') limit 1];
        
        If(!salesOrderList.isEmpty()){
            return salesOrderList[0].Id;
        }
        
        return null;
    }
    
    public static String getContractId(Id assetId){
        
       List<Unit_Contract__c> currentContactDetails = [Select Id,Contract__c,ECSS_Unit__c from Unit_Contract__c where Contract__r.ECSS_ContractOrganizationType__c = 'Tenancy' and Contract__r.EndDate > TODAY and ECSS_Unit__c  =:assetId];
        
        //List<Contract> contractList = [Select id from Contract where ECSS_ContractOrganizationType__c = 'Tenancy' And AccountId =: accountId and EndDate > TODAY];
        
        If(!currentContactDetails.isEmpty()){
            return currentContactDetails[0].Contract__c;
        }
        
        return null;
    }
    
    public static string getReferenceNumber (Case newCase){
        
        if(System.Label.GeneralCaseType.split(';').contains(newCase.Type)){
            return newCase.CaseNumber;
        }
        
        return '';
    }
    
    
    public class GenericCaseCreationResponse{
        public string caseId;
        public string referenceNumber;
        public string description;
        public string ownerName;
        public string status;
        public string createdDate;
        public string caseNumber;
        public string type;
        public string precinctName;
        public string unitName;
        public string communityName;
        public string commentsForCustomer;
        public string modifiedDate;
        public list<string> CommunityManager = new list<string>();
        public list<CaseCommentBlock> CaseComments = new list<CaseCommentBlock>();
    }
    
    public class CaseCommentBlock{
        public string createdDate;
        public string commentbody;
    }    
}