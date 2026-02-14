@isTest
private class ADCBAndADIBCollectionWrapperClassTest {

    @isTest
    static void testDataAndInstruction() {
        // Create test data
        String requestType = 'Type1';
        String customerReference = 'Ref1';
        String ddrReference = 'DDR123';
        String mandateReferenceNumber = 'Mandate123';
        String oicCode = 'OIC123';
        String originatorAccountNumber = 'Originator123';
        String iban = 'IBAN123';
        String dueDate = '2024-04-24';
        String amount = '100';
        //String currency = 'USD';

        // Create an instance of the ADCBAndADIBCollectionWrapperClass class
        ADCBAndADIBCollectionWrapperClass wrapper = new ADCBAndADIBCollectionWrapperClass();

        // Initialize the Data object if necessary
        if (wrapper.Data == null) {
            wrapper.Data = new ADCBAndADIBCollectionWrapperClass.Data();
            wrapper.Data.Instruction = new ADCBAndADIBCollectionWrapperClass.Instruction();
            wrapper.Data.Instruction.ClaimedAmount = new ADCBAndADIBCollectionWrapperClass.ClaimedAmount();
        }
        
        // Set values for Data object
        wrapper.Data.RequestType = requestType;
        wrapper.Data.CustomerReference = customerReference;
        wrapper.Data.DDRReference = ddrReference;
        wrapper.Data.MandateReferenceNumber = mandateReferenceNumber;
        // Set values for Instruction object
        wrapper.Data.Instruction.OICCode = oicCode;
        wrapper.Data.Instruction.OriginatorAccountNumber = originatorAccountNumber;
        wrapper.Data.Instruction.IBAN = iban;
        wrapper.Data.Instruction.DueDate = dueDate;
        // Set values for ClaimedAmount object
        wrapper.Data.Instruction.ClaimedAmount.Amount = amount;
        // Note: "Currency" cannot be set directly due to the reserved keyword, so we access it through "Currency_Z"
       // wrapper.Data.Instruction.ClaimedAmount.Currency_Z = currency;

        // Verify the values
        System.assertEquals(requestType, wrapper.Data.RequestType, 'RequestType should match');
        System.assertEquals(customerReference, wrapper.Data.CustomerReference, 'CustomerReference should match');
        System.assertEquals(ddrReference, wrapper.Data.DDRReference, 'DDRReference should match');
        System.assertEquals(mandateReferenceNumber, wrapper.Data.MandateReferenceNumber, 'MandateReferenceNumber should match');
        System.assertEquals(oicCode, wrapper.Data.Instruction.OICCode, 'OICCode should match');
        System.assertEquals(originatorAccountNumber, wrapper.Data.Instruction.OriginatorAccountNumber, 'OriginatorAccountNumber should match');
        System.assertEquals(iban, wrapper.Data.Instruction.IBAN, 'IBAN should match');
        System.assertEquals(dueDate, wrapper.Data.Instruction.DueDate, 'DueDate should match');
        System.assertEquals(amount, wrapper.Data.Instruction.ClaimedAmount.Amount, 'Amount should match');
        //System.assertEquals(currency, wrapper.Data.Instruction.ClaimedAmount.Currency_Z, 'Currency should match');
    }
}