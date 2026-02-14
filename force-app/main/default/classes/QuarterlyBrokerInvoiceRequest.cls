/**********************************************************************************************************************
* Name               : QuarterlyBrokerInvoiceRequest                                                       
* Description        : Controller to generate the request for ERP API for Quarter Commission
* Usage              : ERP Mulesoft Integration                                               
* Created By         : Sanket Kumar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           sajkumar@aldar.com      10 April 2023   Initial Draft       
******************************************************************************************************************/
public class QuarterlyBrokerInvoiceRequest {
    public static string generateJSONContent(Id recordId) {
        // Create a JSONGenerator object.
        // Pass true to the constructor for pretty print formatting.
        
        Map<Id, Map<String, String>> publicIdURLMap   = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> newMap           = new Map<Id, Map<String, String>>();
        List<Id> relatedIds                           = new List<Id>();
        Map<Id, Id> invoiceBundleDocMap               = new Map<Id, Id>();
        
        JSONGenerator gen = JSON.createGenerator(true);
        
        QuarterlyBrokerRequestPayload request = new QuarterlyBrokerRequestPayload();
        
        QuarterlyBonusCommission__c  quarterRecord = [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
                                                      LastActivityDate, Approval_Status__c, BrokerAgency__c, CommentTrail__c, Comments__c, Quarter__c, Status__c, Year__c, 
                                                      (SELECT Id, Name, BrokerAgency__c, BrokerAgency__r.name,BrokerAgency__r.Broker_Classification_Formula__c,CommissionAmount__c,Unit__c, 
                                                       Unit__r.name, SalesOrder__c, SalesOrder__r.name, OrderDate__c, CommissionPercentage__c, NetAmount__c, Unit__r.BuildingSectionName__c, 
                                                       Unit__r.BuildingSectionName__r.name  FROM  Commission_Line_Items__r ) FROM QuarterlyBonusCommission__c WHERE Id=:recordId LIMIT 1];
       
        
        for(Document__c doc: [SELECT Id, QuarterlyBonusCommission__c, DocumentType__c, AvailableForExternalUsers__c FROM Document__c WHERE QuarterlyBonusCommission__c  =: quarterRecord.Id AND (DocumentType__c =: Constants.COMMISSION_LINE_BONUS_COMMISSION )]) {
            relatedIds.add(doc.Id);
            invoiceBundleDocMap.put(doc.Id, doc.QuarterlyBonusCommission__c);  
        }        
        newMap = ContentDocumentLinkService.getIdUSLMap(relatedIds);
        for (Id docId: newMap.keySet()) {
            if (invoiceBundleDocMap.containsKey(docId)) {
                publicIdURLMap.put(invoiceBundleDocMap.get(docId), newMap.get(docId));
            }
        }
        Map<String, String> idURLMap = publicIdURLMap.containsKey(quarterRecord.Id) ? publicIdURLMap.get(quarterRecord.Id) : new Map<String, String>();
        
        request.Id = quarterRecord.Id;
        request.OwnerId = quarterRecord.OwnerId;
        request.IsDeleted = quarterRecord.IsDeleted;
        request.Name = quarterRecord.Name;
        request.CurrencyIsoCode = quarterRecord.CurrencyIsoCode;
        request.CreatedDate = quarterRecord.CreatedDate;
        request.CreatedById = quarterRecord.CreatedById;
        request.LastModifiedDate = quarterRecord.LastModifiedDate;
        request.LastModifiedById = quarterRecord.LastModifiedById;
        request.SystemModstamp = quarterRecord.SystemModstamp;
        request.LastActivityDate = quarterRecord.LastActivityDate;
        request.ApprovalStatus = quarterRecord.Approval_Status__c;
        request.BrokerAgency = quarterRecord.BrokerAgency__c;
        request.CommentTrail = quarterRecord.CommentTrail__c;
        request.Comments = quarterRecord.Comments__c;
        request.Quarter = quarterRecord.Quarter__c;
        request.Status = quarterRecord.Status__c;
        request.Year = quarterRecord.Year__c;
        request.quarterlyBonusInvoiceFormDocId = !idURLMap.isEmpty() && idURLMap.containsKey('Id') ? idURLMap.get('Id') : '';
        request.quarterlyBonusInvoiceFormDocURL = !idURLMap.isEmpty() && idURLMap.containsKey('URL') ? idURLMap.get('URL') : '';
        
        request.CommissionLineItems = new QuarterlyBrokerRequestPayload.CommissionLineItem();
        List<QuarterlyBrokerRequestPayload.Records> recordList = new List<QuarterlyBrokerRequestPayload.Records>();
        for(CommissionLineItem__c cli : quarterRecord.Commission_Line_Items__r){
            QuarterlyBrokerRequestPayload.Records record = new QuarterlyBrokerRequestPayload.Records();
            QuarterlyBrokerRequestPayload.BrokerAgency agency = new QuarterlyBrokerRequestPayload.BrokerAgency();
            QuarterlyBrokerRequestPayload.Unit unitrecord = new QuarterlyBrokerRequestPayload.Unit();
            record.Id = cli.Id;
            record.Name = cli.Name;
            record.BrokerAgencyId = cli.BrokerAgency__c;
            record.CommissionAmount = cli.CommissionAmount__c;
            record.UnitId = cli.Unit__c;
            record.SalesOrderId = cli.SalesOrder__c;
            record.OrderDate = cli.OrderDate__c;
            record.CommissionPercentage = cli.CommissionPercentage__c;
            record.NetAmount = cli.NetAmount__c;
            
            agency.Name = cli.BrokerAgency__r.name;
            agency.BrokerClassificationFormula = cli.BrokerAgency__r.Broker_Classification_Formula__c;
            record.BrokerAgency = agency;
            
            unitrecord.Name = cli.Unit__r.Name;
            unitrecord.BuildingSectionNameId = cli.Unit__r.BuildingSectionName__c;
            unitrecord.BuildingSectionName = cli.Unit__r.BuildingSectionName__r.Name;
            record.Unit = unitrecord;
            recordList.add(record);
        }
        request.CommissionLineItems.records = recordList;
        system.debug('request::'+request);
        system.debug('request::'+JSON.serialize(request));
        gen.writeObject(request);
        // Get the JSON string.
        String pretty = gen.getAsString();
        system.debug(pretty);
        return pretty;
    }
    
}