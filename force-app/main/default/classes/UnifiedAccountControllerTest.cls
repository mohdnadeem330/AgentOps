/**
* @File Name : UnifiedAccountControllerTest.cls
* @Description :This apex class is used to code coverage of UnifiedAccountController.cls
* @Author : Rijwan Mohmmed
* @Last Modified By :Rijwan Mohmmed
* @Last Modified On : August 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 18, 2025 |   | Initial Version
**/
@isTest
public class UnifiedAccountControllerTest {
	@isTest
    public static void createLeadAsCCA (){
        List<String> projectLabelData = new List<String>();
        for (String item : label.LSQProject.split(',')) {
            projectLabelData.add(item.trim());
        }
        
        Lead leadReccord1 = TestObjectsFactory.getLeadRecord(3, 'Person');
        leadReccord1.LeadSource = 'Direct Call';
        leadReccord1.EnquiryCategory__c = 'Aldar Employees';
        leadReccord1.EnquiryTrigger__c = 'Provis';
        leadReccord1.CountryOfResidence__c = 'United Arab Emirates';
        leadReccord1.Lead_Type__c = 'AM Sale';
        //insert leadReccord1;
        
        Lead leadReccord2 = TestObjectsFactory.getLeadRecord(3, 'Person');
        leadReccord2.LeadSource = 'Direct Call';
        leadReccord2.EnquiryCategory__c = 'Aldar Employees';
        leadReccord2.EnquiryTrigger__c = 'Provis';
        leadReccord2.CountryOfResidence__c = 'United Arab Emirates';
        leadReccord2.Lead_Type__c = 'Logistics';
        //insert leadReccord2;
        
        Lead leadReccord3 = TestObjectsFactory.getLeadRecord(1, 'ECSS');
        leadReccord3.Project__c = projectLabelData[0];
        //insert leadReccord3;
        
        Test.startTest();
        Account acc = new Account();
        UnifiedAccountController.getCustomerVertical(acc, leadReccord1);
        UnifiedAccountController.getCustomerVertical(acc, leadReccord2);
        leadReccord2.Project__c = projectLabelData[0];
        UnifiedAccountController.getCustomerVertical(acc, leadReccord2);
        UnifiedAccountController.getCustomerVertical(acc, leadReccord3);
        Test.stopTest();
    }
}