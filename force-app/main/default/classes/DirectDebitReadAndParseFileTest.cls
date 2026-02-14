@istest(SeeAllData=false)
public class DirectDebitReadAndParseFileTest {
	@istest
    public static void readContentVersionAndParseTest() {
        try{
            DDResponseFiles__c file = TestObjectsFactory.getDDResponseFile();
            file.Bank__c = 'Abu Dhabi Commercial Bank';
            file.Type__c = 'Registration AckNack';
            insert file;
            
            DDResponseFiles__c file2 = TestObjectsFactory.getDDResponseFile();
            file2.Bank__c = 'Abu Dhabi Commercial Bank';
            file2.Type__c = 'Registration AckNack';
            insert file2;
            
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            insert unit;
            unit = [select id, name from Unit__c where id=:unit.id];
            
            Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
            insert unit2;
            
            SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder1.Unit__c = unit.Id;
            insert salesOrder1;
            
            
            
            DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
            ddr.PayerAccount__c=acc.Id;
            insert ddr;
            
            DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
            ddt.TransactionStatus__c = 'Sent to Bank';
            ddt.RequestFileName__c = 'MAYAN';
            insert ddt;
            
            ContentVersion cv = TestObjectsFactory.getContentVersion();
            cv.VersionData = blob.valueof('25083, MAYAN,-B1,-1001 \n 25083 MAYAN-B1-1001  \n 25083, MAYAN-B1-1001,'+unit.Name+'-'+'DD-100133');
            insert cv;
            ContentDocumentLink cdl = TestObjectsFactory.insertContentDocumentLink(file.Id,cv.id);
            
            SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder2.Unit__c = unit2.Id;
            insert salesOrder2;
                        test.startTest();

            DirectDebitRequest__c ddr2 = TestObjectsFactory.createDirectDebitRecords(salesOrder2.id);
            ddr2.PayerAccount__c=acc.Id;
            insert ddr2;
            
            DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr2.id, 'Abu Dhabi Commercial Bank');
            ddt2.TransactionStatus__c = 'Sent to Bank';
            ddt2.RequestFileName__c = 'MAYAN';
            insert ddt2;
            
            ContentVersion cv2 = TestObjectsFactory.getContentVersion();
            cv2.VersionData = blob.valueof('25083, MAYAN,-B1,-1001 \n 25083 MAYAN-B1-1001  \n 25083, MAYAN-B1-1001,'+unit.Name+'-'+'DD-100133');
            cv2.Title=ddt2.RequestFileName__c+'.DDS.1234567898764.Res';
            insert cv2;
            ContentDocumentLink cdl2 = TestObjectsFactory.insertContentDocumentLink(file2.Id,cv2.id);
            
           
            ScheduleToReadAndParseDirectDebitFile s=new ScheduleToReadAndParseDirectDebitFile();
            String cronexpression = '0 0 0 ? * * *';
            System.schedule('Testing', cronexpression, s);
           // s.execute(null);
            test.stopTest();
        }Catch(System.UnexpectedException theException){
            
        }
    }
}