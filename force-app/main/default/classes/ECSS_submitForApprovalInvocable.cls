public class ECSS_submitForApprovalInvocable {
    
    @InvocableMethod
    public static void submitForApproval(List<invocableWrapper> invocableInputs){
        String objId = invocableInputs[0].objID;
        List<Id> ApproversIds = invocableInputs[0].ApproversIds;

    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
   for(Id id: ApproversIds) {
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        //req1.setComments('Approval for you');
        req1.setObjectId(objId);
        req1.setSkipEntryCriteria(true);
        req1.setNextApproverIds(new List<Id>{id});
    
        req1.setProcessDefinitionNameOrId('Approve_Converted_Opportunity_Creation');
        requests.add(req1);
    }
        
    List<Approval.ProcessResult> results = Approval.process(requests);
    System.debug(results);
    }
    
    public class invocableWrapper{
        @invocableVariable
        public String objID;
        @invocableVariable
        public List<Id> ApproversIds;
    }
}