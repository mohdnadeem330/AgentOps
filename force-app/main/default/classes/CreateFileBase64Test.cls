@IsTest
public class CreateFileBase64Test {

    @IsTest
    static void testDecodeCreatesFile() {
        // 1. Create a test record to attach the file to
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        // 2. Create sample file data
        String fileContent = 'Hello World from Test';
        String base64Data = EncodingUtil.base64Encode(
            Blob.valueOf(fileContent)
        );

        // 3. Prepare Flow input
        CreateFileBase64.FlowInput input = new CreateFileBase64.FlowInput();
        input.base64Data = base64Data;
        input.recordId = orgAcc.Id;
        input.fileName = 'TestFile.txt';

        List<CreateFileBase64.FlowInput> inputs =
            new List<CreateFileBase64.FlowInput>{ input };

        // 4. Execute method under test
        Test.startTest();
        CreateFileBase64.decode(inputs);
        Test.stopTest();
    }
}