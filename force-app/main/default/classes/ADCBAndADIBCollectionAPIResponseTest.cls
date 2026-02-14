@isTest
private class ADCBAndADIBCollectionAPIResponseTest {

    @isTest
    static void testConstructor() {
        // Create an instance of the ADCBAndADIBCollectionAPIResponse class
        ADCBAndADIBCollectionAPIResponse response = new ADCBAndADIBCollectionAPIResponse();

        // Verify that the Data and Errors objects are initialized
        System.assertNotEquals(null, response.Data, 'Data should not be null');
        System.assertEquals(0, response.Errors.size(), 'Errors list should be empty');
    }

    @isTest
    static void testDataAndError() {
        // Create test data
        String collectionBatchId = 'Batch123';
        String requestType = 'Type1';
        String customerReference = 'Ref1';
        String ddrReference = 'DDR123';
        String mandateReferenceNumber = 'Mandate123';
        String errorCode = 'Error123';
        String errorMessage = 'Error message';

        // Create an instance of the ADCBAndADIBCollectionAPIResponse class
        ADCBAndADIBCollectionAPIResponse response = new ADCBAndADIBCollectionAPIResponse();
        
        // Set values for Data object
        response.Data.CollectionBatchId = collectionBatchId;
        response.Data.RequestType = requestType;
        response.Data.CustomerReference = customerReference;
        response.Data.DDRReference = ddrReference;
        response.Data.MandateReferenceNumber = mandateReferenceNumber;

        // Add an error
        ADCBAndADIBCollectionAPIResponse.Error error = new ADCBAndADIBCollectionAPIResponse.Error();
        error.ErrorCode = errorCode;
        error.Message = errorMessage;
        response.Errors.add(error);

        // Verify the values
        System.assertEquals(collectionBatchId, response.Data.CollectionBatchId, 'CollectionBatchId should match');
        System.assertEquals(requestType, response.Data.RequestType, 'RequestType should match');
        System.assertEquals(customerReference, response.Data.CustomerReference, 'CustomerReference should match');
        System.assertEquals(ddrReference, response.Data.DDRReference, 'DDRReference should match');
        System.assertEquals(mandateReferenceNumber, response.Data.MandateReferenceNumber, 'MandateReferenceNumber should match');
        System.assertEquals(1, response.Errors.size(), 'Errors list should have one item');
        System.assertEquals(errorCode, response.Errors[0].ErrorCode, 'ErrorCode should match');
        System.assertEquals(errorMessage, response.Errors[0].Message, 'ErrorMessage should match');
    }
}