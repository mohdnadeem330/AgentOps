public class UpdateContactsFilesBatch implements Database.Batchable<sObject> 
{
    public List<Contact> start(Database.BatchableContext bc)
    {
        List<Contact> conTotalList = [select id, Name, AccountName__c, FileUploadedCount__c, 
                                      (Select Id from ContentDocumentLinks)  
                                      from Contact 
                                      where RecordType.DeveloperName = 'BrokerAgent'  
                                      and AccountName__c != null];
        return conTotalList;
    }
    
    public void execute(Database.BatchableContext bc, List<Contact>  conList)
    {
        List<Contact> conToUpdate = new List<Contact>();
        for(Contact conRecord : conList)
        {
            conRecord.FileUploadedCount__c = conRecord.ContentDocumentLinks.size();
            conToUpdate.add(conRecord);
        }
		update conToUpdate;
        
    }
    public void finish(Database.BatchableContext bc)
    {
        System.debug('Batch finish -> ');
    }
    
}