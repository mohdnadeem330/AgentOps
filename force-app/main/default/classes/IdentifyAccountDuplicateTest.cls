@isTest
public class IdentifyAccountDuplicateTest {
    
    @isTest
    public static void testMethod1(){
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.PersonEmail = 'abc@gmail.com';
        acc1.MobilePhone__pc='92929';
        acc1.NationalIdNumber__pc = '121221';
        insert acc1;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.PersonEmail = 'abc@gmail.com';
        acc2.MobilePhone__pc='92929';
        acc2.NationalIdNumber__pc = '121221';
        insert acc2;
        test.startTest();
        database.executeBatch(new IdentifyAccountDuplicate(), 100);
        test.stopTest();
    }
}