public class ECSS_Invocable_BusinessHours_Quote {

    @InvocableMethod
    public static void calculateBusinessHours (List<Input> inputList) {
        List<Quote> outputList = new List<Quote>();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name='SLA Business Hours'];
        for(Input currInp : inputList){
            datetime beforeDate = currInp.InputDate;
            Long NoHours = (Long)currInp.Hours;
            Quote currQuote = currInp.quoteInput;
            System.debug('bh:'+ bh.Id);
            Long range = ((Long) NoHours) * 60*60* 1000;
            datetime RealDate = BusinessHours.add(bh.id, beforeDate, range);
            System.debug('Range:'+range);
            System.debug('After:'+ RealDate);
            currQuote.ECSS_SLA_Date__c = RealDate;
            outputList.add(currQuote);
        }
        update outputList;
    }
    public class Input {
        @InvocableVariable(label='Hours' required=false)
        public Double Hours;
        @InvocableVariable(label='InputDate' required=false)
        public datetime InputDate;
        @InvocableVariable(label='QuoteRecord' required=false)
        public Quote quoteInput;

        
    }
}