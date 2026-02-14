@RestResource (urlMapping = '/query/units')
global with sharing class UnitQueryWebServiceNew {
    
    @HttpPost
    global static void doPost() {   

        RestRequest req = RestContext.request;
        
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mapRequestMapping = handler.getRequestBodyMap();
            List<Unit__c> propertyInventories = new List<Unit__c>();

            //---- Fetch all available Units
            System.debug('**mapRequestMapping**'+mapRequestMapping);
            if(mapRequestMapping==null || mapRequestMapping.isEmpty()){
                //---- Available , Booked and Sold
//                propertyInventories = getAllUnits(null);
                
            }
            //---- Fetch based on the filters that are applied
            else{
                Utilities.objType = 'inventory';
                String agentId = '';
                /*if(mapRequestMapping !=null && mapRequestMapping.containsKey('agentId')){
                    agentId = mapRequestMapping.get('agentId') ;
                    for(AllocationGroupUser__c allocationGroupUserRec : [SELECT Id,Name,AllocationGroup__r.Name FROM AllocationGroupUser__c where UserEmail__c =: agentId AND (IsActive__c = true OR StartDate__c > TODAY)]){
                        Utilities.groupNames.add(allocationGroupUserRec.AllocationGroup__r.Name);
                    }
                    System.debug('**groupNames**'+Utilities.groupNames);
                }*/
                Map<String,String> mapRequestMappingWhereCondition =  new Map<String,String>();
                String whereConditionFromMap =  '';
//                whereCondition.add(key +' = \''+mapFieldApiFieldValues.get(key)+'\'');

                if(mapRequestMapping !=null && mapRequestMapping.containsKey('PV_Community_Name')){
                    whereConditionFromMap += ' CommunityName__c =  \''+mapRequestMapping.get('PV_Community_Name') + '\'';
//                    mapRequestMappingWhereCondition.put('CommunityName__c',mapRequestMapping.get('PV_Community_Name'));
                }
//                String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapRequestMappingWhereCondition);
                propertyInventories = getAllUnits(whereConditionFromMap);
            }
            List<UnitDetailsWrapper> unitDetailsList = new List<UnitDetailsWrapper>();
            for(Unit__c unit : propertyInventories){
                UnitDetailsWrapper unitRec = new UnitDetailsWrapper();
                unitRec = getUnitWrapper(unit);
                unitDetailsList.add(unitRec);
            }
//            UnitQueryResponse response = new UnitQueryResponse(propertyInventories, 'Unit__c', false);
        
            
            system.debug('SIZE '+unitDetailsList.size());
                
            handler.response.data = unitDetailsList;
            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

   /* global with sharing class UnitQueryResponse extends QueryResponse {
        
        global UnitQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {
            super(records, objectName, processRecords);

            for (SObject record : records) {
                Unit__c unit = (Unit__c) record;
                if(unit.Status__c != Constants.UNIT_STATUS_AVAILABLE && unit.Status__c != Constants.UNIT_STATUS_SOLD){
                    unit.Status__c = Constants.UNIT_STATUS_SOLD;
                }
            }
        }
    }*/
    
    public static UnitDetailsWrapper getUnitWrapper(Unit__c unit){
        UnitDetailsWrapper wrapperRecord = new UnitDetailsWrapper();
        wrapperRecord.attr_property_name = unit.ProjectName__c;
        wrapperRecord.attr_community_name = unit.CommunityName__c;
        wrapperRecord.attr_off_building = unit.BuildingSectionName__r.Name;
        wrapperRecord.attr_off_floor = unit.FloorNumber__c;
        wrapperRecord.unit_status = unit.Status__c;
        wrapperRecord.unit_type = unit.UnitType__c ;
        wrapperRecord.unit_model = unit.UnitModel__c;
        wrapperRecord.saleable_area = String.valueOf(unit.SaleableArea__c) ;
        wrapperRecord.terrace_area = String.valueOf(unit.TerraceArea__c);
        wrapperRecord.bedrooms = unit.NumberOfBedrooms__c;
        wrapperRecord.bathrooms = String.valueOf(unit.NumberOfBathrooms__c);
        wrapperRecord.car_parks = unit.CarParkAllocation__c;
        wrapperRecord.unit_view = unit.UnitView__c;
        wrapperRecord.selling_price = String.valueOf(unit.SellingPrice__c);
        wrapperRecord.unit_category = unit.UnitCategory__c;
        wrapperRecord.aldar_unit_number = unit.Name;
        wrapperRecord.p_plot_area = String.valueOf(unit.PlotArea__c);
        wrapperRecord.p_gfa = String.valueOf(unit.GFAArea__c);
        wrapperRecord.municipality_no = unit.MunicipalityNumber__c;
        wrapperRecord.garage_area = String.valueOf(unit.GarageArea__c);
        wrapperRecord.handover_zone = unit.HandoverZone__c;
        wrapperRecord.mirror = unit.Mirror__c;
        wrapperRecord.plex = unit.Plex__c;

        //        wrapperRecord.web_floor_plan_url = 'TBD';
        wrapperRecord.last_update_date = String.valueOf(unit.LastModifiedDate);
        if(unit.UnitTypology__c == 'Premium'){
            wrapperRecord.premiumApplicable = true;
            wrapperRecord.premiumAmount = String.valueOf(unit.MultiPurposeAmount__c);
            wrapperRecord.paymentPlan = unit.CaptivatePaymentPlan__c;
        }else{
            wrapperRecord.premiumApplicable = false;
            wrapperRecord.premiumAmount = '';
            wrapperRecord.paymentPlan = unit.CaptivatePaymentPlan__c;
        }
        wrapperRecord.downPayment = unit.DownPaymentCaptivate__c;
        wrapperRecord.kitchen_pod_amount = String.valueOf(unit.PODkitchenPrice__c);
        wrapperRecord.multipur_pod_amount = String.valueOf(unit.PODMultiPurposeRoomPrice__c);
        wrapperRecord.podium_area = String.valueOf(unit.PoolArea__c);
        wrapperRecord.sales_agent_id = unit.AssignedToUser__r != null ? unit.AssignedToUser__r.Email : null ;
        // Need clarification
        wrapperRecord.online_status = String.valueOf(unit.OnlineStatus__c); // Why do we need this?
        wrapperRecord.online_reservation_flag = String.valueOf(unit.OnlineReservation__c); // Why do we need this? 
        wrapperRecord.online_reservation_fee = String.valueOf(unit.OnlineReservationFee__c);
        wrapperRecord.digital_sales = String.valueOf(unit.DigitalSales__c);//Added by Tajinkumar
        wrapperRecord.reservation_amount = String.valueOf(unit.ReservationAmount__c);//Added by Tajinkumar
        wrapperRecord.online_broker_flag = String.valueOf(unit.OnlineBrokerFlag__c);
        wrapperRecord.cluster_name = unit.PlotSpecification__c; // Confirmation
        wrapperRecord.location_id = unit.Id;
        wrapperRecord.attr_off_office = '';
        wrapperRecord.attr_off_location_code = '';
        wrapperRecord.property_usage = unit.PropertyUsage__c;
        wrapperRecord.balcony_area = '';
        wrapperRecord.lease_only_price = '';
        wrapperRecord.unit_allocation_group = unit.AllocationGroup__c != null ? unit.AllocationGroup__r.Name : null ;   
        wrapperRecord.p_residential_area = '';
        wrapperRecord.p_retail_area = '';
        wrapperRecord.disableUnit = unit.Disableforvirtualplatforms__c;
        wrapperRecord.numberOfFloorsinBldg = String.valueOf(unit.BuildingSectionName__r.NumberOfFloors__c);
		wrapperRecord.UnitFloorNumbers = unit.UnitFloorNumbers__c;
        wrapperRecord.unitFurnished = unit.is_Default_Furnished__c;
        wrapperRecord.featureSpecification = unit.FeaturesSpecification__c;
        
        return wrapperRecord;
    }

    /*
    * Get all Units Available 
    */
    public static List<Unit__c> getAllUnits(String queryCondition){
    system.debug('getAllUnits');
        Set<String> unitFieldList = Schema.getGlobalDescribe().get('Unit__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
                List<String> strFieldList = new List<String>{'Id','OwnerId','Name','CurrencyIsoCode','RecordTypeId','CreatedDate','LastModifiedDate','ADMARBSectorName__c',
            'ADMPlotNumber__c','ADMSectorName__c','ADMUnitNumber__c','ActualContractorHandoverDate__c','ActualCustomerHandoverDate__c','AllocationGroup__c','AllocationGroup__r.Name',
            'AnticipatedServiceCharges__c','AreaUOM__c','BuildingSectionName__c','CompletionDate__c','Country__c','EscalationServiceCharge__c','DigitalSales__c','ReservationAmount__c',
            'FloorNumber__c','GFAArea__c','MunicipalityNumber__c','NumberOfBedrooms__c','NumberOfCarParks__c','OtherArea__c','EligibleforUnitFurnishing__c',
            'PlotArea__c','Project__c','SaleableArea__c','SellingPrice__c','Status__c','TerraceArea__c','TotalArea__c','TotalRooms__c','CaptivatePaymentPlan__c',
            'UnitCategory__c','UnitGFAArea__c','UnitModel__c','UnitNumber__c','UnitPlotArea__c','UnitType__c','UnitTypology__c','CommunityName__c','DownPaymentCaptivate__c',
            'IsActive__c','ProjectName__c','Plex__c','Mirror__c','FeaturesSpecification__c','Mandatory_POD__c','Mandatory_Premium__c','Internal_Area__c','BuildingSectionName__r.Name','Disableforvirtualplatforms__c','MultiPurposeAmount__c'};
        strList.addAll(unitFieldList);
        strList.add('BuildingSectionName__r.Name');
        strList.add('AssignedToUser__r.Email');
        strList.add('AllocationGroup__r.Name');
        strList.add('BuildingSectionName__r.NumberOfFloors__c');


        String fields = string.join(strList ,',');

        List<String> statusNotAllowed = new List<String>{'New','Blocked','In-Progress'} ;

        //-- DPG Applicable , No Blocked and New 
        String query = 'SELECT ' + fields + ' FROM Unit__c WHERE PropertyStatus__c =\'Sale\' AND Project__r.DPGApplicable__c=true ';
        //AND Status__c NOT IN (\'New\',\'Blocked\',\'In-Progress\')
        if(queryCondition != null && string.isNotEmpty(queryCondition)){
            query += ' AND ('+queryCondition+') ';
        } 
        
        query += ' LIMIT 4000  ';
        System.debug('***Unit Query***'+query);

        List<Unit__c> unitList = Database.Query(query);
        System.debug('***Unit Queried***'+unitList.size());

        return unitList ;
    } 
    
    

}