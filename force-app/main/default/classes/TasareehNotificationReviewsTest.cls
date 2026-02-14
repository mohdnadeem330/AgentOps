@isTest
public class TasareehNotificationReviewsTest {
    @isTest
    Public static void method1(){
        String empname='Nicanor Pasia';
        
         WorkflowTask__c w=new WorkflowTask__c();
        w.name='Review';
        w.Notification_Date__c=date.today();
        insert w;
        
        TasareehNotificationReviews tnr = new TasareehNotificationReviews();
        tnr.setempname(empname);
        tnr.setescalated('N');

        List<WorkflowTask__c> tasks = tnr.TasareehNotificationReviews();
    }
    
     @isTest
    Public static void method2(){
        String empname='Nicanor Pasia';
        
         WorkflowTask__c w=new WorkflowTask__c();
        w.name='Review';
        w.Escalated_On__c=date.today();
        insert w;
        
        TasareehNotificationReviews tnr = new TasareehNotificationReviews();
        tnr.getrecId();
        tnr.setrecId(w.Id);
        tnr.setempname(empname);
        tnr.getempname();
        tnr.setescalated('Y');
        tnr.getescalated();

        List<WorkflowTask__c> tasks = tnr.TasareehNotificationReviews();
    }

}