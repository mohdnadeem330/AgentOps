public class UpdateLastClearedReceiptBatch implements Database.Batchable<sObject>{
    
    public String query='';
    public UpdateLastClearedReceiptBatch () {
        this.query='Select Id,LastInstallment__c from HandoverDetails__c where LastInstallment__c !=null order by CreatedDate DESC';  
    }
    
    public UpdateLastClearedReceiptBatch (String dbQuery) {
       this.query= dbQuery;
    }
    
   public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** Start Method ****');
       // String query='Select Id,LastInstallment__c from HandoverDetails__c where LastInstallment__c !=null order by CreatedDate DESC';
        return Database.getQueryLocator(query);
   }
    
    
   public void execute(Database.BatchableContext bc, List<HandoverDetails__c> handoverDetails){
      Map<Id,InstallmentLines__c> installmentLineMap = new  Map<Id,InstallmentLines__c>();
       List<String> installmentLines=new List<String>();
       for(HandoverDetails__c hd:handoverDetails){
         installmentLines.add(hd.LastInstallment__c);
       }
       //AND PaymentInstallments__r.IsHandoverPayment__c =true
        System.debug('*** installmentLines ****'+installmentLines);   
        Map<Id, InstallmentLines__c> installmentReceiptAllocationMap=new Map<Id, InstallmentLines__c>([SELECT Id,(SELECT  
        InstallmentLine__c,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentType__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.Name FROM Receipt_Allocations__r  where ReceiptAcknowledgement__r.PaymentType__c!='Credit Note' and ReceiptAcknowledgement__r.ClearedDate__c!=null
        ORDER BY InstallmentLine__c,ReceiptAcknowledgement__r.ClearedDate__c DESC limit 1 ) from InstallmentLines__c where Id IN :installmentLines]);  
       for(String installmentId:installmentReceiptAllocationMap.keySet()){
           List<ReceiptAllocation__c> matchedReceiptList=installmentReceiptAllocationMap.get(installmentId).Receipt_Allocations__r;
          if(matchedReceiptList!=null && !matchedReceiptList.isEmpty()){
                InstallmentLines__c installmentLineRec = new InstallmentLines__c();
                installmentLineRec.Id = matchedReceiptList[0].InstallmentLine__c ;
                installmentLineRec.Last_Cleared_Receipt__c=matchedReceiptList[0].ReceiptAcknowledgement__c;
                installmentLineMap.put(installmentLineRec.Id, installmentLineRec); 
                System.debug('ReceiptAcknowledgement__r.Name'+matchedReceiptList[0].ReceiptAcknowledgement__r.Name);              
           }     
   }
       System.debug('*** installmentLineMap ***'+installmentLineMap.values());
       update installmentLineMap.values();
       System.debug('*** installmentLineMap Update ***'+installmentLineMap.values());

   }
    
   public void finish(Database.BatchableContext bc){
        
        
   } 

}