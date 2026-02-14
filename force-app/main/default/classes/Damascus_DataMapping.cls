public without sharing class Damascus_DataMapping {
    public static List<Project> mapProjects(List<Project__c> projectRecords) {
        List<Project> modifiedProjects = new List<Project>();
        
        Map<Id, List<Project__c>> parentWithChildProjects   = new Map<Id, List<Project__c>>();
        Set<Id> parentIds       = new Set<Id>();//BuildingsSectionsProject__r is not accessible in subquery.  So created new for-loop to handle.
        
        for(Project__c p: projectRecords){
            if(p.Projects__r != null && p.Projects__r.size() != 0) {
                parentIds.add(p.Id);
            }
        }
        
        if(!parentIds.isEmpty()) {
            List<Project__c> projList = [SELECT Id, Parent_Project__r.Description__c,Parent_Project__r.Amenities__c,Parent_Project__r.City__c,Parent_Project__r.FeaturedProject__c,Parent_Project__r.CurrencyIsoCode,Parent_Project__r.VirtualTour__c, 
                                         Parent_Project__c, Parent_Project__r.Damascus_Community_Name__c,Parent_Project__r.CommunityName__c,Parent_Project__r.Name, Parent_Project__r.VideoLink__c,
                                         (SELECT Id,LaunchStartDate__c FROM BuildingsSectionsProject__r)
                                         FROM Project__c WHERE Parent_Project__c IN: parentIds];
            for(Project__c proj : projList){
                if(parentWithChildProjects.containsKey(proj.Parent_Project__c)) {
                    parentWithChildProjects.get(proj.Parent_Project__c).add(proj);
                } else {
                    parentWithChildProjects.put(proj.Parent_Project__c, new List<Project__c>{proj});
                }
            }
        }
        
        for(Project__c p: projectRecords){
            Map<String, List<BuildingSection__c>> buildingsByProject = new Map<String, List<BuildingSection__c>>();
            
            if(p.Split_inventory_on_Damascus__c) {
                for(BuildingSection__c building : p.BuildingsSectionsProject__r) {
                    if(buildingsByProject.containsKey(building.Split_Project_Id__c)){
                        buildingsByProject.get(building.Split_Project_Id__c).add(building);
                    } else {
                        buildingsByProject.put(building.Split_Project_Id__c, new List<BuildingSection__c>{building});
                    }
                }
            }
            
            if(p.Split_inventory_on_Damascus__c) {//Added by Sarah on Mar 29, 2024
                for(String building : buildingsByProject.keySet()) {
                    Project mp = new Project();
                    mp.id= building;
                    mp.projectName= buildingsByProject.get(building).get(0).Split_Project_Name__c;
                    mp.communityName= buildingsByProject.get(building).get(0).Split_Project_Name__c;
                    mp.description= buildingsByProject.get(building).get(0).Damascus_Splitted_Project_Description__c;
                    mp.projectLocation= p.ProjectLocation__c;
                    mp.facilities= p.Amenities__c;
                    mp.city= p.City__c;
                    mp.featuredProject= p.FeaturedProject__c;
                    mp.projectCurrency= p.CurrencyIsoCode;
                    mp.virtualTour= p.VirtualTour__c;
                    mp.numberOfBuildings= buildingsByProject.get(building).size();
                    mp.launchDate = buildingsByProject.get(building).get(0).LaunchStartDate__c;//Added by Sarah for LASED-643
                    mp.BrokerSale = p.BrokerSale__c;
                    modifiedProjects.add(mp);
                    System.debug('>>>'+mp.launchDate);
                }
            }
            else {
                if(parentWithChildProjects.containsKey(p.Id)){
                    Project mp = getProject(p, true, parentWithChildProjects.get(p.Id), 0);
                    modifiedProjects.add(mp);
                    System.debug('>>>'+mp.launchDate);
                } else {
                    Project mp = getProject(p, false, null, p.BuildingsSectionsProject__r.size()); 
                    modifiedProjects.add(mp);
                    System.debug('>>>'+mp.launchDate);
                }
            }
        }
        return modifiedProjects;
    }
    
    private static Project getProject(Project__c p, Boolean isParent, List<Project__c> childProjects, Integer buildingCount) {
       	
        Project mp          = new Project();
        mp.id               = p.Id;
        mp.projectName      = p.Damascus_Community_Name__c != null ? p.Damascus_Community_Name__c : p.Name;
        mp.communityName    = p.CommunityName__c;
        mp.description      = p.Description__c;
        mp.projectLocation  = p.ProjectLocation__c;
        mp.facilities       = p.Amenities__c;
        mp.city             = p.City__c;
        mp.featuredProject  = p.FeaturedProject__c;
        mp.projectCurrency  = p.CurrencyIsoCode;
        mp.virtualTour      = p.VirtualTour__c;
        mp.country          = p.Country__c;
        mp.BrokerSale       = p.BrokerSale__c; 
        mp.countryCode      = p.Country__c == 'United Arab Emirates' ? 'UAE' : (p.Country__c == 'United Kingdom' ? 'UK' : (p.Country__c == 'Egypt' ? 'EG': ''));
        mp.startingPrice 	= p.StartingPriceFrom__c; 
        Integer count =0; 
            for(Unit__c un :p.UnitsProject__r){
                count++;
            }
        	for(Unit__c un :p.UnitsProject__r){
                mp.CompletionDate = un.CompletionDate__c;
                break;
            }
            mp.totalUnits =count;
        if(isParent){
            Date launchDateIdentifier = Date.today().addYears(-100);
            Integer buildingsCount = ((p.BuildingsSectionsProject__r != null && p.BuildingsSectionsProject__r.size() != 0) ? p.BuildingsSectionsProject__r.size() : 0);
            if(p.BuildingsSectionsProject__r != null) {
                for(BuildingSection__c building: p.BuildingsSectionsProject__r){
                    launchDateIdentifier = (launchDateIdentifier < building.LaunchStartDate__c) ? building.LaunchStartDate__c : launchDateIdentifier;
                }
            }
            
            for(Project__c proj : childProjects){
                buildingsCount  += ((proj.BuildingsSectionsProject__r != null && proj.BuildingsSectionsProject__r.size() != 0) ? proj.BuildingsSectionsProject__r.size() : 0);
                if(proj.BuildingsSectionsProject__r != null) {
                    for(BuildingSection__c building: proj.BuildingsSectionsProject__r){
                        launchDateIdentifier = (launchDateIdentifier < building.LaunchStartDate__c) ? building.LaunchStartDate__c : launchDateIdentifier;
                    }
                }
            }
            mp.numberOfBuildings= buildingsCount;//Added by Sarah for LASED-643
            mp.launchDate = launchDateIdentifier;
        } else {
            Date launchDateIdentifier = Date.today().addYears(-100);
            System.debug('>>>'+launchDateIdentifier);
            if(p.BuildingsSectionsProject__r != null) {
                for(BuildingSection__c building: p.BuildingsSectionsProject__r){
                    launchDateIdentifier = (launchDateIdentifier < building.LaunchStartDate__c) ? building.LaunchStartDate__c : launchDateIdentifier;
                }
            }
            mp.numberOfBuildings= buildingCount;//Added by Sarah for LASED-643
            mp.launchDate = launchDateIdentifier;
        }
        return mp;
    }
    
     public static List<PaymentPlan> mapPaymentPlan(List<PaymentPlan__c> paymentPlanRecords) {
        List<PaymentPlan> modifiedPaymentPlans = new List<PaymentPlan>();
        for(PaymentPlan__c paymentPlanRecord : paymentPlanRecords){
            PaymentPlan pp = new PaymentPlan();
            pp.id = paymentPlanRecord.Id;
            pp.Name = paymentPlanRecord.name;
            pp.isActive = paymentPlanRecord.isActive__c ==  'Yes' ? TRUE : FALSE ;
            pp.paymentPlanDiscount = paymentPlanRecord.PaymentPlanDiscount__c;
            pp.paymentPlanDescription = paymentPlanRecord.Description__c;
            if(paymentPlanRecord.PaymentInstallments__r != null && paymentPlanRecord.OnlineFlag__c){//Added flag check by Sarah for ASF-2809
                List<PaymentInstallments> paymentInstallmentsList = new List<PaymentInstallments>();
                for(PaymentInstallments__c installments : paymentPlanRecord.PaymentInstallments__r){
                    PaymentInstallments pi = new PaymentInstallments();
                    pi.paymentInstallmentId = installments.Id;
                    pi.paymentInstallmentNumber = installments.InstallmentNumber__c;
                    pi.paymentInstallmentPerc = installments.InstallmentPercentage__c;
                    pi.paymentInstallmentDate = installments.InstallmentDate__c;
                    pi.paymentInstallmentDesc = installments.Description__c;
                    pi.paymentInstallmentDescArabic = installments.DescriptionArabic__c;
                    paymentInstallmentsList.add(pi);
                }
                pp.PaymentInstallmentLines = paymentInstallmentsList;
            }
            
            if(paymentPlanRecord.BuildingSectionMappings__r != null){
                List<PaymentPlanBuildings> paymentBuildingList = new List<PaymentPlanBuildings>();
                for(BuildingSectionMapping__c bldMappingRec : paymentPlanRecord.BuildingSectionMappings__r){
                    PaymentPlanBuildings ppb = new PaymentPlanBuildings();
                    ppb.buildingId = bldMappingRec.BuildingSectionName__c;
                    paymentBuildingList.add(ppb);
                }
                pp.buildingIds = paymentBuildingList;
            }
            modifiedPaymentPlans.add(pp);
        }
        return modifiedPaymentPlans;
    }

    public static List<Unit> mapUnits(List<Unit__c> units) {
        List<Unit> modifiedUnits = new List<Unit>();
        for (Unit__c u : units) {
            Unit mu = new Unit();
            mu.id =  u.Id;
            mu.propertyID =  u.PropertyId__c;
            mu.unitNo =  u.Name;
            mu.unitPlotArea =  u.UnitPlotArea__c;
            mu.unitModel =  u.UnitModel__c;
            mu.unitType =  u.UnitType__c;
            mu.buldingSectionName =  u.BuildingSectionName__r.Name;
            mu.buildingId =  u.BuildingSectionName__c;
            mu.floorNo =  u.FloorNumber__c;
            mu.communityName =  u.CommunityName__c ;
            mu.DigitalSales = u.DigitalSales__c;
            mu.ReservationAmount = u.ReservationAmount__c;//Added for Damascus
            if(u.Project__r.Parent_Project__c != null){
                mu.projectNo    = u.Project__r.Parent_Project__c;
                mu.projectName  = u.Project__r.Parent_Project__r.Damascus_Community_Name__c != null ? u.Project__r.Parent_Project__r.Damascus_Community_Name__c : u.Project__r.Parent_Project__r.Name;
            } else if(u.Project__r.Split_inventory_on_Damascus__c) {//Added by Sarah on Mar 29, 2024
                mu.projectNo    =  u.BuildingSectionName__r.Split_Project_Id__c;
                mu.projectName  =  u.Project__r.Damascus_Community_Name__c != null ? u.Project__r.Damascus_Community_Name__c : u.BuildingSectionName__r.Split_Project_Name__c;
            } else {
                mu.projectNo    =  u.Project__c;
                mu.projectName  =  u.Project__r.Damascus_Community_Name__c != null ? u.Project__r.Damascus_Community_Name__c : u.ProjectName__c;
            }
            mu.launchDate   = u.ResaleListed__c ? u.Listed_Date__c : u.BuildingSectionName__r.LaunchStartDate__c;//Added by Sarah for LASED-643
            mu.completionDate =  u.CompletionDate__c;
            mu.currency1 =  u.CurrencyIsoCode;
            mu.description =  u.Description__c;
            mu.status =  u.Status__c;
            mu.sellingPrice =  u.ResaleListed__c ? u.Listing_Price__c :  u.SellingPrice__c;
            mu.saleableArea =  u.SaleableArea__c;
            mu.noOfBedrooms =  u.NumberOfBedrooms__c;
            mu.noOfBathrooms =  u.NumberOfBathrooms__c;
            mu.noofBalcony =  u.NumberOfBalcony__c;
            mu.noOfCarParks =  u.NumberOfCarParks__c;
            mu.noOfStoreRooms =  u.NumberOfStoreRooms__c;
            mu.noOfStudyRooms =  u.NumberOfStudyRooms__c;
            mu.OffPlan =  u.OffPlanProperty__c; // Formula fields to be updated
            mu.unitSize =  u.SaleableArea__c;
            mu.visible =  u.VisibleOnDamascus__c; // Field to be created to define is needs to be added on Damascus
            mu.unitView = u.UnitView__c;
            mu.latitude =  String.valueOf(u.LatitudeLongitude__Latitude__s);
            mu.longitude =  String.valueOf(u.LatitudeLongitude__Longitude__s);
            mu.resale = u.ResaleListed__c;
            mu.paymentPlanId = (u.ResaleListed__c && u.RelatedSalesOrder__c != null) ? u.RelatedSalesOrder__r.PaymentPlan__c : null;//Created for LASED-621
            mu.areaUOM = u.AreaUOM__c;
            mu.propertyUsage = u.Leadpropertyusage__c;
            mu.OnlineBrokerFlag = u.AvailableForBrokerSales__c;
            // mu.Amenities = u.Amenities__c;
            modifiedUnits.add(mu);
        }
        return modifiedUnits;
    }

    public class Project {
        public String id;   //131
        public String projectName;  //Arc Towers
        public String communityName;    //Arc towers
        public String description;  //Arabian style home
        public String propertySize; //10*25 sqft
        public Decimal startingPrice;    //7458234
        public String status;   //completed
        public Date completionDate;   //30-06-2026
        public String resOutsideUae;    //true
        public String propertyTypes;    //
        public String communityPhase;   //
        public String virtualTour;  //http://saleforce/vtour
        public String videoLink;    //http://salesforce/videolink
        public String projectLocation;  //yas island
        public Integer numberOfBuildings;   //100
        public String mapView;  //
        public String facilities;
        public String location; //
        public List<String> unitTypes;
        public String city; //
        public String projectCurrency;  //                                              // to replace from currency
        public String floorPlans;   //
        public String servicecharges;   //
        public Boolean featuredProject;
        public Date launchDate;//Created by Sarah for LASED-643
        public String country; //added by Sanath for Broker Portal 2.0
        public Boolean BrokerSale;
        public String countryCode;
        public Decimal totalUnits;
    }
    
    public class PaymentPlan {
        public String id;   //131
        public String name;
        public Boolean isActive;
        public Decimal paymentPlanDiscount;
         public String paymentPlanDescription;
        public List<PaymentInstallments> PaymentInstallmentLines;
        public List<PaymentPlanBuildings> buildingIds;
        
    }
    
    public class PaymentInstallments{
        public String paymentInstallmentId;
        public Decimal paymentInstallmentNumber;
        public Decimal paymentInstallmentPerc;
        public Date paymentInstallmentDate;
        public String paymentInstallmentDesc;
        public String paymentInstallmentDescArabic;
    }
    public class PaymentPlanBuildings{
        public String buildingId;
    }
    
    public class Unit{
        public String id;
        public String propertyID;
        public String unitNo;
        public String communityName;
        public Decimal unitPlotArea;
        public String unitModel;
        public String unitType;
        public String buldingSectionName;
        public String buildingId;
        public String floorNo;
        public String projectNo;
        public String projectName;
        public Date completionDate;
        public String currency1;
        public String description;
        public String status;
        public Decimal sellingPrice;
        public Decimal saleableArea;
        public String noOfBedrooms;
        public Decimal noOfBathrooms;
        public Decimal noofBalcony;
        public Decimal noOfCarParks;
        public Decimal noOfStoreRooms;
        public Decimal noOfStudyRooms;
        public String floorPlan;
        public String Amenities;
        public Boolean OffPlan;
        public Boolean visible;
        public String serviceCharge;
        public String location;
        public Decimal unitSize;
        public String AvailableForResidentsForUAE;
        public String Facilities;
        public String unitView;
        public String areaUOM; 
        public String latitude; 
        public String longitude; 
        public Boolean resale; 
        public String propertyUsage;
        public Date launchDate; //Created for LASED-643
        public String paymentPlanId;//Created for LASED-621
        public Boolean DigitalSales;
        public Decimal ReservationAmount;
        public Boolean OnlineBrokerFlag;

    }
}