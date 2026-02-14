public class ECSS_CheckIfRecordIsLocked {
    public class FlowInputs{
        @InvocableVariable
        public List<Id> recordIds;
    }
    @InvocableMethod (label = 'Check if Record Is Locked')
    public static List<Boolean> checkIfRecordIsLocked(List<FlowInputs> flowInput)
    {
        Boolean lockedStatus = false;
        
        for(FlowInputs input: flowInput){
            for(Id recId: input.recordIds)
            {
                if(Approval.isLocked(recId) && !lockedStatus){
                    lockedStatus = true;
                    break;
                }
                else
                {
                    continue;
                }
            }
        }
        List<Boolean> recordLockStatus = new List<Boolean>();
        recordLockStatus.add(lockedStatus);
        return recordLockStatus;
    }
}