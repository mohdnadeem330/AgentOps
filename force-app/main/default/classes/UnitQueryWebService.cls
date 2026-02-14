@RestResource (urlMapping = '/query/units1')
global with sharing class UnitQueryWebService {
    
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
                propertyInventories = getAllUnits(null);
                
            }
            //---- Fetch based on the filters that are applied
            else{
                Utilities.objType = 'inventory';
                String agentId = '';
                if(mapRequestMapping !=null && mapRequestMapping.containsKey('agentId')){
                    agentId = mapRequestMapping.get('agentId') ;
                    for(AllocationGroupUser__c allocationGroupUserRec : [SELECT Id,Name,AllocationGroup__r.Name FROM AllocationGroupUser__c where UserEmail__c =: agentId AND (IsActive__c = true OR StartDate__c > TODAY)]){
                        Utilities.groupNames.add(allocationGroupUserRec.AllocationGroup__r.Name);
                    }
                    System.debug('**groupNames**'+Utilities.groupNames);
                }
                String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapRequestMapping);
                propertyInventories = getAllUnits(whereConditionFromMap);
            }

            UnitQueryResponse response = new UnitQueryResponse(propertyInventories, 'Unit__c', false);

            handler.response.data = response;
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

    global with sharing class UnitQueryResponse extends QueryResponse {
        
        global UnitQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {
            super(records, objectName, processRecords);

            for (SObject record : records) {
                Unit__c unit = (Unit__c) record;
                if(unit.Status__c != Constants.UNIT_STATUS_AVAILABLE && unit.Status__c != Constants.UNIT_STATUS_SOLD){
                    unit.Status__c = Constants.UNIT_STATUS_SOLD;
                }
            }
        }
    }

    /*
    * Get all Units Available 
    */
    public static List<Unit__c> getAllUnits(String queryCondition){
    system.debug('getAllUnits');
        Set<String> unitFieldList = Schema.getGlobalDescribe().get('Unit__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
                List<String> strFieldList = new List<String>{'Id','OwnerId','Name','CurrencyIsoCode','RecordTypeId','CreatedDate','LastModifiedDate','ADMARBSectorName__c',
            'ADMPlotNumber__c','ADMSectorName__c','ADMUnitNumber__c','ActualContractorHandoverDate__c','ActualCustomerHandoverDate__c',
            'AnticipatedServiceCharges__c','AreaUOM__c','BuildingSectionName__c','CompletionDate__c','Country__c','EscalationServiceCharge__c',
            'FloorNumber__c','GFAArea__c','MunicipalityNumber__c','NumberOfBedrooms__c','NumberOfCarParks__c','OtherArea__c',
            'PlotArea__c','Project__c','SaleableArea__c','SellingPrice__c','Status__c','TerraceArea__c','TotalArea__c','TotalRooms__c',
            'UnitCategory__c','UnitGFAArea__c','UnitModel__c','UnitNumber__c','UnitPlotArea__c','UnitType__c','UnitTypology__c','CommunityName__c',
            'IsActive__c','ProjectName__c','Mandatory_POD__c','Mandatory_Premium__c','Internal_Area__c'};
        strList.addAll(unitFieldList);
        String fields = string.join(strFieldList ,',');

        List<String> statusNotAllowed = new List<String>{'New','Blocked','In-Progress'} ;

        //-- DPG Applicable , No Blocked and New 
        String query = 'SELECT ' + fields + ' FROM Unit__c WHERE PropertyStatus__c =\'Sale\' AND Project__r.DPGApplicable__c=true AND Status__c NOT IN (\'New\',\'Blocked\',\'In-Progress\')';
        if(queryCondition != null && string.isNotEmpty(queryCondition)){
            query += ' AND ('+queryCondition+') ';
        } 
        
        query += ' LIMIT 3000  ';
        System.debug('***Unit Query***'+query);

        List<Unit__c> unitList = Database.Query(query);
        System.debug('***Unit Queried***'+unitList.size());

        return unitList ;
    } 

}