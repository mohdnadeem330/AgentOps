@isTest
public class ECSS_FieldsMetadataHelperTest {
    @isTest
    public static void testGetFieldSetFields()
    {
        String objectName = 'Account';
        String fieldSetName = 'ECSS_Person_Account_KYC_Verification';
        
        List<String> returnList = new List<String>();
        returnList = ECSS_FieldsMetadataHelper.getFieldSetFields(objectName,fieldSetName);
    }
    @isTest
    public static void testGetRecordData()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        String objectName = 'Account';
        String recordId = acc.Id;
        List<String> fieldsList = new List<String>{'Name'};
        Map<String,Object> returnMap = ECSS_FieldsMetadataHelper.getRecordData(objectName, recordId, fieldsList);
    }
}