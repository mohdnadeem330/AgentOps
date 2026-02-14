public without sharing class ServiceRequestService {
    //Covered via ALD_DandTSR_Handler_CCTest test class
    /*
    * Query all Service Requests and related object attributes using Service Request Ids. 
    */
    @AuraEnabled
    public static List<HexaBPM__Service_Request__c> queryAllFieldsWithExtraFields(List<Id> srIds) {

        String srIdsStr = String.join(srIds, '\',\'');
        String whrClause = ' Id IN (\'' + srIdsStr + '\') ';
        List<HexaBPM__Service_Request__c> ServiceRequests = queryAllFieldsWithWhereClause(whrClause);
        
        return ServiceRequests;
    }

    /*
    * Query all Service Requests and related object attributes using the Custom Where Clause.
    */
    @AuraEnabled
    public static List<HexaBPM__Service_Request__c> queryAllFieldsWithWhereClause(String whrClause) {
        Set<String> srFieldList = Schema.getGlobalDescribe().get('HexaBPM__Service_Request__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(srFieldList);
        String fields = string.join(strList, ',');

        Set<String> atFieldList = Schema.getGlobalDescribe().get('AgencyTeam__c').getDescribe().fields.getMap().keySet();
        List<String> strATList = new List<String>();
        strATList.addAll(atFieldList);
        String atFields = string.join(strATList, ',');

        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strRAList = new List<String>();
        strRAList.addAll(raFieldList);
        String raFields = string.join(strRAList, ',');

        Set<String> srUnitFieldList = Schema.getGlobalDescribe().get('SRUnitSelected__c').getDescribe().fields.getMap().keySet();
        List<String> strSRUnitList = new List<String>();
        strSRUnitList.addAll(srUnitFieldList);
        String srUnitFields = string.join(strSRUnitList, ',');

        String query = 'SELECT ' + fields + ',ResaleOpportunity__r.SaleType__c, Unit__r.Project__r.City__c, CreatedBy.Email, SalesOrder__r.Remarks__c,SalesOrder__r.ERPID__c,RecordType.Name,HandoverDetail__r.HandoverCompletionDate__c,HandoverDetail__r.FinanceBilling__c,HandoverDetail__r.TitleDeedCompletionDate__c,HandoverDetail__r.RFODate__c,HandoverDetail__r.CHODate__c,HandoverDetail__r.RebateLine__c,SalesOrder__r.AdditionalRebate__c,SalesOrder__r.AdditionalRebate2__c,SalesOrder__r.RebateForfeitureLetterSent__c,SalesOrder__r.LastInstallmentRebate__c,SalesOrder__r.OtherRebateAmount__c, HexaBPM__Customer__r.TransferThresholdLimitExcluded__c, HexaBPM__Customer__r.Name, BuyerName__r.Name,HexaBPM__Customer__r.CustomerType__c,BuyerName__r.CustomerType__c,BuyerName__r.ERPID__c, Unit__r.Name, Owner.Name, SalesOrder__r.Name, SalesOrder__r.Opportunity__c, InstallmentLine__r.PaymentPlan__c, MortgageBank__r.Name, HexaBPM__Customer__r.ERPID__c, HexaBPM__Contact__r.mobilephone, SalesOrder__r.Contact__c, Case__r.Initial_Condition__c, Unit__r.ResaleListingExclusiveness__c, Unit__r.CancellationChargesExpiryDate__c,Unit__r.BuildingSectionName__c,Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c, (SELECT ' + atFields + ', Account__r.Name, Account__r.ERPID__c, JointOwner__r.ERPID__c, Account__r.NameInArabic__c, Account__r.Nationality__pc, Account__r.NationalityinArabic__pc, Account__r.PassportNumber__pc FROM Partners__r), (SELECT ' + raFields + ' FROM Receipt_Acknowledgements__r), (SELECT ' + srUnitFields + ', SalesOrder__r.Name, SalesOrder__r.ProjectName__c, SalesOrder__r.HandoverRFOPayDueDate__c, SalesOrder__r.Account__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.EscalationServiceCharge__c, SalesOrder__r.Unit__r.AnticipatedServiceCharges__c, SalesOrder__r.Unit__r.MeasuredArea__c, SalesOrder__r.Unit__r.SaleableArea__c, SalesOrder__r.Unit__r.TotalArea__c, SalesOrder__r.Unit__r.ResaleListingExclusiveness__c, SalesOrder__r.Unit__r.CancellationChargesExpiryDate__c, SalesOrder__r.SellingPrice__c, SalesOrder__r.NetAmount__c, SalesOrder__r.TotalInstallmentReceived__c, SalesOrder__r.TotalBilled__c, SalesOrder__r.TotalOutstanding__c, SalesOrder__r.OtherRebateAmount__c, SalesOrder__r.ADMFeeWaivedAmount__c, SalesOrder__r.PaymentPlan__c, SalesOrder__r.PaymentPlan__r.Name FROM SRUnitSelected__r) FROM HexaBPM__Service_Request__c';
        if (String.isNotBlank(whrClause)) {
            query = query + ' WHERE ' + whrClause;
        }
        System.debug('***ServiceRequest query***'+query);
        List<HexaBPM__Service_Request__c> ServiceRequests = Database.Query(query);
        System.debug('***ServiceRequest Queried***'+ServiceRequests);
        return ServiceRequests;
    }

    /*
    * Query all Service Requests attributes using the Custom Where Clause.
    */
    @AuraEnabled
    public static List<HexaBPM__Service_Request__c> getServiceRequestWithWhereClause(String whrClause) {
        Set<String> srFieldList = Schema.getGlobalDescribe().get('HexaBPM__Service_Request__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(srFieldList);
        String fields = string.join(strList, ',');

        String query = 'SELECT ' + fields + ', RecordType.Name ';
        query += ' FROM HexaBPM__Service_Request__c';
        if (String.isNotBlank(whrClause)) {
            query = query + ' WHERE ' + whrClause;
        }
        System.debug('***ServiceRequest query***'+query);
        List<HexaBPM__Service_Request__c> ServiceRequests = Database.Query(query);
        System.debug('***ServiceRequest Queried***'+ServiceRequests);
        return ServiceRequests;
    }
    
    public static Map<String,HexaBPM__Service_Request__c> getOpenServiceRequestByType(Set<String> srTypes) {

         Map<String,HexaBPM__Service_Request__c> srMap = new Map<String,HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srList = [
            SELECT Id, SRType__c, SalesOrder__c, Asset__c, HexaBPM__External_Status_Name__c, HexaBPM__IsClosedStatus__c
            FROM HexaBPM__Service_Request__c
            WHERE 
            (
                SRType__c IN( 'Aldar Estates Move-In' , 'Aldar Estates Move-Out')
                AND SalesOrder__c != null
                AND HexaBPM__External_Status_Name__c NOT IN (:Constants.SR_STATUS_CANCELLED, :Constants.STATUS_REJECTED, 'Cancelled By User')
            )
            OR
            (
                SRType__c IN :srTypes
                AND SRType__c NOT IN ('Aldar Estates Move-In','Aldar Estates Move-Out')
                AND SalesOrder__c != null
                AND  HexaBPM__External_Status_Name__c != : Constants.CLOSED_SR AND 
                                                        HexaBPM__External_Status_Name__c != : Constants.SR_STATUS_CANCELLED AND    HexaBPM__External_Status_Name__c != : Constants.SO_STATUS_CANCELLED_BY_USER 
                                                     AND   HexaBPM__Closed_Date_Time__c = null
                                                   AND (NOT(HexaBPM__External_Status_Name__c  LIKE '%Rejected%'))
            )
        ];

		for(HexaBPM__Service_Request__c record : srList){
            system.debug('MoveInSRrecord::'+record);
            if((record.SRType__c =='Aldar Estates Move-In' || record.SRType__c =='Aldar Estates Move-Out')&& record.Asset__c != null ){
                srMap.put(record.Asset__c + '-' + record.SRType__c,record);
            }else{
            srMap.put(record.SalesOrder__c + '-' + record.SRType__c,record);
        }
        }
        system.debug('Returned SRMap::'+srMap);
        return srMap;
    }

    /*
    * Query all Service Requests by SR Type that are not closed or cancelled.
    */
    public static List<HexaBPM__Service_Request__c> getOpenServiceRequestListByType(Set<String> srTypes) {
        List<HexaBPM__Service_Request__c> srList = [SELECT Id, SRType__c, SalesOrder__c, (SELECT Id, Name, SalesOrder__c, SalesOrder__r.Name 
                                                        FROM SRUnitSelected__r) FROM HexaBPM__Service_Request__c WHERE SRType__c IN : srTypes
                                                        AND HexaBPM__External_Status_Name__c != : Constants.CLOSED_SR AND 
                                                        HexaBPM__External_Status_Name__c != : Constants.SR_STATUS_CANCELLED AND 
                                                        HexaBPM__Closed_Date_Time__c = null
                                                   AND (NOT(HexaBPM__External_Status_Name__c  LIKE '%Rejected%'))];

        return srList;
    }
}