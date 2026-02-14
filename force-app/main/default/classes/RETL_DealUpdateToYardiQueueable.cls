/**
 * @description
 * Queueable class to send Deal Financial Information from Salesforce Opportunity
 * to Yardi via MuleSoft.
 *
 *  *
 * Main responsibilities:
 *  - Build the payload from Opportunity and related line items.
 *  - Make the HTTP callout to MuleSoft endpoint.
 *  - Parse response from Yardi.
 *  - Update Opportunity or log errors as needed.
 *
 * @author 
 * vkotaprolu@aldar.com
 * @date 2025-11-25
 */
public with sharing class RETL_DealUpdateToYardiQueueable implements Queueable, Database.AllowsCallouts {

    private Id oppId;

    // Constructor
    public RETL_DealUpdateToYardiQueueable(Id oppId) {
        this.oppId = oppId;
    }

    // Execute method for Queueable
    public void execute(QueueableContext context) {
        try {
            executeDealUpdate(oppId);
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexServiceCalls('DealUpdateToYardi','RETL_DealUpdateToYardiQueueable','execute','','ERROR: ' + e.getMessage(),oppId));
        }
    }

    // Core callout logic
    private static void executeDealUpdate(Id oppId) {

        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_DealUpdateToYardi');
        if (api == null) throw new CalloutException('MuleSoft endpoint config not found.');
        String tableName = api.Table_Name__c != null ? api.Table_Name__c : 'WOBUT_LEAD_CHRG';

        RETL_YardiCustomTableWrapper.CustomTableRequest payload = buildDealPayload(oppId,tableName);
        String requestBody = JSON.serialize(payload, false);

        
        HttpResponse res = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (res == null) throw new CalloutException('Null response from MuleSoft.');
        System.debug('Yardi Deal Update Response: ' + res.getBody());

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            RETL_YardiCustomTableWrapper.CustomTableResponse parsed = 
                (RETL_YardiCustomTableWrapper.CustomTableResponse) JSON.deserialize(
                    res.getBody(), 
                    RETL_YardiCustomTableWrapper.CustomTableResponse.class
                );
            return;
        }
        else{
            LoggerService.save(LoggerService.addApexServiceCalls('DealUpdateToYardi','RETL_DealUpdateToYardiQueueable','executeDealUpdate', requestBody,'ERROR: ' + res.getBody(),oppId));
        }
    }

    @TestVisible
    private static RETL_YardiCustomTableWrapper.CustomTableRequest buildDealPayload(Id oppId, string tableName) {

        Opportunity opp = [
            SELECT Id, Name, RETL_Yardi_Id__c, RETL_WO_Yardi_Id__c,
                   RETL_Total_Base_Rent__c, RETL_Total_Marketing_Amount__c,
                   RETL_Total_Service_Charge__c, RETL_Total_Rent_Free_Amount__c,
                   RETL_Total_FOC_Amount__c, RETL_Deposit_Amount__c, RETL_TOR__c,
                   RETL_Fitout_Days__c, RETL_Special_Conditions__c, RETL_Permitted_Usage__c,
                   RETL_General_Notes__c, RETL_Handover_Conditions__c, RETL_FOC_Information__c,
                   RETL_AM_PreApproval__c, RETL_TOR_Notes__c, RETL_Deposit_Notes__c,
                   RETL_Configure_By__c, RETL_Escalation__c, RETL_Billing_Frequency__c,
                   RETL_Term_Start_Date__c, RETL_Term_End_Date__c,RETL_Work_Order_Notes__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

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
        string propertyCode;
        List<String> unitCodes = new List<String>();
        for (OpportunityLineItem oli : [
            SELECT UnitPrice, PricebookEntry.Product2.ProductCode,
                   RETL_Service_Charge__c, RETL_Marketing_Amount__c, RETL_Rent_Free_Amount__c,
                   RETL_Fitout_Contribution_Amount__c, RETL_Selected_Unit__r.Unit_Area__c,
                   RETL_Selected_Unit__r.Amount_Type__c,RETL_Selected_Unit__r.Property_Code__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
        ]) {

            String unitCode = oli.PricebookEntry.Product2.ProductCode;
            propertyCode = oli.RETL_Selected_Unit__r.Property_Code__c;
            unitCodes.add(unitCode);

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
            String formattedDeal = sizeStrDeal + ' ' + separator + ' ' + opp.RETL_Billing_Frequency__c + ' ' +
                                   separator + ' ' + String.valueOf(opp.RETL_Escalation__c) + '%';
            rentNoteList.add(formattedDeal);
            marketingNoteList.add(formattedDeal);
            serviceChargeNoteList.add(formattedDeal);
        }
        String unitsString = String.join(unitCodes, ',');
        String rentNotes = String.join(rentNoteList, ',');
        String marketingNotes = String.join(marketingNoteList, ',');
        String serviceChargeNotes = String.join(serviceChargeNoteList, ',');

        String requestId = UserInfo.getUserId() + '_' + oppId + '_' + String.valueOf(Datetime.now().getTime());

        RETL_YardiCustomTableWrapper.CustomTableRequest req = new RETL_YardiCustomTableWrapper.CustomTableRequest();
        req.Timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        req.RequestId = requestId;
        req.Description = 'Lead Financial Info Update';
        req.Reserve1 = ''; req.Reserve2 = ''; req.Reserve3 = ''; req.Reserve4 = ''; req.Reserve5 = '';

        RETL_YardiCustomTableWrapper.TableWrapper tbl = new RETL_YardiCustomTableWrapper.TableWrapper();
        tbl.TableName = tableName; //'WOBUT_LEAD_CHRG';
        tbl.Data = new List<RETL_YardiCustomTableWrapper.RecordWrapper>();

        RETL_YardiCustomTableWrapper.RecordWrapper d = new RETL_YardiCustomTableWrapper.RecordWrapper();
        d.EntityRecordCode = opp.RETL_WO_Yardi_Id__c;
        d.CustomTableRecordCode = '';
        d.Fields = new List<RETL_YardiCustomTableWrapper.FieldWrapper>{
            new RETL_YardiCustomTableWrapper.FieldWrapper('BRAMOUNT', totalBRAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SCAMOUNT', totalServiceChargeAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('MKAMOUNT', totalMarketingAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('RENT_FREE', totalRentFreeAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('FOC_AMOUNT', totalFitoutContAmount),
            new RETL_YardiCustomTableWrapper.FieldWrapper('DEPOSIT', opp.RETL_Deposit_Amount__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('TOR', opp.RETL_TOR__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('FITOUT_DAYS', opp.RETL_Fitout_Days__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SPECIAL_CONDITION', opp.RETL_Special_Conditions__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('PERMITTED_USAGE', opp.RETL_Permitted_Usage__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('RENT_NOTES', rentNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SC_NOTES', serviceChargeNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('MARKETING_NOTES', marketingNotes),
            new RETL_YardiCustomTableWrapper.FieldWrapper('DEPOSIT_NOTES', opp.RETL_Deposit_Notes__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('TOR_NOTES', opp.RETL_TOR_Notes__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('GENERAL_NOTES', opp.RETL_General_Notes__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('HANDOVER_CONDITION', opp.RETL_Handover_Conditions__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('AM_PREAPPROV', opp.RETL_AM_PreApproval__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('SF_LEAD_REF', opp.Id),
            new RETL_YardiCustomTableWrapper.FieldWrapper('UNITCODE', unitsString),
            new RETL_YardiCustomTableWrapper.FieldWrapper('PROPERTYCODE', propertyCode),
            new RETL_YardiCustomTableWrapper.FieldWrapper('sNOTES', opp.RETL_Work_Order_Notes__c),
            new RETL_YardiCustomTableWrapper.FieldWrapper('DTLEASEEND', formatDateAsYardiString(opp.RETL_Term_End_Date__c)),
            new RETL_YardiCustomTableWrapper.FieldWrapper('DTLEASESTART', formatDateAsYardiString(opp.RETL_Term_Start_Date__c)),
            new RETL_YardiCustomTableWrapper.FieldWrapper('FOC_INFORMATION', opp.RETL_FOC_Information__c)
        };

        tbl.Data.add(d);
        req.Details = new List<RETL_YardiCustomTableWrapper.TableWrapper>{tbl};

        return req;
    }

    public static String formatDateAsYardiString(Date d) {
        if (d == null) return null;
        Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        return dt.formatGMT('yyyy-MM-dd');
    }

    public class CalloutException extends Exception {}

    public static void enqueueJob(Id oppId) {
        System.enqueueJob(new RETL_DealUpdateToYardiQueueable(oppId));
    }
}