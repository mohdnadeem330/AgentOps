public without sharing class Damascus_RestApiHandler {

    public class Damascus_RestApiException extends Exception {}

    public static Map<String, Object> getModifiedIds(String startDateStr, String endDateStr) {
        Map<String, Object> modifiedIds = new Map<String, Object>();
        Date startDate  = Date.valueOf(startDateStr);
        Date endDate    = Date.valueOf(endDateStr).addDays(1);
        //Map<Id, PaymentPlan__c> paymentsMap = new Map<Id, PaymentPlan__c>();
        Map<Id, PaymentPlan__c> paymentsMap = new Map<Id, PaymentPlan__c>( 
                                                       [SELECT Id, LastModifiedDate 
                                                        FROM PaymentPlan__c 
                                                        WHERE LastModifiedDate >=: startDate 
                                                            AND LastModifiedDate <=: endDate 
                                                            AND OnlineFlag__c = TRUE ]); //WHERE LastModifiedDate >=: startDate AND LastModifiedDate <=: endDate LIMIT 5*/
        modifiedIds.put('paymentIds', paymentsMap.keySet());

        Map<Id, Project__c> projectsMap = new Map<Id, Project__c>(
                                                   [SELECT Id, LastModifiedDate 
                                                    FROM Project__c 
                                                    WHERE LastModifiedDate >=: startDate 
                                                        AND LastModifiedDate <=: endDate  AND (EnableforDamascus__c = TRUE or BrokerSale__c = TRUE)]);

        modifiedIds.put('projectIds', projectsMap.keySet());
        
        Map<Id, Unit__c> unitsMap = new Map<Id, Unit__c>(
                                           [SELECT Id, LastModifiedDate 
                                            FROM Unit__c 
                                            WHERE LastModifiedDate >=: startDate 
                                                AND LastModifiedDate <=: endDate  AND (Project__r.EnableforDamascus__c = TRUE or AvailableForBrokerSales__c = TRUE) ]);
        modifiedIds.put('unitIds', unitsMap.keySet());
        
        return modifiedIds;
    }

    public static List<Damascus_DataMapping.Project> getModifiedProjects(List<String> projectIds) {
        String query = 'SELECT Id, Name, EnableforDamascus__c, CommunityName__c, ProjectLocation__c, Amenities__c, City__c,Parent_Project__r.Description__c,Parent_Project__r.Amenities__c,Parent_Project__r.City__c,Parent_Project__r.FeaturedProject__c,Parent_Project__r.CurrencyIsoCode,Parent_Project__r.VirtualTour__c,   '
            +'VirtualTour__c, CurrencyIsoCode, Description__c,VideoLink__c, Parent_Project__c,Parent_Project__r.Damascus_Community_Name__c,Parent_Project__r.CommunityName__c,'
            +'LastModifiedDate,FeaturedProject__c,Split_inventory_on_Damascus__c,Damascus_Community_Name__c,Parent_Project__r.Name, Parent_Project__r.VideoLink__c,ProjectCode__c, '
            +'( SELECT Id,Split_Project_Name__c,Split_Project_Id__c,Damascus_Splitted_Project_Description__c,LaunchStartDate__c '
            +'FROM BuildingsSectionsProject__r),(SELECT Id,ProjectLocation__c,Split_inventory_on_Damascus__c,Parent_Project__c,Name,CommunityName__c,Description__c,Amenities__c,City__c,FeaturedProject__c,CurrencyIsoCode,VideoLink__c,VirtualTour__c FROM Projects__r), Parent_Project__r.ProjectLocation__c, '
            +'EnableforAppointment__c,AppointmentSystemID__c,AppointmentSystemCode__c,Country__c,BrokerSale__c, StartingPriceFrom__c,(SELECT Id,Name,CompletionDate__c FROM UnitsProject__r ORDER BY CompletionDate__c DESC) '
            +'FROM Project__c ' 
            +'WHERE Id IN: projectIds';//Modified by Sarah on Mar 29, 2024
        
        Map<Id, Project__c> projectsMap = new Map<Id, Project__c>((List<Project__c>)Database.query(query));
        
        return Damascus_DataMapping.mapProjects(projectsMap.values());
    }
    
    
    public static List<Damascus_DataMapping.PaymentPlan> getModifiedPaymentPlans(List<String> paymentPlanIds) {
        List<PaymentPlan__c > paymentPlanList = new List<PaymentPlan__c>();
        paymentPlanList = [Select Id,Name, Description__c, IsActive__c, PaymentPlanDiscount__c,OnlineFlag__c,
                           (SELECT Id,InstallmentNumber__c, InstallmentPercentage__c, InstallmentDate__c,Description__c, DescriptionArabic__c FROM PaymentInstallments__r ORDER BY InstallmentNumber__c ASC ),
                           (SELECT Id,BuildingSectionName__c FROM BuildingSectionMappings__r)
                           FROM PaymentPlan__c WHERE Id IN: paymentPlanIds  ];
        
        return Damascus_DataMapping.mapPaymentPlan(paymentPlanList);
        
    }

    public static List<Damascus_DataMapping.Unit> getModifiedUnits(List<String> unitIds) {
        String query = 'SELECT Id, Name,UnitView__c,AreaUOM__c,Listed_Date__c, '
                            +'CurrencyIsoCode, Description__c, Status__c, CompletionDate__c,VisibleOnDamascus__c,Project__r.Parent_Project__c,Project__r.Parent_Project__r.Damascus_Community_Name__c,Project__r.Parent_Project__r.Name,Project__r.DarnaApplicable__c,'
                            +'PropertyId__c, Project__c,BuildingSectionName__r.Split_Project_Name__c,BuildingSectionName__r.Split_Project_Id__c, Project__r.Split_inventory_on_Damascus__c, Project__r.Damascus_Community_Name__c, ProjectName__c,OffPlanProperty__c,ResaleListed__c, '//Modified by Sarah on Mar 29, 2024
                            +'CommunityName__c,RecordType.Name, '
                            +'Leadpropertyusage__c, BuildingSectionName__c, BuildingSectionName__r.Name,BuildingSectionName__r.LaunchStartDate__c, '
                            +'UnitModel__c, UnitType__c, SellingPrice__c,Listing_Price__c ,RelatedSalesOrder__c,RelatedSalesOrder__r.PaymentPlan__c, '
                            +'FloorNumber__c, NumberOfBedrooms__c, NumberOfBathrooms__c, NumberOfBalcony__c, NumberOfCarParks__c, NumberOfStoreRooms__c, NumberOfStudyRooms__c, '
                            +'UnitPlotArea__c, SaleableArea__c, TotalArea__c,LatitudeLongitude__Latitude__s, ReservationAmount__c,LatitudeLongitude__Longitude__s,DigitalSales__c,OnlineBrokerFlag__c,AvailableForBrokerSales__c,TerraceArea__c, Internal_Area__c   '
                        +'FROM Unit__c '
                        +'WHERE Id IN: unitIds';
        Map<Id, Unit__c> unitsMap = new Map<Id, Unit__c>((List<Unit__c>)Database.query(query));
        system.debug(unitsMap.values());
        return Damascus_DataMapping.mapUnits(unitsMap.values());
    }
    
}