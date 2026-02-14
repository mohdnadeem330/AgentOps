@isTest
private class FLSCheckUtilTest {
    
    @isTest(SeeAllData=true)  
    static  void callMethods() {

        FLSCheckUtil.CheckQueryFieldAccess('Id,Name,createddate,lastmodifieddate,HexaBPM__Document_Description_External__c,HexaBPM__Is_Not_Required__c,'+
                                        +'HexaBPM__Document_Master__r.Name,HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.HexaBPM__Internal_Status_Name__c,'+
                                        +'HexaBPM__Service_Request__r.HexaBPM__External_Status_Name__c,HexaBPM__Doc_ID__c,'+
                                        +'HexaBPM__Customer_Comments__c,HexaBPM__Comments__c,HexaBPM__Document_Type__c,HexaBPM__Rejection_Reason__c,HexaBPM__Status__c', 'HexaBPM__SR_Doc__c');

        FLSCheckUtil.CheckQueryFieldAccess('id,ContactId', 'User');
        FLSCheckUtil.CheckQueryFieldAccess('id,Name', 'SR_Doc__c');

        FLSCheckUtil.fldFLS('Name', 'EmailTemplate');
        FLSCheckUtil.isUpdateable('FirstName,Id', 'Lead');

    }
}