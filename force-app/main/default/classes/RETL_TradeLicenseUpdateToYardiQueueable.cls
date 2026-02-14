/**
 * Queueable class to send Trade License Information for an Account
 * to Yardi Custom Table via MuleSoft.
 *
 * Responsibilities:
 *  - Build the custom table payload from Account fields.
 *  - Call MuleSoft endpoint with standardized integration pattern.
 *  - Parse Yardi custom table response.
 *  - Log success/errors.
 *
 * Author: vkotaprolu@aldar.com
 * Date: 2025-11-29
 */
public with sharing class RETL_TradeLicenseUpdateToYardiQueueable implements Queueable, Database.AllowsCallouts {

    private Id accountId;

    // Constructor
    public RETL_TradeLicenseUpdateToYardiQueueable(Id accountId) {
        this.accountId = accountId;
    }

    // Execute wrapper
    public void execute(QueueableContext context) {
        try {
            executeTradeLicenseUpdate(accountId);
        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'TradeLicenseUpdateToYardi',
                    'RETL_TradeLicenseUpdateToYardiQueueable',
                    'execute',
                    '',
                    'ERROR: ' + e.getMessage(),
                    accountId
                )
            );
        }
    }

    // --------------------------------------
    //  Core Callout Logic 
    // --------------------------------------
    private static void executeTradeLicenseUpdate(Id accountId) {

        

        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_TradeLicenseUpdateToYardi');
        if (api == null) throw new CalloutException('MuleSoft endpoint config not found.');
        String tableName = api.Table_Name__c != null ? api.Table_Name__c : 'CUSTBUT_ME_TLIC';

        RETL_YardiCustomTableWrapper.CustomTableRequest payload =
            buildPayload(accountId, tableName);

        String requestBody = JSON.serialize(payload, false);

        HttpResponse res = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (res == null) throw new CalloutException('Null response from MuleSoft.');

        System.debug('Trade License Response: ' + res.getBody());

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {

            try {

                RETL_YardiCustomTableWrapper.CustomTableResponse respWrapper =
                    (RETL_YardiCustomTableWrapper.CustomTableResponse)
                    JSON.deserialize(res.getBody(), RETL_YardiCustomTableWrapper.CustomTableResponse.class);

                System.debug('Parsed Response: ' + respWrapper);

            } catch (Exception e) {

                LoggerService.save(
                    LoggerService.addApexServiceCalls(
                        'TradeLicenseUpdateToYardi',
                        'RETL_TradeLicenseUpdateToYardiQueueable',
                        'executeTradeLicenseUpdate',
                        requestBody,
                        'ERROR parsing response: ' + e.getMessage(),
                        accountId
                    )
                );
            }

        } else {

            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'TradeLicenseUpdateToYardi',
                    'RETL_TradeLicenseUpdateToYardiQueueable',
                    'executeTradeLicenseUpdate',
                    requestBody,
                    'ERROR: ' + res.getBody(),
                    accountId
                )
            );
        }
    }

    // --------------------------------------
    // Payload Builder
    // --------------------------------------
    @TestVisible
    private static RETL_YardiCustomTableWrapper.CustomTableRequest buildPayload(Id accountId,string tableName) {

        Account acc = [
            SELECT Id, Name,
                   ECSS_Trade_License_Number__c,
                   Parent.RETL_Yardi_Id__c,
                   RETL_Trade_License_Issuing_Authority__c,
                   RETL_LicenseIssuedCity__c,
                   RETL_LicenseIssuedCityArabic__c,
                   RETL_Trade_License_Issue_Date__c,
                   RETL_Trade_License_Expiry_Date__C,
                   RETL_Status__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        RETL_YardiCustomTableWrapper.CustomTableRequest req =
            new RETL_YardiCustomTableWrapper.CustomTableRequest();

        req.Description = 'License Information Update for '+acc.Name;
        req.Timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        req.RequestId = acc.Id + '_' + UserInfo.getUserId()+ '_' + String.valueOf(Datetime.now().getTime());
        req.Details = new List<RETL_YardiCustomTableWrapper.TableWrapper>();

        RETL_YardiCustomTableWrapper.TableWrapper table =
            new RETL_YardiCustomTableWrapper.TableWrapper();
        table.TableName = tableName;
        table.Data = new List<RETL_YardiCustomTableWrapper.RecordWrapper>();

        RETL_YardiCustomTableWrapper.RecordWrapper rec =
            new RETL_YardiCustomTableWrapper.RecordWrapper();
        rec.EntityRecordCode = acc.Parent.RETL_Yardi_Id__c;
        rec.Fields = new List<RETL_YardiCustomTableWrapper.FieldWrapper>();

        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('LICENO', acc.ECSS_Trade_License_Number__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('DTIS', acc.RETL_Trade_License_Issue_Date__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('DTEXP', acc.RETL_Trade_License_Expiry_Date__C));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('STTS', acc.RETL_Status__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('Branchname', acc.RETL_Trade_License_Issuing_Authority__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('Licenseissuedcity', acc.RETL_LicenseIssuedCity__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('Licenseissuedcitya', acc.RETL_LicenseIssuedCityArabic__c));
        rec.Fields.add(new RETL_YardiCustomTableWrapper.FieldWrapper('Branchnamearabic', ''));

        table.Data.add(rec);
        req.Details.add(table);

        return req;
    }

    // --------------------------------------
    // Custom Exception
    // --------------------------------------
    public class CalloutException extends Exception {}

    // --------------------------------------
    // Flow-Invocable Enqueue Method
    // --------------------------------------
    @InvocableMethod(label='Send Trade License Update to Yardi')
    public static void enqueueJob(List<Id> accountIds) {
        for (Id accId : accountIds) {
            System.enqueueJob(new RETL_TradeLicenseUpdateToYardiQueueable(accId));
        }
    }

}