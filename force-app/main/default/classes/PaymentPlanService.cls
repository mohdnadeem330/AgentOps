/**********************************************************************************************************************
* Name               : PaymentPlanService                                                        
* Description        : This class is for fetching Payment details
* Usage              :                                                         
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class PaymentPlanService {

    public static Map<Id,Set<Id>> buildingToPaymentPlanMap ;
    /*
    * Get All Payment Plans and payment lines for a building
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByProjectIds(Set<Id> projectIds){
        //--- Get all the building of the project
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> buildingsIds = new Set<ID>();
        for(BuildingSection__c tempPaymentMappingRec: [select id,Name from BuildingSection__c where Project__c in :projectIds ]){
            buildingsIds.add(tempPaymentMappingRec.id);
        }
        if (buildingsIds != null) {
            paymentPlanMap = getPaymentPlanByBuidlingIds(buildingsIds);
        }
        return paymentPlanMap ;
    }
    
    /*
    * Get All Payment Plans and payment lines for a building
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByBuidlingIds(Set<Id> buidlingIds){
        // Building Section Mapping , identify the payment plans ids
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> paymentPlanIds = new Set<ID>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        // for(BuildingSectionMapping__c tempPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
        //     paymentPlanIds.add(tempPaymentMappingRec.PaymentPlan__c);
        // }
        for(BuildingSectionMapping__c buildingPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
            paymentPlanIds.add(buildingPaymentMappingRec.PaymentPlan__c);
            if(!buildingToPaymentPlanMap.containsKey(buildingPaymentMappingRec.BuildingSectionName__c)){
                buildingToPaymentPlanMap.put(buildingPaymentMappingRec.BuildingSectionName__c,new Set<Id>());
            }
            buildingToPaymentPlanMap.get(buildingPaymentMappingRec.BuildingSectionName__c).add(buildingPaymentMappingRec.PaymentPlan__c);
        }
        if (paymentPlanIds != null) {
            paymentPlanMap = getPaymentPlanByIds(paymentPlanIds);
        }
        return paymentPlanMap ;
    }

    //added for Post Sales 
    public static Map<Id,PaymentPlan__c> getPaymentPlanByBuidlingIdsPostSales(Set<Id> buidlingIds){
        // Building Section Mapping , identify the payment plans ids
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> paymentPlanIds = new Set<ID>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        // for(BuildingSectionMapping__c tempPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
        //     paymentPlanIds.add(tempPaymentMappingRec.PaymentPlan__c);
        // }
        for(BuildingSectionMapping__c buildingPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
            paymentPlanIds.add(buildingPaymentMappingRec.PaymentPlan__c);
            if(!buildingToPaymentPlanMap.containsKey(buildingPaymentMappingRec.BuildingSectionName__c)){
                buildingToPaymentPlanMap.put(buildingPaymentMappingRec.BuildingSectionName__c,new Set<Id>());
            }
            buildingToPaymentPlanMap.get(buildingPaymentMappingRec.BuildingSectionName__c).add(buildingPaymentMappingRec.PaymentPlan__c);
        }
        if (paymentPlanIds != null) {
            paymentPlanMap = getPaymentPlanByIdsPostSales(paymentPlanIds);
        }
        return paymentPlanMap ;
    }

    public static Map<Id,Set<Id>> getPaymentPlanIdsByBuidlingIds(Map<Id,Set<Id>> buildingToPaymentPlanIds,Set<Id> buidlingIds){

        Map<Id,Set<Id>> buildingToPaymentPlanIdsMap = new Map<Id,Set<Id>>();

        for(BuildingSectionMapping__c tempPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds AND PaymentPlan__r.IsActive__c =: Constants.PAYMENT_PLAN_ACTIVE_YES]){
            buildingToPaymentPlanIds.get(tempPaymentMappingRec.BuildingSectionName__c).add(tempPaymentMappingRec.PaymentPlan__c);
        }

        return buildingToPaymentPlanIds ;
    }

    /*
    * Get All Payment Plans by Id
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByIds(Set<Id> paymentPlanIds){

        Map<Id,PaymentPlan__c> paymentPlanMap ;
        //DIGITAL SALES DigitalSales__c
        paymentPlanMap = new map<id,PaymentPlan__c>([select id,Classification__c,Unit_Feature__c,name,CustomerSubType__c,PaymentPlanType__c ,Premium__c,RebatePercentage__c,PaymentPlanDiscount__c,Unit__c,BookingMemo__r.OwnerId,BookingMemo__r.RelatedOpportunity__c,StandardFlag__c,BrokerPortalFlag__c,DigitalSales__c,(select id,Name,BrokerPayoutPercentage__c,PaymentPlan__c,InstallmentNumber__c,Description__c,InstallmentPercentage__c,InstallmentDate__c,IsHandoverPayment__c from PaymentInstallments__r ORDER BY InstallmentNumber__c asc) from PaymentPlan__c where id in :paymentPlanIds and  IsActive__c =: Constants.PAYMENT_PLAN_ACTIVE_YES]);
        return paymentPlanMap ;
    }

    //added for Post Sales. To show all PP with Show to PostSalesFlag = true
    /*
    * Get All Payment Plans by Id
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByIdsPostSales(Set<Id> paymentPlanIds){

        Map<Id,PaymentPlan__c> paymentPlanMap ;
        paymentPlanMap = new map<id,PaymentPlan__c>([select id,name,CustomerSubType__c,PaymentPlanType__c ,Premium__c,RebatePercentage__c,PaymentPlanDiscount__c,Unit__c,BookingMemo__r.OwnerId,BookingMemo__r.RelatedOpportunity__c,StandardFlag__c,BrokerPortalFlag__c,(select id,Name,BrokerPayoutPercentage__c,PaymentPlan__c,InstallmentNumber__c,Description__c,InstallmentPercentage__c,InstallmentDate__c from PaymentInstallments__r ORDER BY InstallmentNumber__c asc) from PaymentPlan__c where id in :paymentPlanIds and (IsActive__c =: Constants.PAYMENT_PLAN_ACTIVE_YES or PostSalesFlag__c =true)]);
        return paymentPlanMap ;
    }

    @AuraEnabled(cacheable=false)
    public static void insertPaymentPlan(List<PaymentPlan__c> paymentPlanList){
      insert paymentPlanList;
    }

    @AuraEnabled(cacheable=false)
    public static String lastCreatedIdPaymentPlan(String bookingMemoId, String unitId) {   
    String lastCreatedId;
    List<PaymentPlan__c> records = [select Id from PaymentPlan__c where BookingMemo__c =: bookingMemoId and Unit__c =: unitId limit 1];
        if(records.size() > 0)
        {
	         lastCreatedId = records[0].Id;
        }
        return lastCreatedId;     
    }

    @AuraEnabled(cacheable=false)
    public static List<PaymentPlan__c> lastCreatedPaymentPlanDetails(String bookingMemoId) {   
        List<PaymentPlan__c> records = [select Id, Unit__r.BuildingSectionName__c  from PaymentPlan__c where BookingMemo__c =: bookingMemoId];
        return records;     
    }

    public static Map<Id,List<PaymentPlan__c>> getListOfPaymentPlans(Opportunity opportunityRec,List<Unit__c> unitList,User loggedInUser){

        Map<Id,List<PaymentPlan__c>> unitPaymentPlanMap = new Map<Id,List<PaymentPlan__c>>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        Map<Id,PaymentPlan__c> paymentPlanMap = new Map<Id,PaymentPlan__c>();

        for(Unit__c unitRec : unitList){
            buildingToPaymentPlanMap.put(unitRec.BuildingSectionName__c,new Set<Id>());
            unitPaymentPlanMap.put(unitRec.Id,new List<PaymentPlan__c>());
        }

        if(buildingToPaymentPlanMap != null){
            paymentPlanMap = new Map<Id,PaymentPlan__c>(PaymentPlanService.getPaymentPlanByBuidlingIds(buildingToPaymentPlanMap.keySet()));

            for(Unit__c unitRec : unitList){
                if(buildingToPaymentPlanMap.containsKey(unitRec.BuildingSectionName__c)){
                    for(Id paymentPlanId : buildingToPaymentPlanMap.get(unitRec.BuildingSectionName__c)){
                        PaymentPlan__c paymentPlanRec = paymentPlanMap.get(paymentPlanId);
                        if(paymentPlanRec !=null){
                            //----- Sub Type Check of account and payment plan
                            if(opportunityRec!=null && paymentPlanRec.CustomerSubType__c!=null && opportunityRec.Account.CustomerSubType__c != paymentPlanRec.CustomerSubType__c){
                                continue;
                            }
                            if(opportunityRec==null && paymentPlanRec.CustomerSubType__c!=null){
                                continue;
                            }
                            //------ Standard payment plans
                            if( (paymentPlanRec.Unit_Feature__c == unitRec.Unit_Feature_for_Payment_Plan__c) || paymentPlanRec.Unit_Feature__c == null){
                                if(paymentPlanRec.BookingMemo__c == null && paymentPlanRec.StandardFlag__c !=null && paymentPlanRec.StandardFlag__c == Constants.YES){
                                    unitPaymentPlanMap.get(unitRec.Id).add(paymentPlanRec);
                                }
                                //------ Check if Memo payment plan is applicable
                                else if(opportunityRec!=null && paymentPlanRec.BookingMemo__c != null && paymentPlanRec.Unit__c  == unitRec.Id && paymentPlanRec.BookingMemo__r.OwnerId == loggedInUser.Id && paymentPlanRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                                    unitPaymentPlanMap.get(unitRec.Id).add(paymentPlanRec);
                                }
                            }
                        } 
                    }
                } 
            }
        }
        return unitPaymentPlanMap ;
    }

    //added for Post Sales
    public static Map<Id,List<PaymentPlan__c>> getListOfPaymentPlansPostSales(Opportunity opportunityRec,List<Unit__c> unitList,User loggedInUser){

        Map<Id,List<PaymentPlan__c>> unitPaymentPlanMap = new Map<Id,List<PaymentPlan__c>>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        Map<Id,PaymentPlan__c> paymentPlanMap = new Map<Id,PaymentPlan__c>();

        for(Unit__c unitRec : unitList){
            buildingToPaymentPlanMap.put(unitRec.BuildingSectionName__c,new Set<Id>());
            unitPaymentPlanMap.put(unitRec.Id,new List<PaymentPlan__c>());
        }

        if(buildingToPaymentPlanMap != null){
            paymentPlanMap = new Map<Id,PaymentPlan__c>(PaymentPlanService.getPaymentPlanByBuidlingIdsPostSales(buildingToPaymentPlanMap.keySet()));

            for(Unit__c unitRec : unitList){
                if(buildingToPaymentPlanMap.containsKey(unitRec.BuildingSectionName__c)){
                    for(Id paymentPlanId : buildingToPaymentPlanMap.get(unitRec.BuildingSectionName__c)){
                        PaymentPlan__c paymentPlanRec = paymentPlanMap.get(paymentPlanId);
                        if(paymentPlanRec !=null){
                            //----- Sub Type Check of account and payment plan
                            if(opportunityRec!=null && paymentPlanRec.CustomerSubType__c!=null && opportunityRec.Account.CustomerSubType__c != paymentPlanRec.CustomerSubType__c){
                                continue;
                            }
                            if(opportunityRec==null && paymentPlanRec.CustomerSubType__c!=null){
                                continue;
                            }
                            //------ Standard payment plans
                            if(paymentPlanRec.BookingMemo__c == null && paymentPlanRec.StandardFlag__c !=null && paymentPlanRec.StandardFlag__c == Constants.YES){
                                unitPaymentPlanMap.get(unitRec.Id).add(paymentPlanRec);
                            }
                            //------ Check if Memo payment plan is applicable
                            else if(opportunityRec!=null && paymentPlanRec.BookingMemo__c != null && paymentPlanRec.Unit__c  == unitRec.Id && paymentPlanRec.BookingMemo__r.OwnerId == loggedInUser.Id && paymentPlanRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                                unitPaymentPlanMap.get(unitRec.Id).add(paymentPlanRec);
                            }
                        }
                        
                    }
                } 
            }
        }
        return unitPaymentPlanMap ;
    }

}