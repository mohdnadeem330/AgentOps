@isTest
public class SendGridProjectEmailControllerTest {
    
	@isTest
    public static void test(){
             Account testacc = new Account(Name = 'Test Account');
        insert testacc;
        
     
        List<SendGridProjectEmailController.FlowInputParamsWrapper> inputs = new List<SendGridProjectEmailController.FlowInputParamsWrapper>();
        SendGridProjectEmailController.FlowInputParamsWrapper input = new SendGridProjectEmailController.FlowInputParamsWrapper();
        input.ProjectName = 'Manarat Living II';
        input.EmailId = 'craiyani@aldar.com';
        input.customerName = 'Chirag Test';
        inputs.add(input);
        
        Test.startTest();

         SendGridProjectEmailController.flowNotification(inputs);
        Test.stopTest();
    }
}