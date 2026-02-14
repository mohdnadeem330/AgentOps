@isTest
public class reUsableSubStatusControllerTest {
    @isTest
    Public Static void method1(){
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.PassportNumber__pc = 'N6385378';
        newAccount.ResidentStatus__pc = 'Resident';
        newAccount.MaritalStatus__pc = 'Married';
        newAccount.EmploymentStatus__pc = 'Self Employed';
        newAccount.PersonEmail = 'test@aldar.com.invalid';
        newAccount.MobileCountryCode__pc = '971';
        newAccount.MobilePhone__pc = '9876543115';
        newAccount.Company__pc = 'XXXXX';
        newAccount.Position__pc = 'XXX';
        newAccount.CompanyAddress__pc = 'NA';
        newAccount.NoofYearswithCompany__pc = 10;
        newAccount.Industry = 'Agriculture';
        newAccount.AnnualIncome__pc = 1234567;
        newAccount.NationalIdNumber__pc = '784123456789012';
       newAccount.SourceofFunds__pc='Profit';
        insert newAccount;
        case c=new case();
        c.Type='GFA';
        c.Status='Assigned';
        c.AccountId=newAccount.Id;
        insert c;
        reUsableSubStatusController.getSubStatusValues(c.id);
        reUsableSubStatusController.getSobjectFieldInfo(c.id);
         list<Sub_Status_Object_Fields_Config__mdt> data = [SELECT Id, MasterLabel, Remarks_API_Name__c,Sub_Status_API_Name__c,Backup_Remarks_API_Name__c,Reject_Reason_Api_Name__c FROM Sub_Status_Object_Fields_Config__mdt WHERE MasterLabel ='Case'];
      c.DC_Sub_Status__c='Rejected';
        c.CaseComments__c='Test';
        update c;
            reUsableSubStatusController.updateSobjectRec(c,data);
    }

}