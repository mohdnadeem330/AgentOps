public with sharing class ReceiptAcknowledgementService {

    public static List<ReceiptAcknowledgement__c> queryAllFieldsWithExtraFields(List<Id> raIds) {
        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(raFieldList);
        String fields = string.join(strList,',');

        Set<String> rallFieldList = Schema.getGlobalDescribe().get('ReceiptAllocation__c').getDescribe().fields.getMap().keySet();
        List<String> strRallList = new List<String>();
        
       // strRallList.addAll(rallFieldList);
      //  String rallFields = string.join(strRallList,',');

        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('ReceiptAllocation__c').getDescribe().fields.getMap();

        for(String s : objectFields.keySet()) {
            Schema.DescribeFieldResult lfieldLabel = objectFields.get(s).getDescribe();
            Schema.DisplayType dType = lfieldLabel.getType();
            string fieldType = String.ValueOf(dType);
            if(fieldType != 'TEXTAREA'){
             strRallList.add(string.valueOf(lfieldLabel.getName()));  
            }
        }
        String rallFields = string.join(strRallList,',');
        String raIdsStr = String.join(raIds, '\',\'');
        String query = 'SELECT ' + fields + ' , CreatedBy.Email,UnidentifiedReceiptProject__r.Name,UnidentifiedReceiptProject__r.AccountNumberCorporate__c,UnidentifiedReceiptProject__r.AccountNumberEscrow__c, Owner.Email, ChequeReceivedBy__r.Email, Account__r.Name, SalesOrder__r.Name,SalesOrder__r.Account__c,SalesOrder__r.Account__r.Name, SalesOrder__r.ERPID__c, SalesOrder__r.PaymentPlan__c, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name, ServiceRequest__r.ReceiptAcknowledgement__c, ServiceRequest__r.ReceiptAcknowledgement__r.ERPID__c,  SalesOrder__r.Status__c, (SELECT ' + rallFields + ' , SalesOrder__r.Status__c , SalesOrder__r.ERPID__c, InstallmentLine__r.InstallmentNumber__c, InstallmentLine__r.InstallmentAmount__c, InstallmentLine__r.InvoiceNumber__c, Account__r.Name, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name, SalesOrderOtherCharges__r.TypeOfCharge__c, SalesOrderOtherCharges__r.Amount__c,SalesOrderOtherCharges__r.InvoiceId__c  FROM Receipt_Allocations__r) FROM ReceiptAcknowledgement__c WHERE Id IN (\'' + raIdsStr + '\')';
        System.debug('***Receipt Acknowledgement query***'+query);
        List<ReceiptAcknowledgement__c> ReceiptAcknowledgements = Database.Query(query);
        System.debug('***Receipt Acknowledgement Queried***'+ReceiptAcknowledgements);
        return ReceiptAcknowledgements;
    }

    public static List<ReceiptAcknowledgement__c> getReceiptAcknowledgementById(Id ra) {
        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(raFieldList);
        String fields = string.join(strList,',');
        String extraFields = ', ServiceRequest__r.Recordtype.Name';

        String query = 'SELECT ' + fields + extraFields + ' FROM ReceiptAcknowledgement__c WHERE Id =\''+ra+'\'';
        System.debug('***Receipt Acknowledgement query***'+query);
        List<ReceiptAcknowledgement__c> ReceiptAcknowledgements = Database.Query(query);
        System.debug('***Receipt Acknowledgement Queried***'+ReceiptAcknowledgements);
        return ReceiptAcknowledgements;
    }
}