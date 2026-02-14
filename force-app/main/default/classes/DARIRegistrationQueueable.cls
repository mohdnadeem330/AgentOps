/**
* @description       : This class used for Queueable the integration.
* @coverage          : DARIRegistrationQueueableTest.cls | @CC100%
* @author            : rmohmmed@aldar.com
* @group             : Aldar
* @last modified on  : 02-12-2024
* @last modified by  : rmohmmed@aldar.com
* Modifications Log
* Ver   Date         Author                        Modification
* 1.0   02-12-2024   rmohmmed@aldar.com            Initial Version | Story Number | @CC100%
**/
public class DARIRegistrationQueueable implements Queueable, Database.AllowsCallouts {
    public String methodName;
    public String serviceRequestId;
    public DARIRegistrationQueueable(String methodName, Id serviceRequestId) {
        this.methodName = methodName;
        this.serviceRequestId = serviceRequestId;
    }
    
    public void execute(QueueableContext context) {
        if(methodName == 'createApplication') {
            DARIRegistrationUtility.createApplication(serviceRequestId);
        } else if(methodName == 'fetchApplication') {
            DARIRegistrationUtility.fetchApplication(serviceRequestId);
        } else if(methodName == 'postMortgageDetails') {
            DARIRegistrationUtility.postMortgageDetails(serviceRequestId);
        } else if(methodName == 'postPropertyDetails') {
            DARIRegistrationUtility.postPropertyDetails(serviceRequestId);
        } else if(methodName == 'postRegistrationFeeDetails') {
            DARIRegistrationUtility.postRegistrationFeeDetails(serviceRequestId);
        } else if(methodName == 'postUploadDocument') {
            HexaBPM__Service_Request__c srRecord = DARIRegistrationUtility.getSRRecord(serviceRequestId);
            DARIRegistrationUtility.postUploadDocument(serviceRequestId, srRecord.ApplicationId__c, new List<String>{'Mortgage Agreement'});
        } else if(methodName == 'submitApplication') {
            DARIRegistrationUtility.submitApplication(serviceRequestId);
        } else if(methodName == 'postDeveloperApproval') {
            DARIRegistrationUtility.postDeveloperApproval(serviceRequestId);
        } else if(methodName == 'cancellationApp') {
            DARIRegistrationUtility.cancellationApp(serviceRequestId);
        } else if(methodName == 'getPaymentBreakdown') {
            DARIRegistrationUtility.getPaymentBreakdown(serviceRequestId);
        } else if(methodName == 'dmtRegFeePayments') {
            DARIRegistrationUtility.dmtRegFeePayments(serviceRequestId);
        }
    }
}