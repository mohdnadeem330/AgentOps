@IsTest
public class Furniture_PaymentSplitDataWrapperTest {

    @IsTest
    static void testDeserializePaymentData_Success() {
        
        // Build mock JSON similar to Stripe API structure
        String mockJson = '{'+
            '"statusCode":200,'+
            '"statusMessage":"success",'+
            '"data":{'+
                '"id":"pay_123",'+
                '"amount_received":10500,'+        // AED 105.00
                '"currencyCode":"AED",'+
                '"created":1700000000,'+
                '"metadata":{'+
                    '"orderTransactionId":"ORD-123",'+
                    '"payerId":"PAYER1",'+
                    '"salesforceRequestId":"SFREQ1",'+
                    '"Remarks":"Test remarks",'+
                    '"splits":['+
                        '{'+
                            '"id":"split1",'+
                            '"amount":10500,'+
                            '"currencyCode":"AED",'+
                            '"completedAt":"2024-01-01",'+
                            '"metadata":{'+
                                '"netAmount":"10000",'+
                                '"totalFee":"300",'+
                                '"vatAmount":"200",'+
                                '"chargeType":"sale",'+
                                '"clientData":"Vendor"'+
                            '},'+
                            '"accountSearchFields":{"accountType":"vendor"},'+
                            '"clientData":{'+
                                '"trn":"12345",'+
                                '"marginPercent":70,'+
                                '"recipientName":"Vendor A",'+
                                '"accountType":"vendor"'+
                            '}'+
                        '}'+
                    ']'+
                '}'+
            '}'+
        '}';

        Test.startTest();
        Furniture_PaymentSplitDataWrapper.PaymentSplitData result =
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(mockJson);
        Test.stopTest();

    }


    @IsTest
    static void testDeserializePaymentData_MissingMetadata_ThrowsError() {
        
        String mockJson = '{ "statusCode":200, "statusMessage":"OK", "data":{} }';

        try {
            Test.startTest();
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(mockJson);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Failed to parse payment data'),
                          'Exception message mismatch');
        }
    }


    @IsTest
    static void testDeserializePaymentData_EmptyJson_ThrowsError() {

        String mockJson = '{}';

        try {
            Test.startTest();
            Furniture_PaymentSplitDataWrapper.deserializePaymentData(mockJson);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception for missing data');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Failed to parse payment data'),
                          'Exception message mismatch');
        }
    }
}