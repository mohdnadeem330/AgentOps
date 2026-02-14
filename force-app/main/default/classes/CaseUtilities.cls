public class CaseUtilities implements Queueable {
    private SalesOrder__c newRecord;
    
    public CaseUtilities(SalesOrder__c newRecord) {
        this.newRecord = newRecord;
    }
    
    public void execute(QueueableContext context) {
        
        try{
            Boolean isVIP = false;
            if(string.isNotBlank(newRecord.Account__c)){
                Account acc = [SELECT Id,CustomerType__c FROM Account WHERE Id =: newRecord.Account__c];
                isVIP = acc.CustomerType__c == 'VIP' ? true : false;
            }
            
            if(System.Label.Case_Creation_Active == 'True' && !isVIP || test.isRunningTest()){
                Case Cs  =new CAse ();
                Cs.CaseCategory__c = 'Customer Onboarding';
                Cs.Department__c = 'Customer Management';
                Cs.Organization__c = 'Development';
                //Cs.CaseComments__c= 'test';
                Cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Case').getRecordTypeId();
                Cs.SubVertical__c = System.Label.Case_SubVertical;
                
                Cs.Vertical__c= 'Customer Excellence';
                Cs.AccountId =newRecord.Account__c;
                Cs.SalesOrder__c = newRecord.Id;
                Cs.Unit__c=newRecord.Unit__c;
                Cs.Opportunity__c=newRecord.Opportunity__c;
                Cs.Origin = System.Label.Case_orgin;
                Cs.Subject = newRecord.Unit__c + Cs.CaseCategory__c;
                Insert Cs;
            }
        } catch(Exception e){
            System.debug('Create Case error'+ e.getMessage());
            LoggerService.save(LoggerService.addApexLog(e,'Caseutilities','Case Create',''));
        }   
    }
    
}