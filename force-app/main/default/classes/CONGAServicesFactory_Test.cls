@isTest
public class CONGAServicesFactory_Test{
    
    @testsetup
    public static void makeData(){
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerBankName__c = 'Test';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        insert acc;
        
        APXTConga4__Conga_Template__c temp = new APXTConga4__Conga_Template__c();
        temp.APXTConga4__Name__c = 'Account KYC Form';
        temp.APXTConga4__Template_Type__c = 'Document';
        temp.APXTConga4__Template_Group__c = 'Account KYC Form';
        insert temp;
        
        Document__c docRecord= new Document__c(Account__c = acc.Id, DocumentType__c = 'KYC Form');
        insert docRecord;
        
        
    }
    
    static testmethod void m1(){
        Document__c thisDoc = [Select id from Document__c limit 1];
        APXTConga4__Conga_Template__c temp = [Select id from APXTConga4__Conga_Template__c limit 1];
        thisDoc.Conga_Template__c = temp.Id;
        thisDoc.GenerateDocument__c = true;
        update thisDoc;
        
        List<CongaServicesFactory.RequestWrapper> requests = new List<CongaServicesFactory.RequestWrapper>();
        CongaServicesFactory.RequestWrapper req = new CongaServicesFactory.RequestWrapper();
        req.templateId = temp.Id;
        req.masterId = thisDoc.Id;
        req.outputFilename = 'Hello.pdf';
        requests.add(req);
        CongaServicesFactory.generateCongaDoc(requests);
        string correlationId = [Select id, Correlation_ID__c from Document__c limit 1].Correlation_ID__c;
        CongaServicesFactory.getStatusAndDownload(correlationId, thisDoc.Id);
    }
    
}