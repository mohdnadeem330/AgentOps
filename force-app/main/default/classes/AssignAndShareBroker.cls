public with sharing class AssignAndShareBroker {
    
    @InvocableMethod(label='Assign Broker and Share Case')
    public static void assignAndShare(List<Request> requests) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Id> caseToUserMap = new Map<Id, Id>();
        
        for (Request req : requests) {
            caseIds.add(req.recordId);
            caseToUserMap.put(req.recordId, req.userId);
        }

        List<Case> casesToUpdate = [
            SELECT Id FROM Case WHERE Id IN :caseIds
        ];
        for (Case c : casesToUpdate) {
            c.Assigned_To__c = caseToUserMap.get(c.Id);
        }
        update casesToUpdate;

        List<CaseShare> shares = new List<CaseShare>();
        for (Id caseId : caseToUserMap.keySet()) {
            CaseShare cs = new CaseShare();
            cs.CaseId = caseId;
            cs.UserOrGroupId = caseToUserMap.get(caseId);
            cs.CaseAccessLevel = 'Edit';
            cs.RowCause = Schema.CaseShare.RowCause.Manual;
            shares.add(cs);
        }
        insert shares;
    }

    public class Request {
        @InvocableVariable(label='Record Id')
        public Id recordId;

        @InvocableVariable(label='User Id')
        public Id userId;
    }
}