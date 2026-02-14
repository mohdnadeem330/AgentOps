/**
 * @description
 * Queueable class for sending Unit-level prospect data from Salesforce to Yardi via MuleSoft.
 * 
 * This class:
 *  - Builds the Yardi payload using Opportunity data.
 *  - Sends the request via MuleSoft (based on metadata configuration).
 *  - Parses Yardi response and updates Opportunity with Yardi record code.
 *  - Logs any failures using LoggerService.
 * 
 * @author 
 * vkotaprolu@aldar.com
 * @date 2025-11-06
 */
public with sharing class RETL_UnitSyncToYardiQueueable implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;

    // Constructor
    public RETL_UnitSyncToYardiQueueable(Id oppId) {
        this.opportunityId = oppId;
    }

    public void execute(QueueableContext context) {
        try {
            pushLeadUnitToYardi(opportunityId);
        } catch (Exception e) {
            System.debug('Error in RETL_UnitSyncToYardiQueueable: ' + e.getMessage());
        }
    }

    // --------------------------------------------------------------------------
    // Core Method - Push to Yardi
    // --------------------------------------------------------------------------
    private static void pushLeadUnitToYardi(Id oppId) {
        MuleSoftSetting__mdt api = MuleSoftSetting__mdt.getInstance('RETL_LeadUnitSyncToYardi');
        if (api == null) throw new CustomException('MuleSoft endpoint configuration not found.');

        String tableName = api.Table_Name__c != null ? api.Table_Name__c : 'COMMPROSPECTBUT_LEAD_CHRG';

        // Build payload using generic Yardi wrapper
        RETL_YardiCustomTableWrapper.CustomTableRequest payload = buildLeadUnitWrapper(oppId, tableName);

        System.debug('REQUEST BODY RAW: ' + payload);

        String requestBody = JSON.serialize(payload, false);
        System.debug('Yardi LeadUnit Request Body: ' + requestBody);

        HttpResponse response = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (response == null) throw new CustomException('No response received from Yardi endpoint.');

        System.debug('Response Code: ' + response.getStatusCode());
        System.debug('Response Body: ' + response.getBody());

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {

            RETL_YardiCustomTableWrapper.CustomTableResponse resWrapper =
                (RETL_YardiCustomTableWrapper.CustomTableResponse) JSON.deserialize(
                    response.getBody(),
                    RETL_YardiCustomTableWrapper.CustomTableResponse.class
                );

            if (resWrapper != null && resWrapper.Details != null && !resWrapper.Details.isEmpty()) {
                String customRecordCode = resWrapper.Details[0].CustomTableRecordCode;
                if (String.isNotBlank(customRecordCode)) {
                    Opportunity oppToUpdate = new Opportunity(
                        Id = oppId,
                        RETL_Lead_Financial_Yardi_Id__c = customRecordCode,
                        StageName = 'Submitted for Proposal'
                    );
                    update oppToUpdate;
                    System.debug('Updated Opportunity with Lead Financial Yardi ID: ' + customRecordCode);
                }
            }

        } else {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'LeadUnitSyncToYardi',
                    'RETL_UnitSyncToYardiQueueable',
                    'pushLeadUnitToYardi',
                    requestBody,
                    'Error: ' + response.getBody(),
                    oppId
                )
            );
        }
    }

    // --------------------------------------------------------------------------
    // Build Payload Using RETL_YardiCustomTableWrapper
    // --------------------------------------------------------------------------
    @TestVisible
    private static RETL_YardiCustomTableWrapper.CustomTableRequest buildLeadUnitWrapper(Id oppId, String tableName) {

        Opportunity opp = [
            SELECT Id, Name, CreatedDate, Description, RETL_Yardi_Id__c, RETL_Lead_Financial_Yardi_Id__c , 
                    RETL_Fitout_Days__c ,RETL_Deposit_Amount__c,RETL_TOR__c,RETL_FOC_Information__c,RETL_Special_Conditions__c,
                    RETL_Permitted_Usage__c,RETL_Deposit_Notes__c,RETL_General_Notes__c,RETL_Handover_Conditions__c,RETL_AM_PreApproval__c,
                    RETL_TOR_Notes__c,RETL_Configure_By__c,RETL_Escalation__c,RETL_Term_Start_Date__c,RETL_Term_End_Date__c,
                    RETL_Total_Base_Rent__c,RETL_Total_Marketing_Amount__c,RETL_Total_Service_Charge__c,RETL_Total_Rent_Free_Amount__c,RETL_Total_FOC_Amount__c,RETL_Billing_Frequency__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        // Calculate totals, assemble notes etc. (same logic as before)
        Decimal totalBRAmount = 0;
        Decimal totalMarketingAmount = 0;
        Decimal totalServiceChargeAmount = 0;
        Decimal totalRentFreeAmount = 0;
        Decimal totalFitoutContAmount = 0;
        List<String> rentNoteList = new List<String>();
        List<String> marketingNoteList = new List<String>();
        List<String> serviceChargeNoteList = new List<String>();
        Decimal totalSize = 0;
        Boolean isFlat = false;
        String separator = ';';

        for (OpportunityLineItem oli : [
            SELECT UnitPrice, PricebookEntry.Product2.ProductCode, RETL_Service_Charge__c,
                   RETL_Marketing_Amount__c, RETL_Rent_Free_Amount__c, RETL_Fitout_Contribution_Amount__c,
                   RETL_Selected_Unit__r.Unit_Area__c, RETL_Selected_Unit__r.Amount_Type__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
        ]) {
            String unitCode = oli.PricebookEntry.Product2.ProductCode;

            if (opp.RETL_Configure_By__c == 'Unit Level') {
                totalBRAmount += (oli.UnitPrice != null) ? oli.UnitPrice : 0;
                totalServiceChargeAmount += (oli.RETL_Service_Charge__c != null) ? oli.RETL_Service_Charge__c : 0;
                totalMarketingAmount += (oli.RETL_Marketing_Amount__c != null) ? oli.RETL_Marketing_Amount__c : 0;
                totalRentFreeAmount += (oli.RETL_Rent_Free_Amount__c != null) ? oli.RETL_Rent_Free_Amount__c : 0;
                totalFitoutContAmount += (oli.RETL_Fitout_Contribution_Amount__c != null) ? oli.RETL_Fitout_Contribution_Amount__c : 0;
            } else {
                totalBRAmount = opp.RETL_Total_Base_Rent__c;
                totalMarketingAmount = opp.RETL_Total_Marketing_Amount__c;
                totalServiceChargeAmount = opp.RETL_Total_Service_Charge__c;
                totalRentFreeAmount = opp.RETL_Total_Rent_Free_Amount__c;
                totalFitoutContAmount = opp.RETL_Total_FOC_Amount__c;
            }

            // Determine size
            String sizeStr = '';
            if (oli.RETL_Selected_Unit__r != null) {
                if (oli.RETL_Selected_Unit__r.Amount_Type__c == 'Flat Amount') {
                    sizeStr = 'flat';
                    isFlat = true;
                } else {
                    sizeStr = String.valueOf(oli.RETL_Selected_Unit__r.Unit_Area__c) + ' sqm';
                    totalSize += (oli.RETL_Selected_Unit__r.Unit_Area__c != null) ? oli.RETL_Selected_Unit__r.Unit_Area__c : 0;
                }
            }

            if (opp.RETL_Configure_By__c == 'Unit Level') {
                String formatted = unitCode + ' ' + separator + ' ' + sizeStr + ' ' + separator + ' ' +
                                   opp.RETL_Billing_Frequency__c + ' ' + separator + ' ' + String.valueOf(opp.RETL_Escalation__c) + '%';
                rentNoteList.add(formatted);
                marketingNoteList.add(formatted);
                serviceChargeNoteList.add(formatted);
            }
        }

        if (opp.RETL_Configure_By__c != 'Unit Level') {
            String sizeStrDeal = isFlat ? 'flat' : String.valueOf(totalSize) + ' sqm';
            String formattedDeal = sizeStrDeal + ' ' + separator + ' ' + opp.RETL_Billing_Frequency__c + ' ' + separator + 
                                   String.valueOf(opp.RETL_Escalation__c) + '%';
            rentNoteList.add(formattedDeal);
            marketingNoteList.add(formattedDeal);
            serviceChargeNoteList.add(formattedDeal);
        }

        String rentNotes = String.join(rentNoteList, ',');
        String marketingNotes = String.join(marketingNoteList, ',');
        String serviceChargeNotes = String.join(serviceChargeNoteList, ',');

        String userId = UserInfo.getUserId();
        Long unixTime = DateTime.now().getTime();
        String requestId = userId + '_' + oppId + '_' + String.valueOf(unixTime);

        // -----------------------------
        // Build Generic Payload
        // -----------------------------
        RETL_YardiCustomTableWrapper.CustomTableRequest wrapper = new RETL_YardiCustomTableWrapper.CustomTableRequest();
        wrapper.Description = 'Lead Financial Info for ' + opp.Name;
        wrapper.Timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        wrapper.RequestId = requestId;

        RETL_YardiCustomTableWrapper.TableWrapper table = new RETL_YardiCustomTableWrapper.TableWrapper();
        table.TableName = tableName;
        table.Data = new List<RETL_YardiCustomTableWrapper.RecordWrapper>();

        RETL_YardiCustomTableWrapper.RecordWrapper rec = new RETL_YardiCustomTableWrapper.RecordWrapper();
        rec.EntityRecordCode = opp.RETL_Yardi_Id__c;
        rec.Fields = new List<RETL_YardiCustomTableWrapper.FieldWrapper>{
            new RETL_YardiCustomTableWrapper.FieldWrapper('Fitout_days', opp.RETL_Fitout_Days__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('BRAmount', totalBRAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SCAmount', totalServiceChargeAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('MKAmount', totalMarketingAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Rent_Free', totalRentFreeAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('FOC_Amount', totalFitoutContAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Deposit', opp.RETL_Deposit_Amount__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('TOR', opp.RETL_TOR__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('FOC_Information', opp.RETL_FOC_Information__c != null ? opp.RETL_FOC_Information__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Special_condition', opp.RETL_Special_Conditions__c != null ? opp.RETL_Special_Conditions__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Permitted_Usage', opp.RETL_Permitted_Usage__c != null ? opp.RETL_Permitted_Usage__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Rent_Notes', rentNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SC_Notes', serviceChargeNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Marketing_Notes', marketingNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Deposit_Notes', opp.RETL_Deposit_Notes__c != null ? opp.RETL_Deposit_Notes__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('TOR_Notes', opp.RETL_TOR_Notes__c != null ? opp.RETL_TOR_Notes__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('General_Notes', opp.RETL_General_Notes__c != null ? opp.RETL_General_Notes__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('Handover_condition', opp.RETL_Handover_Conditions__c != null ? opp.RETL_Handover_Conditions__c : ''),
            new RETL_YardiCustomTableWrapper.FieldWrapper('AM_PREAPPROV', opp.RETL_AM_PreApproval__c == 'Approved' ? 'Approved' : 'Not Required'),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SF_LEAD_REF', opp.Id)
        };

        table.Data.add(rec);
        wrapper.Details = new List<RETL_YardiCustomTableWrapper.TableWrapper>{ table };

        return wrapper;
    }

    // --------------------------------------------------------------------------
    // Local Exception Class
    // --------------------------------------------------------------------------
    public class CustomException extends Exception {}
}