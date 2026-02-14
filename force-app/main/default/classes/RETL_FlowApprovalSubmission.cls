public with sharing class RETL_FlowApprovalSubmission {

    /**
     * Starts the RETL_Leasing_Committee_Approval_Submission flow
     * for all active users in a given Queue, excluding the current user.
     *
     * Can be called from a Flow.
     *
     * @param inputs List of FlowInput containing recordId and queueId
     */
    @InvocableMethod(label='Start Approval Flow from Queue' 
                     description='Start approval flow for all active users in a Queue except current user')
    public static void startApprovalFlow(List<FlowInput> inputs) {
        Id currentUserId = UserInfo.getUserId();

        for (FlowInput input : inputs) {

            // Validate required inputs
            if (input.recordId == null) {
                throw new IllegalArgumentException('Record Id cannot be null.');
            }
            if (input.queueId == null) {
                throw new IllegalArgumentException('Queue Id cannot be null.');
            }

            // Get all members of the queue
            List<GroupMember> members = [
                SELECT UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId = :input.queueId
            ];

            Set<Id> userIds = new Set<Id>();
            for (GroupMember gm : members) {
                // Exclude current user
                if (gm.UserOrGroupId != currentUserId) {
                    userIds.add(gm.UserOrGroupId);
                }
            }

            // Query only active users
            List<User> users = [
                SELECT Id, Username, Name
                FROM User
                WHERE Id IN :userIds
                  AND IsActive = TRUE
            ];

            // Start the flow for each user with try/catch
            for (User u : users) {
                try {
                    Map<String, Object> flowVariables = new Map<String, Object>{
                        'recordId' => input.recordId,
                        'UserName' => u.Username,
                        'submitter' => u.Id,
                        'submissionComments' => 'Approval submission via Queue'
                    };

                    Flow.Interview flowInterview = Flow.Interview.createInterview(
                        'RETL_Leasing_Committee_Approval_Submission',
                        flowVariables
                    );
                    flowInterview.start();

                    System.debug('Flow started for user ' + u.Name + ' with inputs: ' + flowVariables);
                } catch (Exception e) {
                    System.debug('Error starting flow for user ' + u.Name + ': ' + e.getMessage());
                    // Optionally: add custom logging or error handling here
                }
            }

            System.debug('Flow started for ' + users.size() + ' active users in the queue, excluding current user.');
        }
    }

    // Wrapper class for Flow input
    public class FlowInput {
        @InvocableVariable(required=true description='Record Id to submit for approval')
        public Id recordId;

        @InvocableVariable(required=true description='Queue Id whose active users will be submitted')
        public Id queueId;
    }
}