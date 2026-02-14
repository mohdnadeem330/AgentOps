public with sharing class DeleteJointOwner {
    @AuraEnabled
    public static Boolean SubmitForDelete(Id recordId) {
        try {
            // Create a new approval request
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(recordId);
            req.setComments('Submitted for approval via Quick Action in LWC');
            req.setSubmitterId(UserInfo.getUserId());

            // Submit the approval request
            Approval.ProcessResult result = Approval.process(req);

            // Check if submission was successful
            if (result.isSuccess()) {
                return true;
            } else {
                throw new CustomException('Approval process failed');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
}