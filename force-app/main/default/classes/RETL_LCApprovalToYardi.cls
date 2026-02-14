/**
 * @description
 * Handles sending LC Approval data from Salesforce Opportunity to Yardi via MuleSoft.
 * Constructs the LC Approval payload (using RETL_YardiCustomTableWrapper),
 * performs the callout, and logs any errors.
 *
 * Table name is dynamically loaded from MuleSoftSetting__mdt.Table_Name__c
 * with fallback = 'AMENDBUT_LC_APPROVAL'.
 */
public with sharing class RETL_LCApprovalToYardi {

    public class CalloutException extends Exception {}

    // -----------------------------
    // Public Entry Point (@future)
    // -----------------------------
    @future(callout=true)
    public static void pushLCApproval(Id oppId) {
        try {
            executeLCApproval(oppId);
        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'LCApprovalToYardi',
                    'RETL_LCApprovalToYardi',
                    'pushLCApproval',
                    '',
                    'ERROR: ' + e.getMessage(),
                    oppId
                )
            );
        }
    }

    // -----------------------------
    // Execute Callout
    // -----------------------------
    private static void executeLCApproval(Id oppId) {

        // Get MuleSoft endpoint settings
        MuleSoftSetting__mdt api =
            Utilities.getMuleSoftDetails('RETL_LCApprovalToYardi');

        if (api == null) {
            throw new CalloutException('MuleSoft endpoint config not found.');
        }

        // Determine table name
        String tableName = api.Table_Name__c != null
            ? api.Table_Name__c
            : 'AMENDBUT_LC_APPROVAL';

        // Build payload using unified Yardi wrapper
        RETL_YardiCustomTableWrapper.CustomTableRequest payload =
            buildLCApprovalPayload(oppId, tableName);

        String requestBody = JSON.serialize(payload, false);

        // Make the callout
        HttpResponse res = CalloutToMuleSoft.makeCallout(
            api.DeveloperName,
            requestBody
        );

        if (res == null) {
            throw new CalloutException('Null response from MuleSoft.');
        }

        System.debug('LC Approval Response: ' + res.getBody());

        // Log failed responses
        if (!(res.getStatusCode() >= 200 && res.getStatusCode() < 300)) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'LCApprovalToYardi',
                    'RETL_LCApprovalToYardi',
                    'executeLCApproval',
                    requestBody,
                    'ERROR: ' + res.getBody(),
                    oppId
                )
            );
        }
    }

    // -----------------------------
    // Build LC Approval Payload
    // -----------------------------
    @TestVisible
    private static RETL_YardiCustomTableWrapper.CustomTableRequest 
        buildLCApprovalPayload(Id oppId, String tableName) 
    {
        Opportunity opp = [
            SELECT Id, RETL_Yardi_Proposal_Id__c, Leasing_Committee_Approval_Status__c, RETL_LC_Notes__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        String lcStatus    = opp.Leasing_Committee_Approval_Status__c;
        String lcApproved  = (lcStatus == 'Approved') ? 'Yes' : 'No';
        // String lcNotes     = lcStatus;
        String lcNotes     = opp.RETL_LC_Notes__c;

        // Root request
        RETL_YardiCustomTableWrapper.CustomTableRequest req =
            new RETL_YardiCustomTableWrapper.CustomTableRequest();

        req.Description = 'LC Approval for ' + opp.RETL_Yardi_Proposal_Id__c;
        req.Timestamp   = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        req.RequestId   = UserInfo.getUserId() + '_' + oppId + '_' +
                          String.valueOf(Datetime.now().getTime());

        // Table wrapper
        RETL_YardiCustomTableWrapper.TableWrapper tbl =
            new RETL_YardiCustomTableWrapper.TableWrapper();

        tbl.TableName = tableName;
        tbl.Data = new List<RETL_YardiCustomTableWrapper.RecordWrapper>();

        // Record wrapper
        RETL_YardiCustomTableWrapper.RecordWrapper rec =
            new RETL_YardiCustomTableWrapper.RecordWrapper();

        rec.EntityRecordCode = opp.RETL_Yardi_Proposal_Id__c;
        rec.CustomTableRecordCode = null;

        // Fields
        rec.Fields = new List<RETL_YardiCustomTableWrapper.FieldWrapper>{
            new RETL_YardiCustomTableWrapper.FieldWrapper('LCAPPROV', lcStatus),
            new RETL_YardiCustomTableWrapper.FieldWrapper('LCAPPSTATUS', lcApproved),
            new RETL_YardiCustomTableWrapper.FieldWrapper('LCNOTES', lcNotes)
        };

        tbl.Data.add(rec);

        req.Details = new List<RETL_YardiCustomTableWrapper.TableWrapper>{ tbl };

        return req;
    }
}