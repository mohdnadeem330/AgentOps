@isTest
private class ADCBAndADIBFileWrapperClassTest {

    @isTest
    static void testParse() {
        // Test JSON string
        String jsonString = '{"Data":{"RequestType":"Type1","BankReference":"Ref123","OICCode":"Code456","File":"SomeFile","FileName":"TestFile.txt"}}';
        
        // Call the parse method
        ADCBAndADIBFileWrapperClass parsedObject = ADCBAndADIBFileWrapperClass.parse(jsonString);

        // Verify if parsing is successful
        System.assertNotEquals(null, parsedObject, 'Parsing should not return null');
        System.assertNotEquals(null, parsedObject.Data, 'Parsed data should not be null');
        
        // Verify individual fields in the parsed data
        System.assertEquals('Type1', parsedObject.Data.RequestType, 'RequestType should match');
        System.assertEquals('Ref123', parsedObject.Data.BankReference, 'BankReference should match');
        System.assertEquals('Code456', parsedObject.Data.OICCode, 'OICCode should match');
        System.assertEquals('SomeFile', parsedObject.Data.File, 'File should match');
        System.assertEquals('TestFile.txt', parsedObject.Data.FileName, 'FileName should match');
    }

    @isTest
    static void testConstructor() {
        // Call the constructor
        ADCBAndADIBFileWrapperClass wrapperObj = new ADCBAndADIBFileWrapperClass();

        // Verify if the constructor initializes the inner class instance
        System.assertNotEquals(null, wrapperObj.Data, 'Inner class instance should not be null');
    }
}