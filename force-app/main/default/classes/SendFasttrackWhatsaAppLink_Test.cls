@isTest
public class SendFasttrackWhatsaAppLink_Test {
    @isTest
    static void testPositiveScenario() {
        
        Account testacc = new Account(Name = 'Test Account');
        insert testacc;
        
        List<SendFasttrackWhatsaAppLink.FlowInputs> inputs = new List<SendFasttrackWhatsaAppLink.FlowInputs>();
        SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
        input.category = 'FastTrack';
        input.accountId = testacc.Id;
        input.sourceType = 'Damascus';
        input.Project = 'Test Project';
        input.status = 'Fasttrack Completed';
        inputs.add(input);
        
        Test.startTest();
        List<SendFasttrackWhatsaAppLink.FlowOutputs> outputs = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        Test.stopTest();
    }
    @isTest
    static void testPositiveScenario2() {
        
        Account testacc = new Account(Name = 'Test Account');
        insert testacc;
        
        List<SendFasttrackWhatsaAppLink.FlowInputs> inputs = new List<SendFasttrackWhatsaAppLink.FlowInputs>();
        SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
        input.category = 'Booking';
        input.accountId = testacc.Id;
        input.sourceType = 'Broker Portal';
        input.Project = 'Test Project';
        input.status = 'Fasttrack Completed';
        inputs.add(input);
        
        Test.startTest();
        List<SendFasttrackWhatsaAppLink.FlowOutputs> outputs = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        Test.stopTest();
    }
    @isTest
    static void testNegativeScenario() {
        List<SendFasttrackWhatsaAppLink.FlowInputs> inputs = new List<SendFasttrackWhatsaAppLink.FlowInputs>();
        SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
        input.category = 'Test Category';
        input.accountId = 'AccountId';
        inputs.add(input);
        Test.startTest();
        List<SendFasttrackWhatsaAppLink.FlowOutputs> outputs = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        Test.stopTest();
    }
}