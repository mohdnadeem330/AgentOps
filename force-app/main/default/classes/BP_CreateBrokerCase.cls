@RestResource(urlMapping = '/createBrokerCase')
global without sharing class BP_CreateBrokerCase extends BP_BaseRestResource {

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);

        Map<String, String> params = RestContext.request.params;
        String requestBody = RestContext.request.requestBody.toString();
        System.debug('Params: ' + params);
        System.debug('Request Body: ' + requestBody);

        BP_CreateBrokerCase service = new BP_CreateBrokerCase();
        ApiResponse response = service.processRequest(params, requestBody);

        handler.response.data = response.data;
        handler.response.success = response.success;
        handler.response.statusCode = response.statusCode;
        handler.response.message = response.message;

        System.debug('Response: ' + response);
        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        WrapperClass wrap = (WrapperClass) JSON.deserialize(requestBody, WrapperClass.class);
        
       // Scenario 1: Create a Case
if (wrap.caseRec != null) {
    return createCase(wrap);
} 

// Scenario 2: Add Comment to Case
else if (wrap.caseId != null && wrap.comment != null) {
    return addCommentToCase(wrap.caseId, wrap.comment);
} 

// Scenario 3: Add Files to Case
else if (wrap.caseId != null && wrap.filesToInsert != null) {
    return addFilesToCase(wrap.caseId, wrap.filesToInsert);
} 

        
        // Invalid request
        return new ApiResponse(false, 400, 'Invalid request. Provide either case details, comment, or files.', null);
    }

    // 1. Method to Create a Case
    private ApiResponse createCase(WrapperClass wrap) {
        List<Object> fileObjects = new List<Object>();
        if (wrap.filesToInsert != null) {
            for (FileToInsert file : wrap.filesToInsert) {
                fileObjects.add(file);
            }
        }

        Id accountId = wrap.accountId;
        Id contactId = wrap.contactId;

        // Call saveFiles method (returns List<Id>)
        List<Id> savedCaseIds = (List<Id>) ManageCasesController.saveFiles(fileObjects, (sObject)wrap.caseRec, wrap.comment, accountId, contactId);
        
        Id caseId = (savedCaseIds != null && !savedCaseIds.isEmpty()) ? savedCaseIds[0] : null;
        String caseNumber = null;

        // Query Case Number if caseId is available
        if (caseId != null) {
            try {
                Case queriedCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
                caseNumber = queriedCase.CaseNumber;
            } catch (Exception e) {
                System.debug('Error while fetching Case Number: ' + e.getMessage());
            }
        }

        // Response Data
        Map<String, Object> responseData = new Map<String, Object>();
        responseData.put('caseId', caseId);
        responseData.put('caseNumber', caseNumber);

        return new ApiResponse(true, 200, 'Case has been created successfully.', responseData);
    }

    // 2. Method to Add Comment to Case
    private ApiResponse addCommentToCase(Id caseId, String comment) {
        try {
            String commentId = CaseCommentsService.createnewComments(caseId, comment);
            return new ApiResponse(true, 200, 'Comment added successfully.', new Map<String, Object>{ 'commentId' => commentId });
        } catch (Exception e) {
            return new ApiResponse(false, 500, 'Error while adding comment: ' + e.getMessage(), null);
        }
    }

    // 3. Method to Add Files to Case
    private ApiResponse addFilesToCase(Id caseId, List<FileToInsert> filesToInsert) {
        try {
            List<Object> fileObjects = new List<Object>();
            for (FileToInsert file : filesToInsert) {
                fileObjects.add(file);
            }

            List<Id> fileIds = ManageCasesController.createFiles(fileObjects, caseId);
            return new ApiResponse(true, 200, 'Files added successfully.', new Map<String, Object>{ 'fileIds' => fileIds });
        } catch (Exception e) {
            return new ApiResponse(false, 500, 'Error while adding files: ' + e.getMessage(), null);
        }
    }

    public class WrapperClass {
        public Id caseId { get; set; }
        public Case caseRec { get; set; }
        public String comment { get; set; }
        public Id accountId { get; set; } 
        public Id contactId { get; set; } 
        public List<FileToInsert> filesToInsert { get; set; }
    }

    public class FileToInsert {
        public String title { get; set; }
        public String versionData { get; set; }
    }
}