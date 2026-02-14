@isTest
private class EncryptionUtilsTest {


    @isTest static  void testMethods() {

        String stringToEncrypt = 'Test Encrypt String';

        Test.startTest();

        // Encrypt String
        String encryptedString = EncryptionUtils.encryptString(stringToEncrypt);
        // Decrypt String
        String decryptedString = EncryptionUtils.decryptString(encryptedString);
        EncryptionUtils.encryptFastTrackAccountId(new List<Id>{'0012500002MPZnzAAH'});
        Test.stopTest();

        system.assertEquals(decryptedString, stringToEncrypt,'stringToEncrypt != decryptedString');
    }
}