/**********************************************************************************************************************
* Name               : SendGridCalloutQueueable                                                        
* Description        : Queueable Class for the Payment Reminder Emails via SendGrid's REST API
* Created By         : Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridCalloutQueueable implements Queueable, Database.AllowsCallouts {

    //Map of Document Id and related Data Wrapper to be passed on to SendGrid Payment 
    private Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap;

    public SendGridCalloutQueueable(Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap) {
        this.requestWrapperMap = requestWrapperMap;
    }

    public void execute(QueueableContext context) {
        SendGridIntegrationHandler.doCallout(requestWrapperMap);
    }
}