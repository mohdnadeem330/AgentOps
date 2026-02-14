public class AdhocProformaInvoicesHandler extends TriggerHandler{
     public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) { 
        //newRecord.OutstandingAmountinwords__c
        for(Adhoc_Proforma_Invoices__c newRecord  : (list<Adhoc_Proforma_Invoices__c >) newList){
            if(newRecord.Amount__c  != null ){
                
                    newRecord.Amounts_in_Words__c = Utilities.amountInWords((newRecord.Amount__c),'Dhirams','Fils');
                }
            }
        }
    }