public class ECSS_Invocable_BusinessHours_Opp {
  @InvocableMethod
    public static void calculateBusinessHours (List<Input> inputList) {
        List<Opportunity> outputList = new List<Opportunity>();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name='SLA Business Hours'];
        for(Input currInp : inputList){
            datetime beforeDate = currInp.InputDate;
            Long NoHours = (Long)currInp.Hours;
            Opportunity currOpportunity = currInp.oppInput;
            System.debug('bh:'+ bh.Id);
            Long range = ((Long) NoHours) * 60 * 60 * 1000;
            datetime RealDate = BusinessHours.add(bh.id, beforeDate, range);
            System.debug('Range:'+range);
            System.debug('After:'+ RealDate);
            currOpportunity.ECSS_SLA_Date__c = RealDate;
            outputList.add(currOpportunity);
        }
        update outputList;
    }
    public class Input {
        @InvocableVariable(label='Hours' required=false)
        public Double Hours;
        @InvocableVariable(label='InputDate' required=false)
        public datetime InputDate;
        @InvocableVariable(label='OpportunityRecord' required=false)
        public Opportunity oppInput;

        
    }
}