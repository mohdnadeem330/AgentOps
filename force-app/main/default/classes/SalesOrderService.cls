public class SalesOrderService {
    public static String Cancellationinprogress                     = System.Label.Cancellationinprogress;
    public static String Cancelled                                  = System.Label.Cancelled;
    public static String RejectedbyBank                             = System.Label.RejectedbyBank;
    public static List<String> cancelledOrRejectedList              = new List<String>{Cancellationinprogress,Cancelled,RejectedbyBank};
        
    public static set<string> getMandatoryDocsStatus(salesorder__c SO){
        set<String> SalesOrderDoclist = new set<String>();
        set<string> MissingDocs = new set<String>();
        String residentStatus = null;
        residentStatus= SO.ContactResidentStatus__c;
            list<MandatoryDocList__mdt> MDocList = [select Document_Name__c,Object_Name__c,Applicable_for_Residents_only__c  from MandatoryDocList__mdt where Active__c = True order by Object_Name__c];
        list<String> accDocs = new list<String>();
        list<String> SODocs = new list<String>();
        for(MandatoryDocList__mdt Mdoc : MDocList) {
            
            if(residentStatus != null){
                if(Mdoc.Applicable_for_Residents_only__c == TRUE && residentStatus.equals('Resident') == FALSE ) { // && residentStatus.equals('Non-Resident')){
                    system.debug('Resident');
                    continue;
                }
                
                if(Mdoc.Object_Name__c == 'Account'){
                    accDocs.add(MDoc.Document_Name__c);
                }
            }
            
            if(MDoc.Object_Name__c == 'SalesOrder__c'){
                SODocs.add(MDoc.Document_Name__c);
            }
        }
        system.debug('accDocs' + accDocs);
        system.debug('SODocs' + SODocs);
        if(accDocs.size() > 0 ||  SODocs.size()>0){
            list<document__c> lstDocs = [Select id,DocumentType__c,account__c,SalesOrder__c from document__c where (account__c = :SO.account__c AND DocumentType__c IN :accDocs ) OR (SalesOrder__c = :SO.Id AND DocumentType__c IN :SODocs) order by SalesOrder__c];
            list<ContentDocumentLink> lstDocFiles = [SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId IN (SELECT Id FROM Document__c where (account__c = :SO.account__c AND DocumentType__c IN :accDocs ) OR (SalesOrder__c = :SO.Id AND DocumentType__c IN :SODocs ))];
            set<id> DocFilesId = new set<id>();
            for(ContentDocumentLink docfile : lstDocFiles ) {
                DocFilesId.add(docfile.LinkedEntityId);
            }
            if (!lstDocs.isempty()) {
                for(document__c doc : lstDocs) {
                    if(!String.isBlank(doc.account__c) && !DocFilesId.contains(doc.id) ){
                        system.debug('doc.id' + doc.id);
                        MissingDocs.add(doc.DocumentType__c + '(Account)');
                    }
                    if(!String.isBlank(doc.SalesOrder__c) && !DocFilesId.contains(doc.id) ){
                        system.debug('doc.id' + doc.id);
                        MissingDocs.add(doc.DocumentType__c + '(Sales Order)');
                    }
                }
            }
        }
        system.debug('MissingDocs' + MissingDocs) ;
        return MissingDocs;
       
    }
    
    public static List<SalesOrder__c> getSalesOrderByAccountId(Set<Id> accountIds){
        return [SELECT Id,Name,Unit__c, Unit__r.Name,Account__c,Status__c,RecordType.Name, (SELECT Id, Name FROM SalesOrdersOtherCharges__r WHERE TypeOfCharge__c =: Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO) FROM SalesOrder__c WHERE Account__c IN:accountIds];
    }
    
    @AuraEnabled
    public static List<SalesOrder__c> getSalesOrderRec(Id SalesOrderId){
        return [SELECT Id,Name,Account__c,Account__r.Name FROM SalesOrder__c WHERE Id =:SalesOrderId AND Account__c != null];
    }
    public static Map<Id,List<SalesOrder__c>> getAccountOpportunityUnitMap(Set<Id>accountIds){
        Map<Id,List<SalesOrder__c>> accountMap = new Map<Id,List<SalesOrder__c>>();
        for(SalesOrder__c opportunityUnitRec : getSalesOrderByAccountId(accountIds)){
            List<SalesOrder__c> opportunityUnitList ;
            Id accountId = opportunityUnitRec.Account__c ;
            opportunityUnitList = (accountMap.containsKey(accountId) ? accountMap.get(accountId) : new List<SalesOrder__c>());
            opportunityUnitList.add(opportunityUnitRec);
            accountMap.put(accountId,opportunityUnitList);
        }
        return accountMap;
    }
    public static Map<Id,List<SalesOrder__c>> getOpportunitySalesOrderMap(Set<Id> opportunityIds){
        Map<Id,List<SalesOrder__c>> opportunitySalesOrderMap = new Map<Id,List<SalesOrder__c>>();
        for(SalesOrder__c salesOrderRec : getSalesOrderByOpportunityIdSet(opportunityIds)){
            List<SalesOrder__c> salesOrderList ;
            Id opportunityId = salesOrderRec.Opportunity__c ;
            salesOrderList = (opportunitySalesOrderMap.containsKey(opportunityId) ? opportunitySalesOrderMap.get(opportunityId) : new List<SalesOrder__c>());
            salesOrderList.add(salesOrderRec);
            opportunitySalesOrderMap.put(opportunityId,salesOrderList);
        }
        return opportunitySalesOrderMap;
    }
    /*
    * Get all the sales order booked today
    */
    public static List<AggregateResult> getSalesOrdersBookedToday(Set<Id> projectBudgetIds){
        AggregateResult[] groupedResults = [SELECT ProjectBudget__c,SUM(Discount__c) discount,SUM(ADMFeeWaivedAmount__c) admfee,SUM(DARNAAmount__c) darnaAmount
        ,SUM(ExternalCommissionAmount__c) externalComission,SUM(HomeMaintenanceWaivedAmount__c) homemaintenance,SUM(InternalCommissionAmount__c) internalComission,
        SUM(ServiceChargeWaivedAmount__c) serviceCharge,SUM(SubsidyAmount__c) subsidyAmount,SUM(OtherRebateAmount__c) rebateAmount,SUM(OtherSalesSupportAmount__c) othersupportAmount
        FROM SalesOrder__c 
        WHERE  CreatedDate > YESTERDAY AND ProjectBudget__c IN:projectBudgetIds AND Status__c !=:Constants.SO_STATUS_CANCELLED GROUP BY ProjectBudget__c];
        
        return groupedResults ;
    }
    /*
    * Get all the sales order cancelled today
    */
    public static List<AggregateResult> getSalesOrdersCancelledToday(Set<Id> projectBudgetIds){
        String cancelledStatus = Constants.SO_STATUS_CANCELLED;
        AggregateResult[] groupedResults = [SELECT ProjectBudget__c,SUM(Discount__c) discount,SUM(ADMFeeWaivedAmount__c) admfee,SUM(DARNAAmount__c) darnaAmount
        ,SUM(ExternalCommissionAmount__c) externalComission,SUM(HomeMaintenanceWaivedAmount__c) homemaintenance,SUM(InternalCommissionAmount__c) internalComission,
        SUM(ServiceChargeWaivedAmount__c) serviceCharge,SUM(SubsidyAmount__c) subsidyAmount,SUM(OtherRebateAmount__c) rebateAmount,SUM(OtherSalesSupportAmount__c) othersupportAmount
        FROM SalesOrder__c 
        WHERE SalesOrderCancelledDate__c != null AND SalesOrderCancelledDate__c = TODAY AND Status__c =: cancelledStatus AND ProjectBudget__c IN:projectBudgetIds  GROUP BY ProjectBudget__c];
        
        return groupedResults ;
    }
    
    public static Set<Id> getSalesOrdersAccountIds(Id salesOrderId ){
        Set<Id> accountIds = new    Set<Id> ();
        List<SalesOrder__c> salAccounts =  [SELECT Name,Account__c from SalesOrder__c WHERE  Id=:salesOrderId];
        for(SalesOrder__c  sa : salAccounts){
            accountIds.add(sa.Account__c);
        }
        return accountIds;
    }
    public static Set<Id> getAllSalesOrdersAccountIds(Set<Id> salesOrderId ){
    
        Set<Id> accountIds = new    Set<Id> ();
       List<SalesOrder__c> salAccounts =  [SELECT Name,Account__c from SalesOrder__c WHERE  Id IN:salesOrderId];
      for(SalesOrder__c  sa : salAccounts){
          accountIds.add(sa.Account__c);
      }
      return accountIds;
    }
    
  /*
  * Fetch list of Sales Order based on the condition
  */
  public static List<SalesOrder__c> fetchSalesOrders(string whereCondition){
      
      List<SalesOrder__c> salesOrderList= new List<SalesOrder__c>();
     
      try{
          Set<String> soFieldList = Schema.getGlobalDescribe().get('SalesOrder__c').getDescribe().fields.getMap().keySet();
          List<String> strList = new List<String>();
          strList.addAll(soFieldList);
          Integer i = 0;
          while (i < strList.size()){
              if(strList.get(i).contains('CustomerAddress__c') || strList.get(i).contains('ErrorReason__c') || 
                 strList.get(i).contains('HandoverRemarks__c') ||strList.get(i).contains('JointOwnerNames__c') || 
                 strList.get(i).contains('JointOwnerNamesinArabic__c') ||strList.get(i).contains('JointOwnerNationalities__c') || 
                 strList.get(i).contains('JointOwnerNationalitiesinArabic__c') ||strList.get(i).contains('JointOwnerPassportNumbers__c') || 
                 strList.get(i).contains('JointOwnerSharePercentages__c') || strList.get(i).contains('SubStatusRemarks__c') ||
                 strList.get(i).contains('NetAmountinArabic__c') ||  strList.get(i).contains('PropertyRegistrationRemarks__c')){
                     strList.remove(i);
                 } else {
                     i++;
                 }
          }
             
              
              String fields = string.join(strList, ',');

            String strQuery = 'SELECT ' + fields + ', Unit__r.Project__r.DigitalSignatureApplied__c,Unit__r.Name, Unit__r.Project__c, Unit__r.EscalationServiceCharge__c, Unit__r.AnticipatedServiceCharges__c, Unit__r.MeasuredArea__c, Unit__r.SaleableArea__c, Unit__r.TotalArea__c, Account__r.Name, Offer__r.Name, PaymentPlan__r.Name FROM SalesOrder__c WHERE Id != null ';
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' Order By Name DESC limit '+Utilities.getRecordCount('SalesAppFetchRecordCount',Utilities.getRecordCount('SalesAppMaxRecordCount',0));
            system.debug('--Sales Order Query--'+strQuery);
            salesOrderList = Database.query(strQuery);
            return salesOrderList;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
            throw e;
        }
    }
    
  /*
  * Fetch list of Sales Order for logged in Sales Manager
  */
    public static List<SalesOrder__c> getSalesOrderForManager(Map<String, String> mapFieldApiFieldValues){
      List<String> andConditions = new List<String>();
      if (mapFieldApiFieldValues == null)
        mapFieldApiFieldValues = new Map<String, String>();
      mapFieldApiFieldValues.put('SalesManager__c', UserInfo.getUserId());
    
      Utilities.objType = 'salesorder';
      String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
      if (String.isNotBlank(whereConditionFromMap))
          andConditions.add(whereConditionFromMap);
      System.debug(whereConditionFromMap);
      String whereCondition = String.join(andConditions, ' AND ');
      
      System.debug('**Query**'+whereCondition);
      List<SalesOrder__c> salesOrders = fetchSalesOrders(whereCondition);
      return salesOrders ;
    }
    public static List<SalesOrder__c> fetchSalesOrderByAccountId(String accountId) {
        return [SELECT id,Status__c FROM SalesOrder__c WHERE Account__c =: accountId];
    }
    
    public static List<SalesOrder__c> fetchSalesOrderForAPIByUser(String userId) {
        return [SELECT Id, NetAmount__c, Status__c, Opportunity__c, Opportunity__r.AgentType__c FROM SalesOrder__c WHERE SalesManager__c =: userId AND BookingDate__c = THIS_FISCAL_YEAR];
    }
     public static List<Document__c> getAllActiveDirectDebitRequests(String soIdsStr) {
        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        List<Document__c> documentList = new List<Document__c>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');
        
        Map<Id,DirectDebitRequest__c> activeDirectDebitRequestsMap = 
            new Map<Id, DirectDebitRequest__c>( [SELECT
                                                 Id FROM
                                                 DirectDebitRequest__c
                                                 WHERE SalesOrder__c=:soIdsStr 
                                                 AND Status__c NOT 
                                                 IN: cancelledOrRejectedList]);
        List<String> strList = new List<String>();
        for(String str: activeDirectDebitRequestsMap.keySet() ){
            strList.add(str);
        }
        String ddrStrng = String.join(strList, '\',\'');
        system.debug('ddrStrng::::'+ddrStrng);
        String query = '';
        if(ddrStrng != null && ddrStrng != ''){
            query = 'SELECT '+docFields+ ' FROM Document__c WHERE DirectDebitRequest__r.Id IN (\'' + ddrStrng + '\')';
            system.debug('*****Query*****'+query);
            system.debug('*****Database.query(query)*****'+Database.query(query).size());
            documentList = Database.query(query);
        }
        
        return documentList;
        
    }
    
    public static List<SalesOrder__c> queryAllFieldsWithExtraFields(List<Id> soIds) {

        String soIdsStr = String.join(soIds, '\',\'');
        String whrClause = ' Id IN (\'' + soIdsStr + '\') ';
        List<SalesOrder__c> SalesOrders = queryAllFieldsWithWhereClause(whrClause);
        
        return SalesOrders;
    }
    public static List<SalesOrder__c> queryAllFieldsWithWhereClause(String whrClause) {
        Set<String> soFieldList = Schema.getGlobalDescribe().get('SalesOrder__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(soFieldList);
        String fields = string.join(strList, ',');
        
        Set<String> ocFieldList = Schema.getGlobalDescribe().get('SalesOrderCancellation__c').getDescribe().fields.getMap().keySet();
        List<String> strOCList = new List<String>();
        strOCList.addAll(ocFieldList);
        String ocFields = string.join(strOCList, ',');

        Set<String> ilFieldList = Schema.getGlobalDescribe().get('InstallmentLines__c').getDescribe().fields.getMap().keySet();
        List<String> strILList = new List<String>();
        strILList.addAll(ilFieldList);
        String ilFields = string.join(strILList, ',');

        Set<String> socFieldList = Schema.getGlobalDescribe().get('SalesOrderOtherCharges__c').getDescribe().fields.getMap().keySet();
        List<String> strSOCList = new List<String>();
        strSOCList.addAll(socFieldList);
        String socFields = string.join(strSOCList, ',');

        Set<String> oolFieldList = Schema.getGlobalDescribe().get('OpportunityOfferLine__c').getDescribe().fields.getMap().keySet();
        List<String> strOOLList = new List<String>();
        strOOLList.addAll(oolFieldList);
        String oolFields = string.join(strOOLList, ',');

        Set<String> cliFieldList = Schema.getGlobalDescribe().get('CommissionLineItem__c').getDescribe().fields.getMap().keySet();
        List<String> strCLIList = new List<String>();
        strCLIList.addAll(cliFieldList);
        String cliFields = string.join(strCLIList, ',');

        Set<String> joFieldList = Schema.getGlobalDescribe().get('JointOwner__c').getDescribe().fields.getMap().keySet();
        List<String> strJOList = new List<String>();
        strJOList.addAll(joFieldList);
        String joFields = string.join(strJOList, ',');

        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strRAList = new List<String>();
        strRAList.addAll(raFieldList);
        String raFields = string.join(strRAList, ',');

        Set<String> rallFieldList = Schema.getGlobalDescribe().get('ReceiptAllocation__c').getDescribe().fields.getMap().keySet();
        List<String> strRAllList = new List<String>();
        strRAllList.addAll(rallFieldList);
        String rallFields = string.join(strRAllList, ',');

        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');
        
        // Added by Sanath H M,  Date: 12.12.2022
        Set<String> ddrFieldList = Schema.getGlobalDescribe().get('DirectDebitRequest__c').getDescribe().fields.getMap().keySet();
        List<String> strDDrList = new List<String>();
        strDDrList.addAll(ddrFieldList);
        String ddrFields = string.join(strDDrList, ',');

        // String externalStr = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
        String query = 'SELECT ' + fields + ', Account__r.PassportNumber__pc, Account__r.UnifiedNumber__c, Account__r.Nationality__pc, Account__r.IsPersonAccount, Unit__r.Project__r.DirectDebitApplied__c, Unit__r.Project__r.DirectDebitOIC__c, Unit__r.Project__r.BankNameEscrow__c, Account__r.RegistrationNumber__c, Account__r.NationalIdNumber__pc, Account__r.RecordType.Name, Account__r.Name,Account__r.CorporateWealthName__c, Account__r.id, Account__r.ERPID__c, Account__r.Email__c, Account__r.PersonEmail, Account__r.Phone, Account__r.PersonMobilePhone, Account__r.MobileNumber__c, Account__r.MobileCountryCode__c,Opportunity__r.ReservationApprovalStatus__c,Opportunity__r.CustomerResidentStatus__c, Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, CreatedBy.Email, Owner.Email, Owner.Name, Offer__r.SalesEventCampaignName__c, Unit__r.ADMSectorName__c, Unit__r.ADMPlotNumber__c, Unit__r.ADMUnitNumber__c, Unit__r.ADMBuildingNumber__c, Unit__r.Name, PaymentPlan__r.Name, Unit__r.MeasuredArea__c, Unit__r.SaleableArea__c, Unit__r.TotalArea__c, Unit__r.Project__r.BusinessUnitId__c, Unit__r.Project__r.ExcludeFromADM__c, Unit__r.Project__r.City__c, Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c, Unit__r.BuildingSectionName__r.TransferThresholdLimit__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, Unit__r.BuildingSectionName__r.LaunchStartDate__c, Unit__r.recordTypeId, Unit__r.SellingPrice__c, PaymentPlan__r.Classification__c, ProjectBudget__r.Name, Opportunity__r.BrokerAgencyAccount__r.Name, Opportunity__r.BrokerAgentContact__r.Name, Opportunity__r.BrokerAgentContact__r.NationalIdNumber__c, OpportunityEOI__r.Name, ';
        query += ' (SELECT ' + ocFields + ', CreatedBy.Email FROM Sales_Order_Cancellation__r WHERE Cancellation_Status__c = \'Approved\' LIMIT 1), ';
        query += ' (SELECT ' + ilFields + ', PaymentPlan__r.Name, CreatedBy.Email, RTOLine__r.RentEscalation__c, RTOLine__r.RebateAmount__c, RTOLine__r.RTOConfiguration__r.DiscountPercentage__c, RTOLine__r.OptionFee__c, RTOLine__r.OptionFeeAmount__c, RTOLine__r.RemainingPayment__c, RTOLine__r.Rent__c FROM InstallmentLines__r order by InstallmentNumber__c asc), ';
        query += ' (SELECT ' + socFields + ', Account__r.Name, Account__r.ERPID__c, SalesOrder__r.ERPID__c FROM SalesOrdersOtherCharges__r), ';
        query += ' (SELECT ' + oolFields + ', OfferLine__r.OfferOn__c, OfferLine__r.OfferType__c, OfferLine__r.OfferName__c, OfferLine__r.OfferName__r.OfferName__c FROM OpportunityOfferLines__r), ';
        query += ' (SELECT ' + cliFields + ', CreatedBy.Email, Owner.Email, BrokerAgency__r.Name, BrokerAgency__r.ERPID__c, BrokerAgency__r.OtherERPID__c, BrokerAgent__r.Name, SalesManager__r.Name, SalesManager__r.Email FROM CommissionLineItems__r), ';
        query += ' (SELECT ' + joFields + ', Account__r.UnifiedNumber__c, Account__r.RecordType.Name, Account__r.NationalIdNumber__pc, Account__r.RegistrationNumber__c, Account__r.PersonEmail, Account__r.Nationality__pc, Account__r.Name, Account__r.NameInArabic__c, Account__r.NationalityinArabic__pc, Account__r.PassportNumber__pc FROM Joint_OwnersSalesOrder__r), ';
        query += ' (SELECT ' + raFields + ', Account__r.Name FROM Payments__r), ';
        query += ' (SELECT ' + rallFields + ', InstallmentLine__r.InvoiceNumber__c FROM ReceiptAllocations__r), ';
        query += ' (SELECT ' + docFields + ' FROM Documents__r ORDER BY DocumentType__c ASC), ';
        query += ' (SELECT ' + ddrFields+ ', PayerAccount__r.Name FROM Direct_Debit_Request__r) ';
        query += ' FROM SalesOrder__c ';
        if (String.isNotBlank(whrClause)) {
            query = query + ' WHERE ' + whrClause;
        }
        System.debug('***SalesOrder query***' + query);
        List<SalesOrder__c> SalesOrders = Database.Query(query);
        System.debug('***SalesOrder Queried***' + SalesOrders);
        return SalesOrders;
    }
    
    public static SalesOrder__c getAccountWithJointOwners(String soId) {
        SalesOrder__c so = [SELECT Id, Name, Account__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingCity, 
                            Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.ShippingStreet, 
                            Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry, 
                            (SELECT Id, Account__c, RelationshipType__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingCity, 
                            Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.ShippingStreet, 
                            Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry 
                            FROM Joint_OwnersSalesOrder__r) FROM SalesOrder__c WHERE Id =: soId];
        return so;
    }
    
            
    public static void newOpportunityUnitRecord(List<SalesOrder__c> newList){
        for(SalesOrder__c newSalesOrder : newList){
            if( newSalesOrder.Opportunity__c != null){ // added null check by Kuhinoor...
                OpportunityService.updateOpportunityStage(newSalesOrder.Opportunity__c,'meeting');

            }
        }
    }
    /*
    public static void createDocuments(map<id,SalesOrder__c> salesOrderMap){
        
        List<Document__c> documentList = new List<Document__c>();
        set<String> documentsNames =new set<String>{
            Constants.DOCUMENT_TYPE_KYC,Constants.DOCUMENT_TYPE_RA,Constants.DOCUMENT_TYPE_SIGNED_KYC,Constants.DOCUMENT_TYPE_SIGNED_RA,Constants.DOCUMENT_TYPE_WEALTH ,
            Constants.DOCUMENT_TYPE_SIGNED_WEALTH
        };
        //get Existing Documents
        map<string,Document__c> existingDocMap = new map<string,Document__c>();
        for(Document__c tempDoc : [select id,DocumentType__c,SalesOrder__c from Document__c where DocumentType__c in :documentsNames and SalesOrder__c in :salesOrderMap.keySet()]){
                existingDocMap.put(tempDoc.DocumentType__c + tempDoc.SalesOrder__c,tempDoc);
        }
        
        for(SalesOrder__c newSalesOrder : salesOrderMap.values()){
            if (newSalesOrder.Status__c == Constants.STATUS_RESERVED) {
                for (String docName : documentsNames) {
                    if(!existingDocMap.containsKey( docName + newSalesOrder.Id)){
                        Document__c documentRecord = new Document__c();
                        documentRecord = DocumentService.createDocumentRecord(newSalesOrder.Opportunity__c, '', newSalesOrder.Unit__c, docName, newSalesOrder.Id, '');
                        documentList.add(documentRecord);        
                    }
                }
            }
        }
        if(!documentList.isEmpty()){
          DocumentService.insertDocumentRecords(documentList);  
        } 
    } */
    public static Boolean cancelSalesOrderReservation(Set<String> idList) {
        system.debug('cancelSalesOrderReservation' + idList);
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
              
        for(SalesOrder__c objSalesOrder : [Select id,Name from SalesOrder__c where id IN:idList]){
            objSalesOrder.Status__c = Constants.SALES_STATUS_CANCELLED;
            salesOrderList.add(objSalesOrder);
          }
          update salesOrderList;
          return true;     
    }
    /*
    * Get all Sales Orders By AccountId
    */
    public static List<SalesOrder__c> getOpportunityUnitByAccountId(Set<Id> accountIds){
        return [SELECT Id,Name,Unit__c,Account__c FROM SalesOrder__c WHERE Account__c IN:accountIds];
    }
    /*
    * Get all Sales Orders By opportunityId
    */
    public static List<SalesOrder__c> getSalesOrderByOpportunityId(String opportunityId){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,Opportunity__c,ReceiptAcknowledgementPaymentMethod__c,NetAmount__c FROM SalesOrder__c WHERE Opportunity__c =:opportunityId];
    }
    /*
    * Get all Sales Orders By opportunityId Set
    */
    public static List<SalesOrder__c> getSalesOrderByOpportunityIdSet(Set<Id> opportunityIds){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,Opportunity__c,ReceiptAcknowledgementPaymentMethod__c,NetAmount__c FROM SalesOrder__c WHERE Opportunity__c in:opportunityIds];
    }
    /*
    * Get Sales Order By unitId
    */
    public static SalesOrder__c getSalesOrderByUnitId(String unitId){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,ReceiptAcknowledgementPaymentMethod__c,NetAmount__c FROM SalesOrder__c WHERE Unit__c =:unitId limit 1];
    }

    /*
    * Get Sales Orders By unitIds
    */
    public static List<SalesOrder__c> getSalesOrdersByUnitIds(List<Id> unitIds){
        return [SELECT Id, Unit__c, Account__c, Account__r.PersonContactId, Status__c, Contact__c, TotalInstallmentReceived__c, TotalOutstanding__c, NetAmount__c, TotalBilled__c, NumberOfDefaults__c, HoldFlag__c, Unit__r.Project__r.AsiteProjectName__c  FROM SalesOrder__c WHERE Unit__c IN: unitIds];
    }
    
    public static List<SalesOrder__c> getSalesOrderDetailsWithWhereClause(String whrClause) {
        Set<String> soFieldList = Schema.getGlobalDescribe().get('SalesOrder__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(soFieldList);
        String fields = string.join(strList, ',');

        Set<String> ilFieldList = Schema.getGlobalDescribe().get('InstallmentLines__c').getDescribe().fields.getMap().keySet();
        List<String> strILList = new List<String>();
        strILList.addAll(ilFieldList);
        String ilFields = string.join(strILList, ',');

        Set<String> joFieldList = Schema.getGlobalDescribe().get('JointOwner__c').getDescribe().fields.getMap().keySet();
        List<String> strJOList = new List<String>();
        strJOList.addAll(joFieldList);
        String joFields = string.join(strJOList, ',');

        String query = 'SELECT ' + fields + ', Account__r.Name, Unit__r.Name, Unit__r.NumberOfBedrooms__c, Unit__r.NumberOfBathrooms__c, Unit__r.Project__c, Unit__r.Project__r.Name, Unit__r.Project__r.City__c, Unit__r.Project__r.Description__c, Unit__r.Project__r.Amenities__c, ';
        query += ' (SELECT ' + ilFields + ' FROM InstallmentLines__r ORDER BY InstallmentNumber__c ASC), ';
        query += ' (SELECT ' + joFields + ' FROM Joint_OwnersSalesOrder__r) ';
        query += ' FROM SalesOrder__c ';
        if (String.isNotBlank(whrClause)) {
            query = query + ' WHERE ' + whrClause;
        }
        System.debug('SalesOrder query>>>' + query);
        List<SalesOrder__c> SalesOrders = Database.Query(query);
        System.debug('SalesOrder Data>>>' + SalesOrders);
        return SalesOrders;
    }

    public static List<SalesOrderCancellation__c> getSalesOrderCancellation(Id salesOrderId) {
       
        Set<String> cancelOrderFieldList = Schema.getGlobalDescribe().get('SalesOrderCancellation__c').getDescribe().fields.getMap().keySet();
        List<String> strOCList = new List<String>();
        strOCList.addAll(cancelOrderFieldList);
        String ocFields = string.join(strOCList, ',');
        String query = 'SELECT ' + ocFields + ' FROM SalesOrderCancellation__c WHERE SalesOrder__c = \'' + salesOrderId + '\'';
        System.debug('***SalesOrder query***'+query);
        List<SalesOrderCancellation__c> salesOrderCancellation = Database.Query(query);
        System.debug('***Sales Order Cancellation Queried***'+salesOrderCancellation);
        return salesOrderCancellation;
    }     

    @AuraEnabled
    public static MandatoryDocWrapper getMandatoryDocs(String opportunityId){
        // updated by Moh Sarfaraj on 17 July 23 for ASF-1107
        Opportunity oppRecord = [Select Id, Name, Project__c, AccountId, Account.RecordType.Name, SaleType__c from Opportunity where Id=:opportunityId];
        MandatoryDocWrapper wrapperToReturn = new MandatoryDocWrapper();
        if(oppRecord.SaleType__c != 'AM Sale'){
        String accountType = '';
        Account oppRelatedAccount = new Account();
        Map<String,Boolean> mapOfDocumentTypeWithExistingFile = new Map<String,Boolean>();
        if(string.isnotblank(oppRecord.AccountId)){
            Map<Id,Document__c> mapOfDocument = new Map<Id,Document__c>([select Id, DocumentType__c from Document__c where Account__c=:oppRecord.AccountId]);
            accountType = oppRecord.Account.RecordType.Name == 'Organization Account' ? 'Organization': 'Person';
            oppRelatedAccount = [Select Id, Nationality__pc, ResidentStatus__pc, EmploymentStatus__pc,CustomerType__c, CustomerSubType__c from Account where Id=:oppRecord.AccountId];
            Set<Id> newSet = mapOfDocument.keyset();
            if(newSet.size() >0){//Added by Chirag
                for(ContentDocumentLink cdl : [Select Id, LinkedEntityId from ContentDocumentLink where LinkedEntityId IN: newSet]){
                    mapOfDocumentTypeWithExistingFile.put(mapOfDocument.get(cdl.LinkedEntityId).DocumentType__c,true);
                }
        	}
        }
            //added by Nikhil 17Jul25
            String projectCountries;
            if(oppRecord.Project__c.containsIgnoreCase('London') || oppRecord.Project__c.containsIgnoreCase('Square')){
                projectCountries = 'United Kingdom';
            }else{
                projectCountries = 'United Arab Emirates';
            }   
            //added by Nikhil 17Jul25
        Set<String> missingDocs = new Set<String>();
        Map<String,MandatoryDocument__mdt> mapOfDocumentNameWithDocumentInfo = new Map<String,MandatoryDocument__mdt>();
        for(MandatoryDocument__mdt mandatoryDoc : MandatoryDocument__mdt.getAll().values()){
            // Added by Moh Sarfaraj on 17 July 23 for ASF-1107
            Set<String> setExemptProjects = new Set<String>();
            Set<String> exemptCountrySet = new Set<String>();
           
            if(String.isNotBlank(mandatoryDoc.Exempt_Country__c)){
                exemptCountrySet = new Set<String>(mandatoryDoc.Exempt_Country__c.split(','));
            }
            if(String.isNotBlank(mandatoryDoc.Exempt_From_Project__c)){
                setExemptProjects = new Set<String>(mandatoryDoc.Exempt_From_Project__c.split(','));
            }
            String nationality = string.isnotblank(oppRelatedAccount.Nationality__pc) ? oppRelatedAccount.Nationality__pc : '';
            if(mandatoryDoc.Active__c && !mandatoryDoc.NationalitiesExcempted__c.contains(nationality) && 
               mandatoryDoc.AccountType__c == accountType && !setExemptProjects.contains(oppRecord.Project__c) 
               && (!exemptCountrySet.contains(projectCountries))){ //added by Nikhil 17Jul25
                                                            // Added by Moh Sarfaraj on 17 July 23 for ASF-1107
                
                if(oppRelatedAccount.ResidentStatus__pc == 'Resident' && mandatoryDoc.ApplicableForResidentsOnly__c){
                    mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
                }else if(oppRelatedAccount.ResidentStatus__pc == 'Non-Resident' && mandatoryDoc.ApplicableForNonResidentsOnly__c){
                    mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
                }else if(oppRelatedAccount.EmploymentStatus__pc != null && oppRelatedAccount.EmploymentStatus__pc == 'Self Employed'
               			&& mandatoryDoc.DocumentName__c == 'Trade License'){
                   		mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
               	}else if(!mandatoryDoc.ApplicableForResidentsOnly__c && !mandatoryDoc.ApplicableForResidentsOnly__c && mandatoryDoc.DocumentName__c != 'Trade License' && mandatoryDoc.DocumentName__c != 'Confirmation Letter' && mandatoryDoc.DocumentName__c !='Corporate partner ID proof'){
                    mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
                }else if(mandatoryDoc.DocumentName__c == 'Confirmation Letter' && oppRelatedAccount.CustomerType__c != null && oppRelatedAccount.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF)){
                    mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
                }else if(mandatoryDoc.DocumentName__c =='Corporate partner ID proof' && oppRelatedAccount.CustomerSubType__c != null && oppRelatedAccount.CustomerSubType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_SUBTYPE_CORPORATE)){
                    mapOfDocumentNameWithDocumentInfo.put(mandatoryDoc.DocumentName__c,mandatoryDoc);
                }
            }
        }
    
        for(String docType : mapOfDocumentNameWithDocumentInfo.keyset()){
            if(!mapOfDocumentTypeWithExistingFile.containskey(docType)){
                missingDocs.add(docType);
            }
        }
        
        wrapperToReturn.message = 'Mandatory Document(s) are missing on the Account. Please upload '+ String.join((Iterable<String>)missingDocs, ', ');
        wrapperToReturn.requiredDocMissing = !missingDocs.isEmpty();
            return wrapperToReturn;
        }
        wrapperToReturn.requiredDocMissing = false;
        return wrapperToReturn;
    }
    
    //Getting unit project city for ADM / RAK / DLD -  Added by Anil Kumar for SSP-431
    @AuraEnabled(cacheable=true)
    public static String getUnitLocationById(Id unitId) {
        Unit__c unit = [SELECT Project__r.City__c FROM Unit__c WHERE Id = :unitId LIMIT 1 ];
        return unit.Project__r != null ? unit.Project__r.City__c : null;
    }

    public class MandatoryDocWrapper{
        @auraEnabled public string message{get;set;}
        @auraEnabled public Boolean requiredDocMissing{get;set;}
    }
}