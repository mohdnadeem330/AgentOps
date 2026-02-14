public class ECSS_Invocable_BusinessHours {
    @InvocableMethod
    public static void calculateBusinessHours (List<Input> inputList) {
        List<Lead> outputList = new List<Lead>();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name='SLA Business Hours'];
        for(Input currInp : inputList){
            datetime beforeDate = currInp.InputDate;
            Long NoHours = (Long)currInp.Hours;
            Lead currLead = currInp.leadInput;
            System.debug('bh:'+ bh.Id);
            Long range = ((Long) NoHours) * 60 * 60 * 1000;
            datetime RealDate = BusinessHours.add(bh.id, beforeDate, range);
            System.debug('Range:'+range);
            System.debug('After:'+ RealDate);
            currLead.ECSS_SLA_Date__c = RealDate;
            outputList.add(currLead);
        }
        update outputList;
    }
    public class Input {
        @InvocableVariable(label='Hours' required=false)
        public Double Hours;
        @InvocableVariable(label='InputDate' required=false)
        public datetime InputDate;
        @InvocableVariable(label='LeadRecord' required=false)
        public Lead leadInput;

        
    }
    
    
}