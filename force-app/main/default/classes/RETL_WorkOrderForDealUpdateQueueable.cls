/**
 * @description
 * Queueable class to send Work Order information for a Salesforce Opportunity
 * to Yardi via MuleSoft.
 *
 *
 * Main responsibilities:
 *  - Build the Work Order payload from Opportunity data.
 *  - Make the HTTP callout to MuleSoft endpoint.
 *  - Parse response from Yardi using a wrapper.
 *  - Update Opportunity with the returned Yardi Work Order Code.
 *  - Log errors for debugging or auditing.
 *
 * Author: vkotaprolu@aldar.com
 * Date: 2025-11-25
 */
public with sharing class RETL_WorkOrderForDealUpdateQueueable implements Queueable, Database.AllowsCallouts {

    private Id oppId;

    // Constructor
    public RETL_WorkOrderForDealUpdateQueueable(Id oppId) {
        this.oppId = oppId;
    }

    // Execute method
    public void execute(QueueableContext context) {
        try {
            executeWorkOrder(oppId);
        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'WorkOrderForDealUpdate',
                    'RETL_WorkOrderForDealUpdateQueueable',
                    'execute',
                    '',
                    'ERROR: ' + e.getMessage(),
                    oppId
                )
            );
        }
    }

    // Core callout logic
    private static void executeWorkOrder(Id oppId) {

        WorkOrderRequest payload = buildWorkOrderPayload(oppId);
        String requestBody = JSON.serialize(payload, false);

        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_WorkOrderForDealUpdate');
        if (api == null) throw new CalloutException('MuleSoft endpoint config not found.');

        HttpResponse res = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (res == null) throw new CalloutException('Null response from MuleSoft.');
        System.debug('Work Order Response: ' + res.getBody());

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            try {                
                WorkOrderResponse respWrapper = (WorkOrderResponse) JSON.deserialize(res.getBody(), WorkOrderResponse.class);

                if (respWrapper != null && respWrapper.Yardi_WO_Code != null) {
                    // Update Opportunity with Yardi WO Code
                    Opportunity oppToUpdate = new Opportunity(
                        Id = oppId,
                        RETL_WO_Yardi_Id__c = respWrapper.Yardi_WO_Code,
                        StageName = 'Submitted for Proposal'
                    );
                    update oppToUpdate;
                    System.debug('Updated Opportunity with Yardi WO Code: ' + respWrapper.Yardi_WO_Code);

                    // Chain DealUpdate Queueable
                    System.enqueueJob(new RETL_DealUpdateToYardiQueueable(oppId));
                }
            } catch (Exception e) {
                LoggerService.save(
                    LoggerService.addApexServiceCalls(
                        'WorkOrderForDealUpdate',
                        'RETL_WorkOrderForDealUpdateQueueable',
                        'executeWorkOrder',
                        requestBody,
                        'ERROR parsing response: ' + e.getMessage(),
                        oppId
                    )
                );
            }
        } else {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'WorkOrderForDealUpdate',
                    'RETL_WorkOrderForDealUpdateQueueable',
                    'executeWorkOrder',
                    requestBody,
                    'ERROR: ' + res.getBody(),
                    oppId
                )
            );
        }
    }

    @TestVisible
    private static WorkOrderRequest buildWorkOrderPayload(Id oppId) {

        Opportunity opp = [
            SELECT Id, Name, RETL_Tenant_Code__c, RETL_Project__r.RETL_Property_Yardi_Code__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        WorkOrderRequest req = new WorkOrderRequest();
        req.WorkOrder = new List<WorkOrderItem>();

        WorkOrderItem wo = new WorkOrderItem();
        wo.SF_Ref_WO_Id = opp.Id;
        wo.Tenant_Code = opp.RETL_Tenant_Code__c;
        wo.Property_Code = opp.RETL_Project__r.RETL_Property_Yardi_Code__c;
        wo.Unit_Code = '';
        wo.Template_Code = '';
        wo.WOStatus = 'In Progress';
        wo.WOCategory = 'Deal Updates';
        wo.SubCategory = 'Deal Updates';

        req.WorkOrder.add(wo);
        return req;
    }

    // -----------------------------
    // Payload Classes
    // -----------------------------
    public class WorkOrderRequest { 
        public List<WorkOrderItem> WorkOrder; 
    }

    public class WorkOrderItem {
        public String SF_Ref_WO_Id;
        public String Tenant_Code;
        public String Property_Code;
        public String Unit_Code;
        public String Template_Code;
        public String WOStatus;
        public String WOOrigin = '';
        public String WOCategory;
        public String SubCategory = '';
        public String WOPriority = '';
        public String Problem_Description = '';
        public String Brief_Description = '';
        public String Occupant_Code = '';
        public String Caller_Name = '';
        public String Caller_Number = '';
        public String Caller_Email = '';
        public String Related_WOID = '';
        public String Common_Area = '';
        public String ExtRef_Site_ID = '';
        public String WO_ExtRef_ID = '';
        public String userDefined1 = '';
        public String userDefined2 = '';
        public String userDefined3 = '';
        public String userDefined4 = '';
        public String userDefined5 = '';
        public String userDefined6 = '';
        public String userDefined7 = '';
        public String CustomField1 = '';
        public String CustomField2 = '';
        public String CustomField3 = '';
        public String AccessEntryNotes = '';
        public String FullDescription = '';
        public String TechnicianNotes = '';
    }

    // -----------------------------
    // Response Wrapper
    // -----------------------------
    public class WorkOrderResponse {
        public String Yardi_WO_Code;
        public String Status;
        public String ErrorMessage;
        public String SF_Ref_WO_Id;
    }

    public class CalloutException extends Exception {}

    // -----------------------------
    // Helper to enqueue
    // -----------------------------
    public static void enqueueJob(Id oppId) {
        System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(oppId));
    }
}