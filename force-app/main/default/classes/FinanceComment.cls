public class FinanceComment {
       @AuraEnabled(cacheable=false)
    public static void saveFinanceComment(Id recordID, String remarks)
    {
        String messageToReturn = Constants.SUCCESS_MESSAGE;
            list<SalesOrder__c> soRecord = [select id,FinanceComments__c from SalesOrder__c where id = :recordID ];
        if (!soRecord.isEmpty()) {
            User currentUser = Utilities.getLoggedInUserDetail();
          
             if(remarks!=null && remarks!='')
             {
                soRecord[0].FinanceComments__c=currentUser.Name +' ('+currentUser.Profile.Name+') '+System.now().format()+'\n ----- \n' +remarks +'\n\n'+ (soRecord[0].FinanceComments__c==null?'':soRecord[0].FinanceComments__c) ;
             }} 
  update soRecord;
        
    }
}