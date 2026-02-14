@isTest
public class ALD_CreateSRDocsForAgencyRegTest 
{
    @isTest
    public static void testMethod1() {
        Test.startTest();
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate('AgencyRegistration');
		SRTemplateDetailRecord1.Name = 'Agency Registration';
        insert SRTemplateDetailRecord1;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__SR_Template__c = SRTemplateDetailRecord1.Id;
        insert SR;
        
        ALD_CreateSRDocsForAgencyRegistration b = new ALD_CreateSRDocsForAgencyRegistration();
        Database.executeBatch(b);
        
        Test.stopTest();
    }
    
}