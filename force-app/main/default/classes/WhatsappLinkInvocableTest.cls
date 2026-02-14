@isTest
public class WhatsappLinkInvocableTest {

    @isTest
    static void sendWhatsappMessage() {
        List<WhatsappLinkInvocable.FlowInputParamsWrapper> testInputList = new List<WhatsappLinkInvocable.FlowInputParamsWrapper>();
        testInputList.add(createFlowInputParamsWrapper('John Smith', 'NoyaLuma-N3-V-112', '917907632780', '7907632780', 'NOC'));

        Test.startTest();
        
      WhatsappLinkInvocable.flowWhatsApp(testInputList);
        
        Test.stopTest();

    }

    public static WhatsappLinkInvocable.FlowInputParamsWrapper createFlowInputParamsWrapper(String customerName, String projectName, String mobileNumber, String messageType, String attributeValue5) {
        WhatsappLinkInvocable.FlowInputParamsWrapper wrapper = new WhatsappLinkInvocable.FlowInputParamsWrapper();
        wrapper.CustomerName = customerName;
        wrapper.ProjectName = projectName;
        wrapper.MobileNumber = mobileNumber;
        wrapper.MessageType = messageType;
        wrapper.AttributeValue5 = attributeValue5;
        wrapper.AttributeName1 = 'UnitNo';
        wrapper.AttributeValue1 = 'Unit123';
        wrapper.AttributeName2 = 'Location';
        wrapper.AttributeValue2 = 'Dubai';
        wrapper.AttributeName3 = 'Status';
        wrapper.AttributeValue3 = 'Active';
        wrapper.AttributeName4 = 'Date';
        wrapper.AttributeValue4 = '2024-12-19';
        wrapper.HSMTemplateId = '91edc069-ff33-481a-8101-991a5a40995a';
        wrapper.SalesManager = 'John Doe';
        wrapper.LeadNumber = '123456';
        return wrapper;
    }
}