/**
 * @description
 * Handles sending Cancel Proposal data from Salesforce Opportunity to Yardi via MuleSoft.
 * Constructs the Cancel Proposal payload, performs the HTTP callout,
 * and logs the response from MuleSoft/Yardi.
 *
 * Requires:
 * 1. MuleSoftSetting__mdt
 * 2. Utilities.getMuleSoftDetails()
 * 3. CalloutToMuleSoft.makeCallout()
 * 4. LoggerService.addApexServiceCalls()
 *
 * @author 
 * vkotaprolu@aldar.com
 *
 * @date 2025-11-27
 */
public with sharing class RETL_CancelProposalInYardi {

    public class CalloutException extends Exception {}

    // -----------------------------
    // Public Entry Point (@future)
    // -----------------------------

    @future(callout=true)
    public static void pushCancelProposal(Id oppId, String reason) {
        try {
            executeCancelProposal(oppId, reason);
        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'CancelProposalToYardi',
                    'RETL_CancelProposalInYardi',
                    'pushCancelProposal',
                    '',
                    'ERROR: ' + e.getMessage(),
                    oppId
                )
            );
        }
    }

    // -----------------------------
    // Core Logic
    // -----------------------------

    private static void executeCancelProposal(Id oppId, String reason) {        

        // MuleSoft Endpoint
        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_CancelProposalInYardi');
        if (api == null) throw new CalloutException('MuleSoft endpoint config not found.');
        String tableName = api.Table_Name__c != null ? api.Table_Name__c : 'AMENDBUT_PROPOSAL_STATUS';

        // Build Payload
        RETL_YardiCustomTableWrapper.CustomTableRequest payload  = buildCancelProposalPayload(oppId, reason, tableName);
        String requestBody = JSON.serialize(payload, false);

        // Make Callout
        HttpResponse res = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (res == null) throw new CalloutException('Null response from MuleSoft.');

        System.debug('Cancel Proposal Response: ' + res.getBody());

        // Check Status
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            // You may parse the success response here if required
        } 
        else {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'CancelProposalToYardi',
                    'RETL_CancelProposalInYardi',
                    'executeCancelProposal',
                    requestBody,
                    'ERROR: ' + res.getBody(),
                    oppId
                )
            );
        }
    }

    // -----------------------------
    // Build Payload
    // -----------------------------

    @TestVisible
    private static RETL_YardiCustomTableWrapper.CustomTableRequest 
        buildCancelProposalPayload(Id oppId, String reason, String tableName) {

        Opportunity opp = [
            SELECT Id, RETL_Yardi_Proposal_Id__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        // Generate requestId
        String requestId = UserInfo.getUserId() + '_' + oppId + '_' +
                        String.valueOf(Datetime.now().getTime());

        // Root Request
        RETL_YardiCustomTableWrapper.CustomTableRequest req = 
            new RETL_YardiCustomTableWrapper.CustomTableRequest();

        req.Description = 'Cancel Proposal for '+opp.RETL_Yardi_Proposal_Id__c;
        req.Timestamp   = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        req.RequestId   = requestId;

        // Table
        RETL_YardiCustomTableWrapper.TableWrapper tbl = 
            new RETL_YardiCustomTableWrapper.TableWrapper();
        tbl.TableName = tableName;
        tbl.Data = new List<RETL_YardiCustomTableWrapper.RecordWrapper>();

        // Record
        RETL_YardiCustomTableWrapper.RecordWrapper rec = 
            new RETL_YardiCustomTableWrapper.RecordWrapper();
        rec.EntityRecordCode = opp.RETL_Yardi_Proposal_Id__c;
        rec.CustomTableRecordCode = null;
        rec.Fields = new List<RETL_YardiCustomTableWrapper.FieldWrapper>{
            new RETL_YardiCustomTableWrapper.FieldWrapper('hCancelProposal', 'YES'),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Reason', reason)
        };

        tbl.Data.add(rec);
        req.Details = new List<RETL_YardiCustomTableWrapper.TableWrapper>{ tbl };

        return req;
    }

}