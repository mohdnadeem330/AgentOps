@RestResource (urlMapping = '/query/pendingapprovals')
global without sharing class PendingApprovalQueryWebService {

    public static Map<Id,ProcessDefinition> processDefinitionMap ; 

    @HttpPost
    global static void getApprovals(String emailId) {   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            RestRequest request = RestContext.request;
            handler.notMobileRequest = true ;
            List<PendingApprovalProcess> pendingApprovals = getPendingApprovals(emailId);
            PendingApprovalQueryResponse response = new PendingApprovalQueryResponse(pendingApprovals, 'PendingApprovalProcess');
            
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

    /*
    * Pending Approval Query
    */
    public static List<PendingApprovalProcess> getPendingApprovals(String emailId){

        Set<Id> definitionIds = new Set<Id>();
        Map<Id,Id> processInstanceDefinitionMap = new Map<Id,Id>();
        List<PendingApprovalProcess> allPendingProcess = new List<PendingApprovalProcess>();
        Set<Id> submittedByIds = new Set<Id>();
        Map<String,Set<Id>> objectIdMap = new Map<String,Set<Id>>();

        //User userDetail = Utilities.getLoggedInUserDetail();
        //User userDetail = UserService.getUserDetailByEmail(emailId);
        User userDetail = [Select Id,Name,Email,ContactId from User where Email =: emailId and FederationIdentifier != null and isactive = True];

        List<ProcessInstance> pendingApprovals = [SELECT CompletedDate, CreatedById, CreatedDate,Id,IsDeleted,LastActorId,
        LastModifiedById,LastModifiedDate,ProcessDefinitionId,Status,SubmittedById
        ,SystemModstamp,TargetObjectId, (SELECT ID, ProcessNodeId, StepStatus,
        Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending,
        OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate 
        FROM StepsAndWorkitems WHERE ActorId =:userDetail.Id AND IsPending=true) FROM ProcessInstance WHERE Status = 'Pending'];
        System.debug('**pendingApprovals**'+pendingApprovals.size());
        List<ProcessInstance> pendingApprovalSteps = new List<ProcessInstance>();
        for(ProcessInstance processInstance : pendingApprovals){
            if(processInstance.StepsAndWorkitems.size()>0){
                definitionIds.add(processInstance.ProcessDefinitionId);
                processInstanceDefinitionMap.put(processInstance.Id,processInstance.ProcessDefinitionId);
                submittedByIds.add(processInstance.SubmittedById);
                pendingApprovalSteps.add(processInstance);
                //----- Get Target Object Details
                String sobjectType = processInstance.TargetObjectId.getSObjectType().getDescribe().getName();
                //objectIdMap.put(sobjectType, new Set<Id>())
            }   
        }
        System.debug('**definitionIds**'+definitionIds.size());
        if(pendingApprovalSteps!=null && !pendingApprovalSteps.isEmpty()){
            //----- Get Approval Process Definition Details
            processDefinitionMap = new Map<Id,ProcessDefinition>([SELECT CreatedById,CreatedDate,Description,DeveloperName,LastModifiedById,LastModifiedDate,LockType,Name,State,SystemModstamp,TableEnumOrId,Type,Id FROM ProcessDefinition WHERE Id IN:definitionIds]); 
            //----- Get Submitted By User Details
            Map<Id,User> userMap = new Map<Id,User>(UserService.getUsersById(submittedByIds));
            
            //----- Process Records
            for(ProcessInstance processInstance : pendingApprovalSteps){
                if(processInstance.StepsAndWorkitems[0]!=null){
                    allPendingProcess.add(new PendingApprovalProcess(processDefinitionMap.get(processInstance.ProcessDefinitionId).Name,processInstance.CreatedDate,userMap.get(processInstance.SubmittedById).Name,processInstance.StepsAndWorkitems[0].Id,processInstance.TargetObjectId,''));
                }
                
            }
        }
        
        return allPendingProcess ;
        
    }

    global class PendingApprovalProcess{

        public String approvalProcessName ;
        public DateTime submittedDateTime ;
        public String submittedBy ;
        public Id contextId ;
        public Id targetObjectId ;
        public String approvalSubject ;


        public PendingApprovalProcess(String approvalProcessName,DateTime submittedDateTime,String submittedBy,Id contextId,Id targetObjectId,String approvalSubject) {
            this.approvalProcessName = approvalProcessName ;
            this.submittedDateTime = submittedDateTime ;
            this.submittedBy = submittedBy; 
            this.contextId = contextId; 
            this.targetObjectId = targetObjectId;
            this.approvalSubject = approvalSubject ;  
        }
    }

    global with sharing class PendingApprovalQueryResponse extends QueryResponse {
        
        global PendingApprovalQueryResponse (List<PendingApprovalProcess> records, String objectName) {
            super(records, objectName);
        }

        global PendingApprovalQueryResponse () {
        }
    }

    

}